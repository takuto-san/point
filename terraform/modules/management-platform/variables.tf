variable "project_name" {
  description = "リソース名の接頭辞。"
  type        = string
}

variable "environment" {
  description = "環境名。"
  type        = string
}

variable "management_account_id" {
  description = "管理システム用AWSアカウントID。"
  type        = string

  validation {
    condition     = can(regex("^[0-9]{12}$", var.management_account_id))
    error_message = "12桁のAWSアカウントIDを指定してください。"
  }
}

variable "l3_account_id" {
  description = "結果連携を許可するL3アカウントID。"
  type        = string

  validation {
    condition     = can(regex("^[0-9]{12}$", var.l3_account_id))
    error_message = "12桁のAWSアカウントIDを指定してください。"
  }
}

variable "log_retention_days" {
  description = "CloudWatch Logsの保持日数。"
  type        = number
}

variable "openapi_document" {
  description = "Lambdaパッケージに同梱するOpenAPI YAML。"
  type        = string
}
