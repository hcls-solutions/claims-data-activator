#Creating a cloud run service

resource "google_storage_bucket" "queue-log-bucket" {
  name          = "${var.project_id}-queue-log"
  location      = var.multiregion
  storage_class = "NEARLINE"
  uniform_bucket_level_access = true
}

resource "google_cloud_run_service" "queue-run" {
  name     = "queue-cloudrun"
  location = var.region

  template {
    spec {
      containers {
        image = "gcr.io/${var.project_id}/queue-image"  #Image to connect pubsub to cloud run to processtask API and fetch data from firestore
        ports{
            container_port=8000
        }
        env {
          name = "t"  #thresold value for comparison with the number of uploaded docs in firesotre collection
          value = "10"
          # API endpoint domain
          API_DOMAIN = var.api_domain
        }
      }
      service_account_name = module.cloud-run-service-account.email
    }
  }
  traffic {
    percent         = 100
    latest_revision = true
    }
  depends_on = [null_resource.provision]
}

#Displaying the cloudrun endpoint

output "cloud_run" {
    value = google_cloud_run_service.queue-run.status[0].url
}
