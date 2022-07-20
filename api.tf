locals {
  s3_origin_id    = "EVIDENCEORIGIN"
  apigw_origin_id = "EVIDENCEAPIORIGIN"
}

resource "aws_cloudfront_origin_access_identity" "evidence-oai" {
  comment = "EVIDENCE-OAI"
}

resource "aws_cloudfront_origin_access_identity" "evidence-api-oai" {
  comment = "EVIDENCE-OAI"
}

resource "aws_cloudfront_distribution" "evidence-distribution" {
  origin {
    domain_name         = aws_s3_bucket.webcode.bucket_domain_name
    origin_id           = local.s3_origin_id
    connection_attempts = 3
    connection_timeout  = 10

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.evidence-oai.cloudfront_access_identity_path
    }
  }

  origin {
    domain_name = replace(aws_apigatewayv2_api.evidence_gw.api_endpoint, "/^https?://([^/]*).*/", "$1")
    origin_id   = local.apigw_origin_id

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Evidence Website"
  default_root_object = "index.html"

  ordered_cache_behavior {
    path_pattern     = "/api/*"
    allowed_methods  = ["HEAD", "DELETE", "POST", "GET", "OPTIONS", "PUT", "PATCH"]
    cached_methods   = ["GET", "OPTIONS", "HEAD"]
    compress         = false
    target_origin_id = local.apigw_origin_id
    forwarded_values {
      query_string = true
      cookies {
        forward = "all"
      }
    }
    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 0
    max_ttl                = 0
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    compress         = false
    target_origin_id = local.s3_origin_id
    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 60
    max_ttl                = 120
  }

  price_class = "PriceClass_All"
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  logging_config {
    bucket = aws_s3_bucket.aws-logs.bucket_domain_name
    prefix = "CloudFront/"
  }

  depends_on = [aws_s3_bucket_policy.aws-logs_policy]
}

resource "aws_apigatewayv2_api" "evidence_gw" {
  name          = "evidence_api"
  protocol_type = "HTTP"
  cors_configuration {
    allow_origins = ["*"]
  }
}

resource "aws_apigatewayv2_stage" "lambda" {
  api_id = aws_apigatewayv2_api.evidence_gw.id

  name        = "api"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gw.arn

    format = jsonencode({
      requestId               = "$context.requestId"
      sourceIp                = "$context.identity.sourceIp"
      requestTime             = "$context.requestTime"
      protocol                = "$context.protocol"
      httpMethod              = "$context.httpMethod"
      resourcePath            = "$context.resourcePath"
      routeKey                = "$context.routeKey"
      status                  = "$context.status"
      responseLength          = "$context.responseLength"
      integrationErrorMessage = "$context.integrationErrorMessage"
      }
    )
  }
}

resource "aws_apigatewayv2_integration" "evidence_integration" {
  api_id             = aws_apigatewayv2_api.evidence_gw.id
  integration_uri    = aws_lambda_function.evidence.invoke_arn
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
}

resource "aws_apigatewayv2_route" "evidence_rt" {
  api_id    = aws_apigatewayv2_api.evidence_gw.id
  route_key = "ANY /"
  target    = "integrations/${aws_apigatewayv2_integration.evidence_integration.id}"
}

resource "aws_cloudwatch_log_group" "api_gw" {
  name              = "/aws/api_gw/${aws_apigatewayv2_api.evidence_gw.name}"
  retention_in_days = 1
}

resource "aws_cloudwatch_log_group" "cloudtrail" {
  name              = "cloudtrail-${random_string.s3_suffix.result}"
  retention_in_days = 1
}

resource "time_sleep" "wait_15_seconds_api" {
  depends_on      = [aws_iam_role_policy_attachment.cloudtrail]
  create_duration = "15s"
}

resource "aws_cloudtrail" "trail" {
  name                       = "cloudtrail-${random_string.s3_suffix.result}"
  s3_bucket_name             = aws_s3_bucket.aws-logs.id
  is_multi_region_trail      = true
  cloud_watch_logs_group_arn = "${aws_cloudwatch_log_group.cloudtrail.arn}:*"
  cloud_watch_logs_role_arn  = aws_iam_role.cloudtrail_cloudwatch.arn
  event_selector {
    read_write_type           = "All"
    include_management_events = true

    data_resource {
      type   = "AWS::S3::Object"
      values = ["${aws_s3_bucket.webcode.arn}/"]
    }
  }
  event_selector {
    read_write_type           = "All"
    include_management_events = true

    data_resource {
      type   = "AWS::S3::Object"
      values = ["${aws_s3_bucket.evidence.arn}/"]
    }
  }
  depends_on = [time_sleep.wait_15_seconds_api]
}
