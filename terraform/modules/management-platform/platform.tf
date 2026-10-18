resource "aws_dynamodb_table" "applications" {
  provider = aws.management

  name         = "${local.name}-applications"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "pk"
  range_key    = "sk"

  attribute {
    name = "pk"
    type = "S"
  }

  attribute {
    name = "sk"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled = true
  }
}

resource "aws_sqs_queue" "intake_dlq" {
  provider = aws.management

  name                      = "${local.name}-intake-dlq"
  message_retention_seconds = 1209600
  sqs_managed_sse_enabled   = true
}

resource "aws_sqs_queue" "intake" {
  provider = aws.management

  name                       = "${local.name}-intake"
  visibility_timeout_seconds = 180
  message_retention_seconds  = 1209600
  sqs_managed_sse_enabled    = true

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.intake_dlq.arn
    maxReceiveCount     = 5
  })
}

resource "aws_cloudwatch_event_bus" "l3_results" {
  provider = aws.management
  name     = "${local.name}-l3-results"
}

resource "aws_cloudwatch_event_bus_policy" "allow_l3" {
  provider = aws.management

  event_bus_name = aws_cloudwatch_event_bus.l3_results.name
  policy         = data.aws_iam_policy_document.event_bus.json
}

data "aws_iam_policy_document" "event_bus" {
  provider = aws.management
  statement {
    sid       = "AllowL3AccountToPutEvents"
    actions   = ["events:PutEvents"]
    resources = [aws_cloudwatch_event_bus.l3_results.arn]

    principals {
      type        = "AWS"
      identifiers = [var.l3_account_id]
    }
  }
}

resource "aws_cloudwatch_event_rule" "analysis_snapshot" {
  provider = aws.management

  name           = "${local.name}-analysis-snapshot"
  event_bus_name = aws_cloudwatch_event_bus.l3_results.name
  event_pattern = jsonencode({
    source      = ["jp.co.nifty.point-award.l3"]
    detail-type = ["AnalysisSnapshot.v1"]
  })
}

resource "aws_cloudwatch_event_target" "intake" {
  provider = aws.management

  rule           = aws_cloudwatch_event_rule.analysis_snapshot.name
  event_bus_name = aws_cloudwatch_event_bus.l3_results.name
  arn            = aws_sqs_queue.intake.arn
  target_id      = "management-intake"

  dead_letter_config {
    arn = aws_sqs_queue.intake_dlq.arn
  }
}

resource "aws_sqs_queue_policy" "events" {
  provider = aws.management
  for_each = {
    intake = { url = aws_sqs_queue.intake.id, arn = aws_sqs_queue.intake.arn }
    dlq    = { url = aws_sqs_queue.intake_dlq.id, arn = aws_sqs_queue.intake_dlq.arn }
  }
  queue_url = each.value.url
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sqs:SendMessage"
      Resource  = each.value.arn
      Principal = { Service = "events.amazonaws.com" }
      Condition = { ArnEquals = { "aws:SourceArn" = aws_cloudwatch_event_rule.analysis_snapshot.arn } }
    }]
  })
}

resource "aws_cognito_user_pool" "staff" {
  provider = aws.management
  name     = "${local.name}-staff"

  mfa_configuration = "OPTIONAL"

  software_token_mfa_configuration {
    enabled = true
  }

  password_policy {
    minimum_length                   = 14
    require_lowercase                = true
    require_numbers                  = true
    require_symbols                  = true
    require_uppercase                = true
    temporary_password_validity_days = 1
  }
}

resource "aws_cognito_user_pool_client" "staff_web" {
  provider = aws.management

  name         = "${local.name}-staff-web"
  user_pool_id = aws_cognito_user_pool.staff.id

  generate_secret                      = false
  prevent_user_existence_errors        = "ENABLED"
  supported_identity_providers         = ["COGNITO"]
  allowed_oauth_flows_user_pool_client = false
}

resource "aws_s3_bucket" "admin_web" {
  provider = aws.management
  bucket   = "${local.name}-admin-${var.management_account_id}"
}

resource "aws_s3_bucket_public_access_block" "admin_web" {
  provider = aws.management
  bucket   = aws_s3_bucket.admin_web.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "admin_web" {
  provider = aws.management
  bucket   = aws_s3_bucket.admin_web.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_cloudfront_origin_access_control" "admin_web" {
  provider = aws.management

  name                              = "${local.name}-admin-web"
  description                       = "OAC for the private admin web bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "admin_web" {
  provider = aws.management

  enabled             = true
  default_root_object = "index.html"
  price_class         = "PriceClass_200"

  origin {
    domain_name              = aws_s3_bucket.admin_web.bucket_regional_domain_name
    origin_id                = "admin-web-s3"
    origin_access_control_id = aws_cloudfront_origin_access_control.admin_web.id
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "admin-web-s3"
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

data "aws_iam_policy_document" "admin_web" {
  provider = aws.management
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.admin_web.arn}/*"]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.admin_web.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "admin_web" {
  provider = aws.management
  bucket   = aws_s3_bucket.admin_web.id
  policy   = data.aws_iam_policy_document.admin_web.json
}
