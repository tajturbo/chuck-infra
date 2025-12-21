import os
import base64
import json
from google.cloud import run_v2

def scale_cloud_run(event, context):
    """
    Cloud Function to scale Cloud Run services based on environment and action.
    Triggered by Cloud Scheduler via Pub/Sub.
    """
    if 'data' not in event:
        print("No data in event")
        return

    try:
        payload = json.loads(base64.b64decode(event['data']).decode('utf-8'))
    except Exception as e:
        print(f"Error decoding payload: {e}")
        return

    action = payload.get('action') # 'sleep' or 'wake'
    env = payload.get('environment')
    
    # Try common environment variables for project ID
    project_id = os.environ.get('GCP_PROJECT') or os.environ.get('GOOGLE_CLOUD_PROJECT') or os.environ.get('PROJECT_ID')
    region = os.environ.get('GCP_REGION', 'us-central1')

    if not action or not env or not project_id:
        print(f"Missing action ({action}), environment ({env}), or project_id ({project_id})")
        return

    client = run_v2.ServicesClient()
    parent = f"projects/{project_id}/locations/-" # Search across all locations

    # List all services in the project
    services = client.list_services(parent=parent)

    for service in services:
        # Check if service belongs to the target environment and app
        labels = service.labels or {}
        if labels.get('environment') == env and labels.get('app') == 'chuck-norris':
            target_count = 0 if action == 'sleep' else int(os.environ.get('WAKE_MIN_INSTANCES', '1'))
            
            print(f"Processing service: {service.name} (Env: {env}, Action: {action})")
            print(f"Target scaling (min/max): {target_count}")
            
            # Update scaling configuration
            service.template.scaling.min_instance_count = target_count
            service.template.scaling.max_instance_count = target_count
            
            # Update the service
            request = run_v2.UpdateServiceRequest(service=service)
            operation = client.update_service(request=request)
            print(f"Update started for {service.name}. Operation: {operation.operation.name}")

    print("Scaling operation finished.")
