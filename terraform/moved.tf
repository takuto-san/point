# Keep existing state addresses stable after extracting the implementation into a child module.
moved {
  from = aws_apigatewayv2_api.management
  to   = module.management_platform.aws_apigatewayv2_api.management
}

moved {
  from = aws_apigatewayv2_integration.api
  to   = module.management_platform.aws_apigatewayv2_integration.api
}

moved {
  from = aws_apigatewayv2_route.put_analysis
  to   = module.management_platform.aws_apigatewayv2_route.put_analysis
}

moved {
  from = aws_apigatewayv2_route.get_receipt
  to   = module.management_platform.aws_apigatewayv2_route.get_receipt
}

moved {
  from = aws_cloudwatch_log_group.api_gateway
  to   = module.management_platform.aws_cloudwatch_log_group.api_gateway
}

moved {
  from = aws_apigatewayv2_stage.default
  to   = module.management_platform.aws_apigatewayv2_stage.default
}

moved {
  from = aws_lambda_permission.api_gateway
  to   = module.management_platform.aws_lambda_permission.api_gateway
}

moved {
  from = data.archive_file.receiver
  to   = module.management_platform.data.archive_file.receiver
}

moved {
  from = aws_iam_role.receiver
  to   = module.management_platform.aws_iam_role.receiver
}

moved {
  from = aws_iam_role_policy.receiver
  to   = module.management_platform.aws_iam_role_policy.receiver
}

moved {
  from = aws_cloudwatch_log_group.receiver
  to   = module.management_platform.aws_cloudwatch_log_group.receiver
}

moved {
  from = aws_lambda_function.receiver
  to   = module.management_platform.aws_lambda_function.receiver
}

moved {
  from = aws_lambda_event_source_mapping.intake
  to   = module.management_platform.aws_lambda_event_source_mapping.intake
}

moved {
  from = aws_dynamodb_table.applications
  to   = module.management_platform.aws_dynamodb_table.applications
}

moved {
  from = aws_sqs_queue.intake_dlq
  to   = module.management_platform.aws_sqs_queue.intake_dlq
}

moved {
  from = aws_sqs_queue.intake
  to   = module.management_platform.aws_sqs_queue.intake
}

moved {
  from = aws_cloudwatch_event_bus.l3_results
  to   = module.management_platform.aws_cloudwatch_event_bus.l3_results
}

moved {
  from = aws_cloudwatch_event_bus_policy.allow_l3
  to   = module.management_platform.aws_cloudwatch_event_bus_policy.allow_l3
}

moved {
  from = data.aws_iam_policy_document.event_bus
  to   = module.management_platform.data.aws_iam_policy_document.event_bus
}

moved {
  from = aws_cloudwatch_event_rule.analysis_snapshot
  to   = module.management_platform.aws_cloudwatch_event_rule.analysis_snapshot
}

moved {
  from = aws_cloudwatch_event_target.intake
  to   = module.management_platform.aws_cloudwatch_event_target.intake
}

moved {
  from = aws_sqs_queue_policy.events
  to   = module.management_platform.aws_sqs_queue_policy.events
}

moved {
  from = aws_cognito_user_pool.staff
  to   = module.management_platform.aws_cognito_user_pool.staff
}

moved {
  from = aws_cognito_user_pool_client.staff_web
  to   = module.management_platform.aws_cognito_user_pool_client.staff_web
}

moved {
  from = aws_s3_bucket.admin_web
  to   = module.management_platform.aws_s3_bucket.admin_web
}

moved {
  from = aws_s3_bucket_public_access_block.admin_web
  to   = module.management_platform.aws_s3_bucket_public_access_block.admin_web
}

moved {
  from = aws_s3_bucket_server_side_encryption_configuration.admin_web
  to   = module.management_platform.aws_s3_bucket_server_side_encryption_configuration.admin_web
}

moved {
  from = aws_cloudfront_origin_access_control.admin_web
  to   = module.management_platform.aws_cloudfront_origin_access_control.admin_web
}

moved {
  from = aws_cloudfront_distribution.admin_web
  to   = module.management_platform.aws_cloudfront_distribution.admin_web
}

moved {
  from = data.aws_iam_policy_document.admin_web
  to   = module.management_platform.data.aws_iam_policy_document.admin_web
}

moved {
  from = aws_s3_bucket_policy.admin_web
  to   = module.management_platform.aws_s3_bucket_policy.admin_web
}
