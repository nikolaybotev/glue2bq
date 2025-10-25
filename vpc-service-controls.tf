# Enable Access Context Manager API
resource "google_project_service" "accesscontextmanager" {
  project = var.gcp_project_id
  service = "accesscontextmanager.googleapis.com"
  
  disable_dependent_services = false
}

# VPC Service Controls Service Perimeter
resource "google_access_context_manager_service_perimeter" "main" {
  parent = "accessPolicies/${google_access_context_manager_access_policy.main.name}"
  name   = "accessPolicies/${google_access_context_manager_access_policy.main.name}/servicePerimeters/${local.resource_prefix}_perimeter"
  title  = "${local.resource_prefix} Service Perimeter"

  status {
    resources = ["projects/${var.gcp_project_id}"]
    
    restricted_services = [
      "storage.googleapis.com",
      "storagetransfer.googleapis.com",
      "bigquery.googleapis.com",
      "bigqueryomni.googleapis.com",
      "bigqueryconnection.googleapis.com",
      "cloudkms.googleapis.com",
      "iam.googleapis.com",
      "serviceusage.googleapis.com"
    ]
  }

  depends_on = [google_access_context_manager_access_policy.main]
}

resource "google_access_context_manager_access_policy" "main" {
  parent = "organizations/${var.gcp_organization_id}"
  title  = "${local.resource_prefix} Access Policy"
  
  depends_on = [google_project_service.accesscontextmanager]
}
