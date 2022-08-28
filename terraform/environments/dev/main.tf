# project-specific locals
locals {
  env = var.env
  #TODO: change
  region           = var.region
  firestore_region = var.firestore_region
  multiregion      = var.multiregion
  project_id       = var.project_id
  services = [
    "appengine.googleapis.com",            # AppEngine
    "artifactregistry.googleapis.com",     # Artifact Registry
    "bigquery.googleapis.com",             # BigQuery
    "bigquerydatatransfer.googleapis.com", # BigQuery Data Transfer
    "cloudbuild.googleapis.com",           # Cloud Build
    "compute.googleapis.com",              # Load Balancers, Cloud Armor
    "container.googleapis.com",            # Google Kubernetes Engine
    "containerregistry.googleapis.com",    # Google Container Registry
    "dataflow.googleapis.com",             # Cloud Dataflow
    "documentai.googleapis.com",           # Document AI
    "eventarc.googleapis.com",             # Event Arc
    "firebase.googleapis.com",             # Firebase
    "firestore.googleapis.com",            # Firestore
    "iam.googleapis.com",                  # Cloud IAM
    "logging.googleapis.com",              # Cloud Logging
    "monitoring.googleapis.com",           # Cloud Operations Suite
    "run.googleapis.com",                  # Cloud Run
    "secretmanager.googleapis.com",        # Secret Manager
    "storage.googleapis.com",              # Cloud Storage
  ]
}

data "google_project" "project" {}

# Displaying the cloudrun endpoint
data "google_cloud_run_service" "queue-run" {
  name     = "queue-cloudrun"
  location = var.region
}

module "project_services" {
  source     = "../../modules/project_services"
  project_id = var.project_id
  services   = local.services
}

resource "time_sleep" "wait_for_project_services" {
  depends_on      = [module.project_services]
  create_duration = "60s"
}

module "service_accounts" {
  depends_on = [time_sleep.wait_for_project_services]
  source     = "../../modules/service_accounts"
  project_id = var.project_id
  env        = var.env
}

module "firebase" {
  depends_on       = [time_sleep.wait_for_project_services]
  source           = "../../modules/firebase"
  project_id       = var.project_id
  firestore_region = var.firestore_region
}

module "vpc_network" {
  source      = "../../modules/vpc_network"
  project_id  = var.project_id
  vpc_network = "default-vpc"
  region      = var.region
}

module "gke" {
  depends_on = [
    time_sleep.wait_for_project_services,
    module.vpc_network
  ]
  source         = "../../modules/gke"
  project_id     = var.project_id
  cluster_name   = "main-cluster"
  vpc_network    = "default-vpc"
  region         = var.region
  min_node_count = 1
  max_node_count = 1
  machine_type   = "n1-standard-8"
}

module "ingress" {
  depends_on        = [module.gke]
  source            = "../../modules/ingress"
  project_id        = var.project_id
  cert_issuer_email = var.admin_email

  # Domains for API endpoint, excluding protocols.
  domain            = var.api_domain
  region            = var.region
  cors_allow_origin = "http://localhost:4200,http://localhost:3000,${var.api_domain}"
}

module "cloudrun" {
  depends_on = [
    time_sleep.wait_for_project_services,
    module.vpc_network
  ]
  source     = "../../modules/cloudrun"
  project_id = var.project_id
  name       = "queue-cloudrun"
  region     = var.region
  api_domain = var.api_domain
}

module "pubsub" {
  depends_on = [
    time_sleep.wait_for_project_services,
    module.service_accounts,
    module.cloudrun,
    data.google_cloud_run_service.queue-run
  ]
  source                = "../../modules/pubsub"
  topic                 = "queue-topic"
  project_id            = var.project_id
  region                = var.region
  cloudrun_name         = module.cloudrun.name
  cloudrun_location     = module.cloudrun.location
  cloudrun_endpoint     = module.cloudrun.endpoint
  service_account_email = "${data.google_project.project.number}-compute@developer.gserviceaccount.com"
  # service_account_email = "${data.google_project.project.number}-compute@developer.gserviceaccount.com"
}

module "validation_bigquery" {
  depends_on = [
    time_sleep.wait_for_project_services
  ]
  source = "../../modules/bigquery"
}

# ================= Document AI Parsers ====================

module "docai" {
  depends_on = [
    time_sleep.wait_for_project_services
  ]
  source     = "../../modules/docai"
  project_id = var.project_id

  # See modules/docai/README.md for available DocAI processor types.
  # Once applied Terraform changes, please run /setup/update_parser_config.sh
  # to automatically update common/src/common/parser_config.json.
  processors = {
    unemployment_form = "FORM_PARSER_PROCESSOR"
    claims_form       = "FORM_PARSER_PROCESSOR"
    driver_license    = "US_DRIVER_LICENSE_PROCESSOR"
    # utility_bill      = "UTILITY_PROCESSOR"
    # pay_stub        = "PAYSTUB_PROCESSOR"
  }
}

# ================= Storage buckets ====================

resource "google_storage_bucket" "default" {
  name                        = local.project_id
  location                    = local.multiregion
  storage_class               = "STANDARD"
  uniform_bucket_level_access = true
}

resource "google_storage_bucket" "document-upload" {
  name                        = "${local.project_id}-document-upload"
  location                    = local.multiregion
  storage_class               = "STANDARD"
  uniform_bucket_level_access = true
}

resource "google_storage_bucket" "docai-output" {
  name                        = "${local.project_id}-docai-output"
  location                    = local.multiregion
  storage_class               = "STANDARD"
  uniform_bucket_level_access = true
}

resource "google_storage_bucket" "assets" {
  name                        = "${local.project_id}-assets"
  location                    = local.multiregion
  storage_class               = "STANDARD"
  uniform_bucket_level_access = true
}

# ================= Validation Rules ====================

# Copying rules JSON files to GCS bucket.
resource "null_resource" "validation_rules" {
  depends_on = [
    google_storage_bucket.default
  ]
  provisioner "local-exec" {
    command = "gsutil cp ../../../common/src/common/validation_rules/* gs://${var.project_id}/Validation"
  }
}
