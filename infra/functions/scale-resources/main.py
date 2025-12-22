import base64
import json
import os

from google.cloud import run_v2
from google.protobuf.field_mask_pb2 import FieldMask


def _get_required_env(name: str) -> str:
    value = os.environ.get(name)
    if not value:
        raise ValueError(f"Missing required env var: {name}")
    return value


def _split_csv(value: str | None) -> list[str]:
    if not value:
        return []
    return [v.strip() for v in value.split(",") if v.strip()]


def _get_ingress_enum(name: str) -> int:
    """Return the run_v2.IngressTraffic enum value for an env var string.

    Expected values are like: INGRESS_TRAFFIC_ALL, INGRESS_TRAFFIC_NONE,
    INGRESS_TRAFFIC_INTERNAL_ONLY, INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER.
    """
    raw = (name or "").strip()
    if not raw:
        raise ValueError("Invalid ingress value: empty")

    # Allow shorter aliases.
    aliases = {
        "ALL": "INGRESS_TRAFFIC_ALL",
        "INTERNAL_ONLY": "INGRESS_TRAFFIC_INTERNAL_ONLY",
        "INTERNAL_LOAD_BALANCER": "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER",
        "NONE": "INGRESS_TRAFFIC_NONE",
    }
    enum_name = aliases.get(raw, raw)

    # google-cloud-run==0.10.5 does not expose INGRESS_TRAFFIC_NONE.
    # For the FinOps requirement "service unreachable", INTERNAL_ONLY is sufficient
    # for an internet-facing service / external HTTP(S) load balancer.
    if enum_name == "INGRESS_TRAFFIC_NONE" and not hasattr(run_v2.IngressTraffic, enum_name):
        enum_name = "INGRESS_TRAFFIC_INTERNAL_ONLY"

    try:
        return getattr(run_v2.IngressTraffic, enum_name)
    except Exception as e:
        raise ValueError(f"Invalid ingress value '{raw}' (resolved to {enum_name}): {e}")


def _extract_pubsub_message_data_b64(event) -> str | bytes | None:
    """Returns the base64-encoded Pub/Sub message data.

    Terraform Scheduler uses `pubsub_target.data = base64encode(jsonencode({...}))`.
    Cloud Functions Gen2 receives a CloudEvent whose `.data` contains a dict:
      {"message": {"data": "..."}, ...}
    """
    # Gen2 CloudEvent
    cloud_event_data = getattr(event, "data", None)
    if isinstance(cloud_event_data, dict):
        msg = cloud_event_data.get("message")
        if isinstance(msg, dict) and "data" in msg:
            return msg.get("data")

    # Gen1/background (or tests) sometimes pass a dict directly
    if isinstance(event, dict):
        if "data" in event:
            return event.get("data")
        msg = event.get("message")
        if isinstance(msg, dict) and "data" in msg:
            return msg.get("data")

    return None


def _decode_scheduler_pubsub_payload(message_b64: str | bytes) -> dict:
    """Decode payload published by Cloud Scheduler to Pub/Sub.

    In Terraform we publish: base64encode(jsonencode({...}))
    Pub/Sub delivers message.data as base64 again inside the CloudEvent.
    So we commonly need to base64-decode twice.
    """
    if isinstance(message_b64, bytes):
        first = base64.b64decode(message_b64)
    else:
        first = base64.b64decode(message_b64.encode("utf-8"))

    # Try direct JSON first
    try:
        return json.loads(first.decode("utf-8"))
    except Exception:
        pass

    # Fallback: Scheduler often publishes already-base64'd JSON; decode again
    try:
        inner_b64 = first.decode("utf-8").strip()
        second = base64.b64decode(inner_b64.encode("utf-8"))
        return json.loads(second.decode("utf-8"))
    except Exception as e:
        raise ValueError(f"Unable to decode Pub/Sub payload (expected JSON or base64(JSON)): {e}")


def scale_cloud_run(event, context=None):
    """Scale all Cloud Run services up/down for out-of-office hours.

    Trigger: Cloud Scheduler -> Pub/Sub -> Cloud Functions Gen2 event trigger.
    Payload (JSON): {"action": "sleep"|"wake", "environment": "..."}
    - sleep: set min=0 and set ingress to SLEEP_INGRESS (default NONE)
    - wake:  set min/max from WAKE_* env vars and set ingress to WAKE_INGRESS (default ALL)
    """
    try:
        project_id = _get_required_env("GCP_PROJECT")
        regions = _split_csv(os.environ.get("GCP_REGIONS"))
        if not regions:
            # Back-compat with older env var name.
            regions = [_get_required_env("GCP_REGION")]
    except Exception as e:
        print(str(e))
        return (str(e), 500)

    target_service_ids = set(_split_csv(os.environ.get("TARGET_SERVICE_IDS")))
    if not target_service_ids:
        print("Missing TARGET_SERVICE_IDS; refusing to scale all services")
        return ("Missing TARGET_SERVICE_IDS", 500)

    message_b64 = _extract_pubsub_message_data_b64(event)
    if not message_b64:
        print(f"No Pub/Sub message data found. event_type={type(event)}")
        evt_data = getattr(event, "data", None)
        if isinstance(evt_data, dict):
            print(f"CloudEvent.data keys: {list(evt_data.keys())}")
        return ("No Pub/Sub message data found", 400)

    try:
        payload = _decode_scheduler_pubsub_payload(message_b64)
    except Exception as e:
        print(f"Failed to decode Pub/Sub payload: {e}")
        return ("Failed to decode Pub/Sub payload", 400)

    action = payload.get("action")
    environment = payload.get("environment")
    if action not in {"sleep", "wake"}:
        return ("Invalid payload action (expected sleep|wake)", 400)

    if action == "sleep":
        target_min = 0
        # Cloud Run max instances must be >= 1; keep max at wake value.
        target_max = int(os.environ.get("WAKE_MAX_INSTANCES", "1"))
        ingress_name = os.environ.get("SLEEP_INGRESS", "INGRESS_TRAFFIC_NONE")
    else:
        # Terraform sets these to var.desired_instances (typically 1)
        target_min = int(os.environ.get("WAKE_MIN_INSTANCES", "1"))
        target_max = int(os.environ.get("WAKE_MAX_INSTANCES", "1"))
        ingress_name = os.environ.get("WAKE_INGRESS", "INGRESS_TRAFFIC_ALL")

    try:
        target_ingress = _get_ingress_enum(ingress_name)
    except Exception as e:
        print(str(e))
        return (str(e), 500)

    print(
        f"FinOps scaler invoked. project={project_id} regions={regions} "
        f"environment={environment} action={action} target_min={target_min} target_max={target_max} ingress={ingress_name}"
    )

    client = run_v2.ServicesClient()

    updated = 0
    failed = 0
    skipped = 0

    update_paths = [
        "template.scaling.min_instance_count",
        "template.scaling.max_instance_count",
        "ingress",
    ]

    for region in regions:
        parent = f"projects/{project_id}/locations/{region}"
        for service in client.list_services(parent=parent):
            try:
                service_id = service.name.split("/")[-1] if getattr(service, "name", None) else None
                if not service_id or service_id not in target_service_ids:
                    skipped += 1
                    continue

                if getattr(service, "template", None) is None:
                    print(f"Skipping {service.name}: missing template")
                    failed += 1
                    continue

                # Make unreachable by setting ingress=NONE during sleep.
                service.ingress = target_ingress

                scaling = service.template.scaling
                scaling.min_instance_count = target_min
                scaling.max_instance_count = target_max

                # Some older google-cloud-run client versions (e.g. 0.10.5) do not expose
                # UpdateServiceRequest.update_mask. Prefer using it when available, but
                # fall back to sending the full Service without an update mask.
                req = run_v2.UpdateServiceRequest(service=service)
                try:
                    req.update_mask = FieldMask(paths=update_paths)
                except Exception as e:
                    print(f"UpdateServiceRequest.update_mask not supported; continuing without update mask: {e}")
                op = client.update_service(request=req)
                updated += 1
                print(f"Update started: {service.name} op={op.operation.name}")
            except Exception as e:
                failed += 1
                print(f"Failed updating {getattr(service, 'name', '<unknown>')}: {e}")

    return (f"Done. Updated={updated} Failed={failed} Skipped={skipped}", 200)
