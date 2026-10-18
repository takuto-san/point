provider "aws" {
  alias               = "management"
  region              = var.aws_region
  profile             = var.management_aws_profile
  allowed_account_ids = [var.management_account_id]

  default_tags {
    tags = local.common_tags
  }
}

provider "archive" {}
