module "management_platform" {
  source = "./modules/management-platform"

  providers = {
    aws.management = aws.management
  }

  project_name          = var.project_name
  environment           = var.environment
  management_account_id = var.management_account_id
  l3_account_id         = var.l3_account_id
  log_retention_days    = var.log_retention_days
  openapi_document      = file("${path.root}/../openapi.yml")
}
