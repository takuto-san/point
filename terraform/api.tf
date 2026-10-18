resource "aws_apigatewayv2_api" "management" {
  provider = aws.management

  name          = "${local.name}-management"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "api" {
  provider = aws.management

  api_id                 = aws_apigatewayv2_api.management.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.receiver.invoke_arn
  payload_format_version = "2.0"
  timeout_milliseconds   = 29000
}

resource "aws_apigatewayv2_route" "put_analysis" {
  provider = aws.management

  api_id             = aws_apigatewayv2_api.management.id
  route_key          = "PUT /v1/applications/{applicationId}/analysis-revisions/{revision}"
  target             = "integrations/${aws_apigatewayv2_integration.api.id}"
  authorization_type = "AWS_IAM"
}

resource "aws_apigatewayv2_route" "get_receipt" {
  provider = aws.management

  api_id             = aws_apigatewayv2_api.management.id
  route_key          = "GET /v1/applications/{applicationId}/analysis-revisions/{revision}"
  target             = "integrations/${aws_apigatewayv2_integration.api.id}"
  authorization_type = "AWS_IAM"
}

resource "aws_cloudwatch_log_group" "api_gateway" {
  provider          = aws.management
  name              = "/aws/apigateway/${local.name}-management"
  retention_in_days = var.log_retention_days
}

resource "aws_apigatewayv2_stage" "default" {
  provider = aws.management

  api_id      = aws_apigatewayv2_api.management.id
  name        = "$default"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway.arn
    format = jsonencode({
      requestId        = "$context.requestId"
      routeKey         = "$context.routeKey"
      status           = "$context.status"
      responseLatency  = "$context.responseLatency"
      integrationError = "$context.integrationErrorMessage"
    })
  }
}

resource "aws_lambda_permission" "api_gateway" {
  provider = aws.management

  statement_id  = "AllowApiGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.receiver.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.management.execution_arn}/*/*"
}
