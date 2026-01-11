# Changelog

## [0.2.0](https://github.com/tajturbo/chuck-infra/compare/v0.1.2...v0.2.0) (2026-01-11)


### Features

* automatically enable FinOps schedule for non-prod environments in GHA workflow ([6d03fa1](https://github.com/tajturbo/chuck-infra/commit/6d03fa1a1dd1b86cecc5d56673fe43096faa6820))
* disable autoscaling and implement fixed 1-instance scaling with FinOps support ([cf38c75](https://github.com/tajturbo/chuck-infra/commit/cf38c7539b1634f06742aaec8bc8dd407e44f7e1))
* enforce manual scaling with single desired_instances variable ([a158006](https://github.com/tajturbo/chuck-infra/commit/a158006cf2d1cc9f3e6fa0106ffc14da44f7decd))
* **finops:** schedule sleep/wake for Cloud Run in UTC ([18ce402](https://github.com/tajturbo/chuck-infra/commit/18ce4022796c228def6177fd7018e67a56a4713e))
* implement automated FinOps start/stop schedule for non-prod ([#6](https://github.com/tajturbo/chuck-infra/issues/6)) ([fa55149](https://github.com/tajturbo/chuck-infra/commit/fa551493f149b2e9a83d217468610dfc242ebc06))
* **infra:** add deletion_protection=false to Cloud Run service ([50ff909](https://github.com/tajturbo/chuck-infra/commit/50ff9092a0859fce5843708d5e5d76f78966bb36))
* simplify manual scaling using min/max constraints ([91d9d74](https://github.com/tajturbo/chuck-infra/commit/91d9d746c2515670ca69c2b687b8d235baac010f))
* use native Cloud Run v2 manual scaling mode ([dae23aa](https://github.com/tajturbo/chuck-infra/commit/dae23aa5becf6161390b71d1902c00653fb424b8))


### Bug Fixes

* enable eventarc API and grant project IAM admin to deployer ([80669fb](https://github.com/tajturbo/chuck-infra/commit/80669fbe4121c09d7efee32f47818dde060ea3ca))
* **finops:** avoid update_mask for older run client ([973292a](https://github.com/tajturbo/chuck-infra/commit/973292ac77492725493102ecff75fb388591c5f8))
* **finops:** grant additional Eventarc and Run Viewer roles to FinOps SAs ([497d3b2](https://github.com/tajturbo/chuck-infra/commit/497d3b24f50d96cb60316e25e03792dffdd7a15a))
* **finops:** grant artifactregistry.reader to FinOps SAs ([fffb8a7](https://github.com/tajturbo/chuck-infra/commit/fffb8a7c1f762987e7a50c9311f497c7fad9a20b))
* **finops:** grant Service Account User permission to FinOps SAs on default compute SA ([5e36aa6](https://github.com/tajturbo/chuck-infra/commit/5e36aa6af567664f2109c1307aca3a6e7ea4a28f))
* **finops:** handle ingress NONE with older client ([9e28022](https://github.com/tajturbo/chuck-infra/commit/9e2802257f4795b969bce46ca4473f12a96fdcd3))
* **finops:** keep ingress ALL during sleep ([9d412ee](https://github.com/tajturbo/chuck-infra/commit/9d412eeb123d22d56adc645fd0ec9142420ee3b9))
* pass GCP_PROJECT to Cloud Function and refine project_id detection in main.py ([f0c2239](https://github.com/tajturbo/chuck-infra/commit/f0c2239e53f8efcdf11c07b9cdc97293dbd1ecf8))
* pre-create FinOps SAs in setup-wif.sh and add Service Account Admin role ([f4abed4](https://github.com/tajturbo/chuck-infra/commit/f4abed47e5e24a9150b0029d171eafa2f471b957))
* **wif:** grant necessary IAM permissions for FinOps resources in setup-wif.sh ([01fdefc](https://github.com/tajturbo/chuck-infra/commit/01fdefca6bd7f5b2fd979f460b9171af7e9aa7ab))


### Documentation

* update scaling terminology to manual scaling ([4c68f58](https://github.com/tajturbo/chuck-infra/commit/4c68f58f6944bdbbb8ca5f78fc049b52fc7a4852))

## [0.1.2](https://github.com/tajturbo/chuck-infra/compare/v0.1.1...v0.1.2) (2025-12-18)


### Bug Fixes

* resolve typo in terraform plan command ([df0085a](https://github.com/tajturbo/chuck-infra/commit/df0085a65b8ebd42990e183fe0df95d01ffb51f0))


### Documentation

* add CI/CD status badges and environments table to README ([def5fda](https://github.com/tajturbo/chuck-infra/commit/def5fda5f13c67ecf121f440a5cdc4105915433c))
* finalize release process and remove obsolete files ([1645200](https://github.com/tajturbo/chuck-infra/commit/1645200f0e2c7a4515a32baba5de0b93f0e58efb))
* refine release process and deduplicate documentation ([a652d76](https://github.com/tajturbo/chuck-infra/commit/a652d764ec7621a4d1886f0e35fdb232bb8167d9))
* refine release process and deduplicate documentation ([916ed7f](https://github.com/tajturbo/chuck-infra/commit/916ed7fb623b06cd89e339e577917b3afefec495))
* restructure guides into initial setup and continuous deployment ([a08d18a](https://github.com/tajturbo/chuck-infra/commit/a08d18a122922adc1cfd015ecf342a6a88bda083))
* update development workflows and contributing guide ([e197938](https://github.com/tajturbo/chuck-infra/commit/e197938a7a9507f16d24a27470ba5b72795afe6b))
* update environment URLs in README with live endpoints ([48799b1](https://github.com/tajturbo/chuck-infra/commit/48799b127b6d8cd0c3f9a1de87969d2f65949078))

## [0.1.1](https://github.com/tajturbo/chuck-infra/compare/v0.1.0...v0.1.1) (2025-12-18)


### Bug Fixes

* **infra:** remove conflicting default_route_action from default url map ([716e561](https://github.com/tajturbo/chuck-infra/commit/716e56138614a3fd93c2be49f652daaeff1baf9f))
* **infra:** remove conflicting default_route_action from http_redirect ([ee6b6a1](https://github.com/tajturbo/chuck-infra/commit/ee6b6a145e6f5c2b295acba71f066b23bf68edc1))


### Documentation

* finalize task and walkthrough for CI/CD refinements ([f534a94](https://github.com/tajturbo/chuck-infra/commit/f534a94896a246f5332f2843e4011ad6fa45533d))

## 0.1.0 (2025-12-18)


### Features

* **app:** add flask application with docker configuration ([ee94f7c](https://github.com/tajturbo/chuck-infra/commit/ee94f7cb6c35c70a30de0a5a0d4c8bab37401503))
* automate integration tests after infra apply ([69c684b](https://github.com/tajturbo/chuck-infra/commit/69c684bcc9faef56475880875126ac3f430d1369))
* implement GitOps workflow with auto-commit image tags ([b44b58b](https://github.com/tajturbo/chuck-infra/commit/b44b58b61f9d38d450fdec134fe070848baffc32))
* **infra:** add terraform modules for gcp deployment ([c90ccc1](https://github.com/tajturbo/chuck-infra/commit/c90ccc178f4cb886f5f7230c3315357d9c741630))
* refine load balancer routing and finalize architecture ports ([1397f40](https://github.com/tajturbo/chuck-infra/commit/1397f40a13c6a17d59d37aa7a36000c0842c40a0))


### Bug Fixes

* **ci:** add setup-gcloud to docker build workflow for auth ([7066b5e](https://github.com/tajturbo/chuck-infra/commit/7066b5e72cf03fd47405fe306d3cf3df8eb60bab))
* **scripts:** update wif setup with repo owner constraint ([2455ce6](https://github.com/tajturbo/chuck-infra/commit/2455ce62a3a0afac1bfd5d8c2b9dddd14c1a2f94))


### Documentation

* add initial project documentation and structure ([a908d2c](https://github.com/tajturbo/chuck-infra/commit/a908d2cc5f735befd29c1569563c4c16a900586b))
* add missing Service Account Token Creator role ([05c7474](https://github.com/tajturbo/chuck-infra/commit/05c747406c61512bd377332e9faa4f0d103ab65b))
* add troubleshooting tip for specific local impersonation permissions ([946d53e](https://github.com/tajturbo/chuck-infra/commit/946d53e19902da20762db3a05bd3e89170780562))
* clarify TF_STATE_BUCKET format in deployment guide ([ff6cec8](https://github.com/tajturbo/chuck-infra/commit/ff6cec86b2fe091e1736a880f50de4cceae50c94))
* comprehensive documentation audit and enhancement ([b4dfea2](https://github.com/tajturbo/chuck-infra/commit/b4dfea22523b1e0961818dc17a62e252bf755add))
* correct deployment steps for manual registry ([b89b512](https://github.com/tajturbo/chuck-infra/commit/b89b512229e1bd561d3716fd1cbdd14f659794ea))
* fix formatting in deployment guide ([4420266](https://github.com/tajturbo/chuck-infra/commit/44202667f0b81c1f6680a68d5b48a7ab0432e37b))
* update deployment guide with WIF helper script and manual setup fixes ([3ae8f4c](https://github.com/tajturbo/chuck-infra/commit/3ae8f4cb3d49c9e5dbf45ec12adc5eb189ad60a7))
