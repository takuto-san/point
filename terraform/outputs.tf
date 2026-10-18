output "management_account_id" {
  description = "管理システム用AWSアカウントID。"
  value       = var.management_account_id
}

output "management_api_base_url" {
  description = "管理APIのベースURL。"
  value       = module.management_platform.management_api_base_url
}

output "management_event_bus_arn" {
  description = "L3からの結果を受け付けるEventBridgeイベントバスARN。"
  value       = module.management_platform.management_event_bus_arn
}

output "admin_web_domain" {
  description = "管理画面を配信するCloudFrontドメイン名。"
  value       = module.management_platform.admin_web_domain
}

output "staff_user_pool_id" {
  description = "管理画面スタッフ用Cognito User Pool ID。"
  value       = module.management_platform.staff_user_pool_id
}
