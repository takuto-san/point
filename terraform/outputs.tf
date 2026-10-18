output "management_account_id" {
  value = var.management_account_id
}

output "management_api_base_url" {
  value = "${aws_apigatewayv2_api.management.api_endpoint}/v1"
}

output "management_event_bus_arn" {
  value = aws_cloudwatch_event_bus.l3_results.arn
}

output "admin_web_domain" {
  value = aws_cloudfront_distribution.admin_web.domain_name
}

output "staff_user_pool_id" {
  value = aws_cognito_user_pool.staff.id
}
