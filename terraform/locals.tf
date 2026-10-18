locals {
  name = "${var.project_name}-${var.environment}"

  common_tags = merge({
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    DataClass   = "Restricted"
  }, var.tags)
}
