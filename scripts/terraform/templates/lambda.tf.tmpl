data "archive_file" "receiver" {
  type        = "zip"
  output_path = "${path.module}/receiver.zip"

  dynamic "source" {
    for_each = fileset("${path.module}/lambda", "*.mjs")
    content {
      filename = source.value
      content  = file("${path.module}/lambda/${source.value}")
    }
  }

  source {
    filename = "openapi.json"
    content  = jsonencode(yamldecode(file("${path.module}/../openapi/l3-management.openapi.yaml")))
  }
}

resource "aws_iam_role" "receiver" {
  provider = aws.management
  name     = "${local.name}-receiver"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "receiver" {
  provider = aws.management
  name     = "receive-results"
  role     = aws_iam_role.receiver.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:UpdateItem", "dynamodb:ConditionCheckItem"]
        Resource = aws_dynamodb_table.applications.arn
      },
      {
        Effect   = "Allow"
        Action   = ["sqs:ReceiveMessage", "sqs:DeleteMessage", "sqs:GetQueueAttributes"]
        Resource = aws_sqs_queue.intake.arn
      },
      {
        Effect   = "Allow"
        Action   = ["logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = "${aws_cloudwatch_log_group.receiver.arn}:*"
      }
    ]
  })
}

resource "aws_cloudwatch_log_group" "receiver" {
  provider          = aws.management
  name              = "/aws/lambda/${local.name}-receiver"
  retention_in_days = var.log_retention_days
}

resource "aws_lambda_function" "receiver" {
  provider = aws.management

  function_name    = "${local.name}-receiver"
  role             = aws_iam_role.receiver.arn
  runtime          = "nodejs22.x"
  handler          = "index.handler"
  filename         = data.archive_file.receiver.output_path
  source_code_hash = data.archive_file.receiver.output_base64sha256
  timeout          = 30
  memory_size      = 256

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.applications.name
    }
  }

  depends_on = [aws_iam_role_policy.receiver]
}

resource "aws_lambda_event_source_mapping" "intake" {
  provider                = aws.management
  event_source_arn        = aws_sqs_queue.intake.arn
  function_name           = aws_lambda_function.receiver.arn
  batch_size              = 10
  function_response_types = ["ReportBatchItemFailures"]
  depends_on              = [aws_iam_role_policy.receiver]
}
