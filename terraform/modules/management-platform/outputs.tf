output "management_api_base_url" {
  description = "管理APIのベースURL。"
  value       = "${aws_apigatewayv2_api.management.api_endpoint}/v1"
}

output "management_event_bus_arn" {
  description = "L3からの結果を受け付けるEventBridgeイベントバスARN。"
  value       = aws_cloudwatch_event_bus.l3_results.arn
}

output "admin_web_domain" {
  description = "管理画面を配信するCloudFrontドメイン名。"
  value       = aws_cloudfront_distribution.admin_web.domain_name
}

output "staff_user_pool_id" {
  description = "管理画面スタッフ用Cognito User Pool ID。"
  value       = aws_cognito_user_pool.staff.id
}
