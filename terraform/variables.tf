variable "project_name" {
  description = "リソース名の接頭辞。"
  type        = string
  default     = "point-award"
}

variable "environment" {
  description = "環境名。"
  type        = string
  default     = "dev"
}

variable "aws_region" {
  description = "管理アカウントで利用するAWSリージョン。"
  type        = string
  default     = "ap-northeast-1"
}

variable "management_aws_profile" {
  description = "管理システム用AWSアカウントのCLIプロファイル。"
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
  description = "結果連携を許可するL3アカウントID。point-l3の適用先と一致させる。"
  type        = string
  validation {
    condition     = can(regex("^[0-9]{12}$", var.l3_account_id))
    error_message = "12桁のAWSアカウントIDを指定してください。"
  }
}

variable "log_retention_days" {
  description = "CloudWatch Logsの保持日数。"
  type        = number
  default     = 30
}

variable "tags" {
  description = "全AWSリソースへ付与する追加タグ。"
  type        = map(string)
  default     = {}
}
