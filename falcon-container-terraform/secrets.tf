variable "falcon_client_id" {
  description = "CrowdStrike Falcon / OAuth2 API / Client ID (needs only permissions to download falcon container sensor) (Alternatively, set env variable TF_VAR_falcon_client_id)"
  sensitive   = true
}

variable "falcon_client_secret" {
  description = "CrowdStrike Falcon / OAuth2 API / Client Secret (needs only permissions to download falcon container sensor) (Alternatively, set env variable TF_VAR_falcon_client_secret)"
  sensitive   = true
}

variable "falcon_cloud" {
  description = "Falcon cloud region abbreviation (us-1, us-2, eu-1, us-gov-1) (Alternatively, set env variable TF_VAR_falcon_cloud)"
  validation {
    condition     = (var.falcon_cloud == "us-1" || var.falcon_cloud == "us-2" || var.falcon_cloud == "eu-1" || var.falcon_cloud == "us-gov-1")
    error_message = "Variable falcon_cloud must be set to one of: us-1, us-2, eu-1, us-gov-1."
  }
}

variable "falcon_cid" {
  description = "CrowdStrike Falcon CID (full cid string) (Alternatively, set env variable TF_VAR_falcon_cid)"
  sensitive   = true
}


resource "google_project_service" "secretmanager" {
  provider           = google
  service            = "secretmanager.googleapis.com"
  disable_on_destroy = false
}

resource "google_secret_manager_secret" "FALCON_CLIENT_ID" {
  secret_id = "${var.tenant}-FALCON_CLIENT_ID"

  replication {
    automatic = true
  }

  depends_on = [google_project_service.secretmanager]
}

resource "google_secret_manager_secret" "FALCON_CLIENT_SECRET" {
  secret_id = "${var.tenant}-FALCON_CLIENT_SECRET"

  replication {
    automatic = true
  }

  depends_on = [google_project_service.secretmanager]
}

resource "google_secret_manager_secret" "FALCON_CLOUD" {
  secret_id = "${var.tenant}-FALCON_CLOUD"

  replication {
    automatic = true
  }

  depends_on = [google_project_service.secretmanager]
}

resource "google_secret_manager_secret" "FALCON_CID" {
  secret_id = "${var.tenant}-FALCON_CID"

  replication {
    automatic = true
  }

  depends_on = [google_project_service.secretmanager]
}

resource "google_secret_manager_secret_version" "FALCON_CLIENT_ID" {
  secret      = google_secret_manager_secret.FALCON_CLIENT_ID.id
  secret_data = var.falcon_client_id
}

resource "google_secret_manager_secret_version" "FALCON_CLIENT_SECRET" {
  secret      = google_secret_manager_secret.FALCON_CLIENT_SECRET.id
  secret_data = var.falcon_client_secret
}

resource "google_secret_manager_secret_version" "FALCON_CLOUD" {
  secret      = google_secret_manager_secret.FALCON_CLOUD.id
  secret_data = var.falcon_cloud
}
resource "google_secret_manager_secret_version" "FALCON_CID" {
  secret      = google_secret_manager_secret.FALCON_CID.id
  secret_data = var.falcon_cid
}

resource "google_secret_manager_secret_iam_member" "gke-admin-reads-falcon-client-id" {
  secret_id = google_secret_manager_secret.FALCON_CLIENT_ID.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.gke-admin-vm.email}"
}

resource "google_secret_manager_secret_iam_member" "gke-admin-reads-falcon-client-secret" {
  secret_id = google_secret_manager_secret.FALCON_CLIENT_SECRET.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.gke-admin-vm.email}"
}

resource "google_secret_manager_secret_iam_member" "gke-admin-reads-falcon-cloud" {
  secret_id = google_secret_manager_secret.FALCON_CLOUD.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.gke-admin-vm.email}"
}

resource "google_secret_manager_secret_iam_member" "gke-admin-reads-falcon-cid" {
  secret_id = google_secret_manager_secret.FALCON_CID.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.gke-admin-vm.email}"
}
