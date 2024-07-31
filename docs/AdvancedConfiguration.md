# Advanced Configuration Options for Claims Data Activator (CDA)
<!-- TOC -->
* [Advanced Configuration Options for Claims Data Activator (CDA)](#advanced-configuration-options-for-claims-data-activator--cda-)
* [Introduction](#introduction)
  * [Additional Options](#additional-options)
    * [Private vs Public End Point](#private-vs-public-end-point)
    * [Using Shared VPC](#using-shared-vpc)
    * [Identity Platform](#identity-platform)
    * [IAP setup](#iap-setup)
    * [IAP With External identity](#iap-with-external-identity)
      * [Errors](#errors)
* [Configuration](#configuration)
  * [Setting up CDE and CDS](#setting-up-cde-and-cds)
    * [Custom Document Extractor](#custom-document-extractor)
    * [Custom Document Classifier](#custom-document-classifier)
  * [Configuring the System](#configuring-the-system)
    * [Adding Classifier](#adding-classifier)
    * [Adding Support for Additional Type of Forms](#adding-support-for-additional-type-of-forms)
    * [General Settings](#general-settings)
  * [Cross-Project Setup](#cross-project-setup)
    * [Introduction](#introduction-1)
    * [Same Organizational Setup (Only)](#same-organizational-setup--only-)
    * [Two different Organizations - Cross Organization Setup (Only)](#two-different-organizations---cross-organization-setup--only-)
      * [Reset Organization Policy for Domain restricted sharing](#reset-organization-policy-for-domain-restricted-sharing)
    * [Grant Required permissions to DocAI Project](#grant-required-permissions-to-docai-project)
      * [Option 1 - using service account](#option-1---using-service-account)
    * [Option 2 - using managed Group (Alternative)](#option-2---using-managed-group--alternative-)
    * [Grant Required permissions to CDA engine Project](#grant-required-permissions-to-cda-engine-project)
    * [Setting up config](#setting-up-config)
* [CDA Usage](#cda-usage)
  * [When Using Private Access](#when-using-private-access)
* [<a name="rebuild-redeploy-microservices"></a> Rebuild / Re-deploy Microservices](#a-namerebuild-redeploy-microservices-a-rebuild--re-deploy-microservices)
  * [Upgrading Infrastructure](#upgrading-infrastructure)
  * [Deploy microservices](#deploy-microservices)
* [Utilities](#utilities)
  * [Prerequisites](#prerequisites)
  * [Testing Utilities](#testing-utilities)
  * [Cleaning Data](#cleaning-data)
  * [Configuration Service](#configuration-service)
  * [Splitter](#splitter)
* [Deployment Troubleshoot](#deployment-troubleshoot)
  * [Checking SSL certificates](#checking-ssl-certificates)
  * [Terraform Troubleshoot](#terraform-troubleshoot)
    * [App Engine already exists](#app-engine-already-exists)
  * [CloudRun Troubleshoot](#cloudrun-troubleshoot)
  * [Frontend Web App](#frontend-web-app)
  * [Troubleshooting Commands](#troubleshooting-commands)
* [CDA Troubleshoot](#cda-troubleshoot)
  * [Errors when using Classifier/Extractor](#errors-when-using-classifierextractor)
  * [Classification Service Logs](#classification-service-logs)
* [Development Guide](#development-guide)
<!-- TOC -->

# Introduction

For a Quick Start and Demo Guide refer to the [README](../README.md), that explains how to install CDA engine. 
Use these instructions to explore in-depth customizations and installation options if needed.


## Additional Options

### Private vs Public End Point
You have an option to expose UI externally in public internet, or make it fully internal within the internal network.
When exposed, the end point (via domain name) will be accessible via Internet and protected by Firebase Authentication and optionally IAP, enforced
on all the end points.
When protected, you will need machine in the same internal network in order to access the UI (for testing, you could create Windows VM in the same network and access it via RDP using IAP tunnel).

By default, the end-point is private (so then when upgrading customer accidentally end point does not become open unintentionally).
The preference can be set in `terraform/stages/foundation/terraform.tfvars` file via `cda_external_ui` parameter:

```shell
cda_external_ui = false       # Expose UI to the Internet: true or false
```

For simple demo purposes you probably want to expose the end point (`cda_external_ui = true`).

### Using Shared VPC
As is often the case in real-world configurations, this blueprint accepts as input an existing [Shared-VPC](https://cloud.google.com/vpc/docs/shared-vpc)
via the `network_config` variable inside [terraform.tfvars](terraform/stages/foundation/terraform.sample.tfvars).
Follow [these steps](docs/SharedVPC_steps.md) to prepare environment with VPC Host Project and Service project.

- Edit `terraform/stages/foundation/terraform.tfvars` in the editor,
- uncomment `network_config` and fill in required parameters inside `network_config` (when using the [steps above](docs/SharedVPC_steps.md),
- only need to set `HOST_PROJECT_ID`, all other variables are pre-filled correctly):
 ```
network_config = {
  host_project      = "HOST_PROJECT_ID"
  network = "cda-vpc"   #SHARED_VPC_NETWORK_NAME"
  subnet  = "tier-1"    #SUBNET_NAME
  gke_secondary_ranges = {
    pods     = "tier-1-pods"       #SECONDARY_SUBNET_PODS_RANGE_NAME
    services = "tier-1-services"   #SECONDARY_SUBNET_SERVICES_RANGE_NAME"
  }
  region = "us-central1"
}
```

When the **default GKE Control Plane CIDR Range (172.16.0.0/28) overlaps** with your network:
- Edit `terraform.tfvars` in the editor, uncomment `master_ipv4_cidr_block` and fill in the value of the GKE Control Plane CIDR /28 range:
 ```shell
 master_ipv4_cidr_block = "MASTER.CIDR/28.HERE"
 ```

For example, if you have already one CDA installation in your shared vpc and want a second installation, you should manually set master_ipv4_cidr_block to avoid conflicts:
 ```shell
master_ipv4_cidr_block =172.16.16.0/28
 ```

###  Identity Platform
Optionally, Enable Identity Platform via [Cloud Shell](https://console.cloud.google.com/marketplace/details/google-cloud-platform/customer-identity)
  - It will ask your confirmation to perform Firebase Upgrade and will import all Firebase settings.


### IAP setup

Optionally, enable [IAP](https://cloud.google.com/iap/docs/enabling-kubernetes-howto) to protect all the backend services.
Make sure that if you already have created [oAuth Consent screen](https://console.cloud.google.com/apis/credentials/consent), it is marked as Internal type.


Make sure Env variables are set:
```shell
export PROJECT_ID=
```

Run following script to enable IAP:
```shell
bash -e iap/enable_iap.sh
```

Run following command to disable IAP:
```shell
bash -e iap/disable_iap.sh
```

### IAP With External identity
When not using GCP identity for IAP, following steps to be executed:

1. Modify `Domain restricted sharing` [Org Policy](https://console.cloud.google.com/iam-admin/orgpolicies/) and make it to _Allow All_
2. Go to [oAuth Consent Screen](https://console.cloud.google.com/apis/credentials/consent) and make **User type**  _External_
3. [Create google group](https://groups.google.com/my-groups) and add required members to it.
4. [Grant](https://console.cloud.google.com/iam-admin/iam) `IAP-secured Web-App User` Role to the newly created google group as the Principal

#### Errors
When getting error:
```
Access blocked: CDA Application can only be used within its organization
```

Make sure that steps 1 and 2 above are executed.

# Configuration
## Setting up CDE and CDS

**Pre-requisites**
- There should be at least 20 (recommended 50) customer  forms with filled data (of the same type), which could be used for training the processor for extraction and classification.
- All forms need to be in pdf format


If you have png files, following script can convert them to pdf:
```shell
python3 -m pip install --upgrade Pillow
python utils/fake_data_generation/png2pdf.py -d sample_data/<input-dir> -o sample_data/<output_pdf_dir>
```

### Custom Document Extractor
The Custom Document Extractor has already been deployed, but not yet trained. The steps need to be done manual and via the UI.
- Manually Configure and [Train Custom Document Extractor](https://cloud.google.com/document-ai/docs/workbench/build-custom-processor) (currently it is deployed but not pre-trained)
  - Using UI Manually Label and Train Custom Document Extractor to recognize selected type of the PriorAuth forms.
  - Set a default revision for the processor.
  - Test extraction by manually uploading document via the UI and check how entities are being extracted and assigned labels.

You can deploy and train additional Custom Document Extractor if you navigate to **Document AI -> Workbench** and select **Custom Document Extractor** -> CREATE PROCESSOR

### Custom Document Classifier
Classifier allows mapping the document class to the processor required for data extraction.

Configure Custom Document Classifier (Currently feature is not available for GA and needs to be requested via the [form](https://docs.google.com/forms/d/e/1FAIpQLSfDuC9bGyEwnseEYIC3I2LvNjzz-XZ2n1RS4X5pnIk2eSbk3A/viewform))
- After Project has been whitelisted for using Classifier, navigate to **Document AI -> Workbench**  and select **Custom Document Classifier** -> CREATE PROCESSOR.
- Create New Labels for each document type you plan to use.
- Train Classifier using sample forms to classify the labels.
- Deploy the new trained version via the UI.
- Set the new version as default and test it manually via the UI by uploading the test document. is it classified properly?

> If you have just one sample_form.pdf, and you want to use it for classifier, use following utility to copy same form into the gcs bucket, later to use for classification. At least 10 instances are needed (all for Training set).
```shell
utils/copy_forms.sh -f sample_data/<path_to_form>.pdf -d gs://<path_to_gs_uri> -c 10
```

## Configuring the System
- Config file is stored in the GCS bucket and dynamically used by the pipeline: `gs://${PROJECT_ID}-config/config.json`


- For the config changes, download, edit, and upload the  `gs://${PROJECT_ID}-config/config.json` file:

  ```shell
  gsutil cp "gs://${PROJECT_ID}-config/config.json" common/src/common/configs/config.json 
  ```

- Apply required changes as discussed later in this section.

- Upload config:
  ```shell
  gsutil cp common/src/common/configs/config.json "gs://${PROJECT_ID}-config/config.json"

### Adding Classifier
Since currently Classifier is not in GA and has to be manually created, following section needs to be added inside  `parser_config` to activate Classification step (replace  <PROJECT_ID> and <PROCESSOR_ID> accordingly):

```shell
"parser_config": {
    # ... parsers here ...
    
    "classifier": {
      "location": "us",
      "parser_type": "CUSTOM_CLASSIFICATION_PROCESSOR",
      "processor_id": "projects/<PROJECT_ID>/locations/us/processors/<PROCESSOR_ID>"
    }
  }
```


### Adding Support for Additional Type of Forms

1. Deploy and train the DocAI  processor.


2. After processor is created and deployed, add following entry (replace <parser_name> with the name which best describes the processor purpose)  inside `parser_config`:
```shell
"parser_config": {
    # ... parsers here ...
      
    "<parser_name>": {
      "processor_id": "projects/<PROJECT_ID>/locations/us/processors/<PROCESSOR_ID>"
    }
}
```

3. Add configuration for the document type entry inside `document_types_config`:

```shell
"document_types_config": {
     # ... document configurations here ... 
     
    "<document_type_name>": {
        "doc_type": {
          "default": "Non-urgent",
          "rules": [
            {
              "ocr_text": "urgent",
              "name": "Urgent-Generic"
            }
          ]
        },
        "display_name": "<Name of the Form>",
        "classifier_label": "<Label-as-trained>",
        "parser": "<parser_name>"
    }  
}

```

```shell
"document_types_config": {
     # ... document configurations here ... 
     
    "<document_type_name>": {
        "doc_type": {
          "default": "Non-urgent",
          "rules": [
            {
              "entities": {
                "name": "reviewTypeUrgent",
                "value": true
              },
              "name": "Urgent-PA"
            }
          ]
        },
        "display_name": "<Name of the Form>",
        "classifier_label": "<Label-as-trained>",
        "parser": "<parser_name>"
    }  
}

```
Where:
- **doc_type** - Specifies rules for type detection (could be based on OCR text or on entity key_name/value)
- **display_name** - Text to be displayed in the UI for the 'Choose Document Type/Class' drop-down when manually Re-Classifying.
- **classifier_label** - As defined in the Classifier when training on the documents.
- **parser** - Parser name as defined in the `parser_config` section.

### General Settings
`settings_config` section currently supports the following parameters:

- `extraction_confidence_threshold` - threshold to mark documents for HITL as *Needs Review*. Compared with the *calculated average* confidence score across all document  labels.
- `field_extraction_confidence_threshold` - threshold to mark documents for HITL as *Needs Review*. Compared with the *minimum* confidence score across all document labels.
- `classification_confidence_threshold` - threshold to pass Classification step. When the confidence score as returned by the Classifier is less, the default behavior is determined by the `classification_default_class` setting. If the settings is "None" or non-existing document type, document remain *Unclassified*.
- `classification_default_class` - the default behavior for the unclassified forms (or when classifier is not configured). Needs to be a valid  name of the document type, as configured in the `document_types_config`.


## Cross-Project Setup

### Introduction
For further reference, lets define the two projects:
- GCP Project to run the Claims Data Activator - Engine (**Project CDA**) => Corresponds to `PROJECT_ID`
- GCP Project to train and serve Document AI Processor  (**Project DocAI**) => Corresponds to `DOCAI_PROJECT_ID`

```shell
export PROJECT_ID=
export DOCAI_PROJECT_ID=
```

To enable cross project access, following permissions need to be granted retrospectively:
1) Inside Project DocAI [add](https://medium.com/@tanujbolisetty/gcp-impersonate-service-accounts-36eaa247f87c) following service account of the Project CDA `gke-sa@$PROJECT_ID.iam.gserviceaccount.com` (used for GKE Nodes) and grant following  [roles](https://cloud.google.com/document-ai/docs/access-control/iam-roles):
- **Document AI Viewer** - To grant access to view all resources and process documents in Document AI.
2) Inside Project CDA grant following permissions to the default Document AI service account of the Project DocAI: `service-{PROJECT_DOCAI_NUMBER}@gcp-sa-prod-dai-core.iam.gserviceaccount.com`
- **Storage Object Viewer** - [To make files in Project CDA accessible to Project DocAI](https://cloud.google.com/document-ai/docs/cross-project-setup) (This could be done on the `${PROJECT_ID}-document-upload`).
- **Storage Object Admin**  - To allow DocAI processor to save extracted entities as json files inside `${PROJECT_ID}-docai-output` bucket of the Project CDA  (This could be done on the `${PROJECT_ID}-docai-output` bucket level).
  Where `{PROJECT_DOCAI_NUMBER}` - to be replaced with the Number of the `Project DocAI`.

### Same Organizational Setup (Only)
When both projects are within organization, following steps to be executed:

* Setting of the environment variables:

```shell
export DOCAI_PROJECT_ID=
export PROJECT_ID=
```

* Running a utility script:
```shell
./setup/setup_docai_access.sh
```

### Two different Organizations - Cross Organization Setup (Only)
When two projects are under different organizations, additional steps are required.

#### Reset Organization Policy for Domain restricted sharing
This step is only required when two `Project CDA` and `Project DocAI` do not belong to the same organization.
In that case following policy constraint `constraints/iam.allowedPolicyMemberDomain` needs to be modified for both of them and be set to  `Allowed All`.


Go to GCP Cloud Shell of `PROJECT_ID`:
```shell
export PROJECT_ID=
gcloud services enable orgpolicy.googleapis.com
gcloud org-policies reset constraints/iam.allowedPolicyMemberDomains --project=$PROJECT_ID
```

To verify changes:
```shell
gcloud resource-manager org-policies list --project=$PROJECT_ID
```
Sample output:
```shell
CONSTRAINT: constraints/iam.allowedPolicyMemberDomains
LIST_POLICY: SET
BOOLEAN_POLICY: -
ETAG: CMiArKIGENi33coC
```

Go to GCP Cloud Shell of `DOCAI_PROJECT_ID`:
```shell
export DOCAI_PROJECT_ID=
gcloud org-policies reset constraints/iam.allowedPolicyMemberDomains --project=$DOCAI_PROJECT_ID
```


[//]: # (Alternatively, changing of organization Policy could be done via UI.)

[//]: # (In order to do so, go to Cloud Console  IAM-> [Organization Policies]&#40;https://console.cloud.google.com/iam-admin/orgpolicies/list&#41; and find `constraints/iam.allowedPolicyMemberDomain` which refers to Domain restricted sharing.)

[//]: # ()
[//]: # (**Select `Manage policy` Icon**:)

[//]: # (* Applies to: => Customize)

[//]: # (* Policy Enforcement => Replace )

[//]: # (* Add rule => `Allow All`)

[//]: # ()
[//]: # (**and submit Save**)

[//]: # ()
[//]: # (Perform step above for both `Project DocAI` and `Project CDA`.)

### Grant Required permissions to DocAI Project

#### Option 1 - using service account
After modifying Organization Policy constraint, go to `Project DocAI` Console Shell and run following commands:
* Set env variables accordingly:
```shell
  export PROJECT_ID=
  export DOCAI_PROJECT_ID=
  gcloud config set project $DOCAI_PROJECT_ID
```
* Execute following commands to grant permissions:
```shell
  gcloud projects add-iam-policy-binding $DOCAI_PROJECT_ID --member="serviceAccount:gke-sa@${PROJECT_ID}.iam.gserviceaccount.com"  --role="roles/documentai.apiUser"
  gcloud projects add-iam-policy-binding $DOCAI_PROJECT_ID --member="serviceAccount:gke-sa@${PROJECT_ID}.iam.gserviceaccount.com"  --role="roles/documentai.viewer"
  PROJECT_DOCAI_NUMBER=$(gcloud projects describe "$DOCAI_PROJECT_ID" --format='get(projectNumber)')
  echo PROJECT_DOCAI_NUMBER=$PROJECT_DOCAI_NUMBER
```
* Copy PROJECT_DOCAI_NUMBER from the output above

### Option 2 - using managed Group (Alternative)
Alternatively, you could create a group in the Organization of DOCAI_PROJECT, grant permissions to the group and assign members to that group.

* Create a user group, that allows external users (later referred as `GROUP_EMAIL`) in the DocAI Project organization.

* Set env variables accordingly:
```shell
  export PROJECT_ID=
  export DOCAI_PROJECT_ID=
  export GROUP_EMAIL=
  gcloud config set project $DOCAI_PROJECT_ID
```

* Execute following commands to grant permissions:
```shell
gcloud projects add-iam-policy-binding $DOCAI_PROJECT_ID \
--member="group:${GROUP_EMAIL}" \
--role="roles/documentai.apiUser"
gcloud projects add-iam-policy-binding $DOCAI_PROJECT_ID \
--member="group:${GROUP_EMAIL}" \
--role="roles/documentai.viewer"
```

* Add member to the group:
```shell
gcloud identity groups memberships add --group-email="${GROUP_EMAIL}" --member-email="serviceAccount:gke-sa@${PROJECT_ID}.iam.gserviceaccount.com" --roles=MEMBER
```

### Grant Required permissions to CDA engine Project
Go to `Project CDA` Console Shell and run following commands:
* Set env variables accordingly:
```shell
  export PROJECT_ID=
  export DOCAI_PROJECT_ID=
  export PROJECT_DOCAI_NUMBER=
  gcloud config set project $PROJECT_ID
```
* Execute following commands:
```shell
  gcloud storage buckets add-iam-policy-binding  gs://${PROJECT_ID}-docai-output --member="serviceAccount:service-${PROJECT_DOCAI_NUMBER}@gcp-sa-prod-dai-core.iam.gserviceaccount.com" --role="roles/storage.admin"
  gcloud storage buckets add-iam-policy-binding  gs://${PROJECT_ID}-document-upload --member="serviceAccount:service-${PROJECT_DOCAI_NUMBER}@gcp-sa-prod-dai-core.iam.gserviceaccount.com" --role="roles/storage.objectViewer"
```


### Setting up config

Each entity inside `document_types_config` (corresponding to a different supported form type), can have optional Document AI Warehouse integration:
```shell
  "document_types_config": {
    "generic_form": {
      "display_name": "Generic Form",
      "parser": "claims_form_parser",
      "classifier_label": "Generic",
      "doc_type": {
        "default": "Non-urgent",
        "rules": [
          {
            "ocr_text": "urgent",
            "name": "Urgent-Generic"
          }
        ]
      }
    },
```


# CDA Usage
## When Using Private Access

- Create Windows VM in the VPC network used to deploy CDA Solution
- Create firewall rules to open up TCP:3389 port for RDP connection
- [Connect to Windows VM using RDP](https://cloud.google.com/compute/docs/instances/connecting-to-windows)
  - OpenUp IAP Tunnel by running following command:

  ```shell
  gcloud compute start-iap-tunnel VM_INSTANCE_NAME 3389     --local-host-port=localhost:3389     --zone=<YOUR_ONE> --project=$PROJECT_ID
  ```


# <a name="rebuild-redeploy-microservices"></a> Rebuild / Re-deploy Microservices

Update sources from the Git repo:
```shell
git pull
```

Set environment variables:
```shell
export PROJECT_ID=<set your project id here>
export API_DOMAIN=<set-api domain here>
```

## Upgrading Infrastructure
In some cases new features/fixes will involve changes to the infrastructure.
In that case you will need to re-run terraform for foundation and ingress: 

```shell
./init_foundation.sh
./init_ingress.sh
```
 
## Deploy microservices

The following wrapper script will use skaffold to rebuild/redeploy microservices:
```shell
./deploy.sh
```

You can additionally [clear all existing data (in GCS, Firestore and BigQuery)](#cleaning-data).


# Utilities
## Prerequisites
Make sure to install all required libraries prior to using utilities listed below:
```shell
pip3 install -r utils/requirements.tx
```
## Testing Utilities
- Following utility would be handy to list all the entities the Trained processor Could extract from the document:

  ```shell
  export RPOCESSOR_ID=<your_processor_id>
  python utils/gen_config_processor.py -f <my-local-dir>/<my-sample-form>.pdf 
  ```

## Cleaning Data

Make sure to first install dependency libraries for utilities:
```shell
pip3 install -r utils/requirements.txt
```

- Following script cleans all document related data (requires PROJECT_ID to be set upfront as an env variable):
  - Firestore `document` collection
  - BigQuery `validation` table
  - `${PROJECT_ID}-pa-forms` bucket
  - `${PROJECT_ID}-document-upload` bucket

  ```shell
  utils/cleanup.sh
  ```

> Please, note, that due to active StreamingBuffer, BigQuery can only be cleaned after a table has received no inserts for an extended interval of time (~ 90 minutes). Then the buffer is detached and DELETE statement is allowed.
> For more details see [here](https://cloud.google.com/blog/products/bigquery/life-of-a-bigquery-streaming-insert).

## Configuration Service
Config Service (used by adp ui):
- `http://$API_DOMAIN/config_service/v1/get_config?name=document_types_config`
- `http://$API_DOMAIN/config_service/v1/get_config`

## Splitter

[Included splitter utility to split the documents](utils/pdf-splitter/README.md).
# Deployment Troubleshoot


## Checking SSL certificates

```shell
gcloud compute ssl-certificates list --global
```

```shell
gcloud compute ssl-certificates describe CERTIFICATE_NAME  --global --format="get(name,managed.status, managed.domainStatus)"
```

```shell
kubectl describe managedcertificate
```

```shell
gcloud compute ssl-policies list
```

```shell
kubectl describe ingress
```

## Terraform Troubleshoot

### App Engine already exists
```
│ Error: Error creating App Engine application: googleapi: Error 409: This application already exists and cannot be re-created., alreadyExists
│
│   with module.firebase.google_app_engine_application.firebase_init,
│   on ../../modules/firebase/main.tf line 3, in resource "google_app_engine_application" "firebase_init":
│    3: resource "google_app_engine_application" "firebase_init" {
```

**Solution**: Import the existing project in Terraform:
```
cd terraform/stages/foundation
terraform import module.firebase.google_app_engine_application.firebase_init $PROJECT_ID

```

## CloudRun Troubleshoot

The CloudRun service “queue” is used as the task dispatcher from listening to Pub/Sub “queue-topic”
- Go to CloudRun logging to see the errors

## Frontend Web App

- When opening up the ADP UI for the first time, you’ll see the HTTPS not secure error, like below:
```
Your connection is not private
```

- Open the chrome://net-internals/#hsts in URL, and delete the domain HSTS.
- (Optional) Click the “Not Secure” icon on the top, and select the “Certificate is not valid” option, and select “Always Trust”.



## Troubleshooting Commands
```shell
terraform destroy -target=module.ingress
```

```shell
helm ls -n ingress-nginx
```

```shell
helm history ingress-nginx -n ingress-nginx
```

```shell
terraform state list
terraform state rm <...>

```

# CDA Troubleshoot

## Errors when using Classifier/Extractor

Such as `400 Error, Failed to process all documents`.
Make sure [Cross Project Access is setup](#cross-project-setup) between DocAI and CDA projects.

Can be resolved by running this script:
```shell
export DOCAI_PROJECT_ID=
export PROJECT_ID=
```

```shell
./setup/setup_docai_access.sh
```


## Classification Service Logs

Search for `Classification prediction` to get summary of the prediction results:

```shell
2023-04-14 17:35:52.542 PDT | Classification predictions for 76983ddc-db25-11ed-90fd-faad96329953_aOA5oKoKS3jszgrQ7rTr_bsc-dme-pa-form-1.pdf
2023-04-14 17:35:52.543 PDT | Classification prediction results: document_class=fax_cover_page with confidence=0.0008332811412401497
2023-04-14 17:35:52.543 PDT | Classification prediction results: document_class=pa_form_texas with confidence=0.0009312000474892557
2023-04-14 17:35:52.543 PDT | Classification prediction results: document_class=pa_form_cda with confidence=0.9972623586654663
2023-04-14 17:35:52.543 PDT | Classification prediction results: document_class=health_intake_form with confidence=0.0009731759782880545
2023-04-14 17:35:53.178 PDT | Classification prediction results: predicted_class=pa_form_cda, predicted_score=0.9972623586654663
```

# Development Guide

For development guide, refer [here](docs/Development.md).

```shell
$npm install -g firebase-tools
firebase --project $PROJECT_ID firestore:delete "/document/*" --recursive --force 
```
