resource "aws_dynamodb_table" "evidence" {
  name           = "evidence"
  billing_mode   = "PROVISIONED"
  read_capacity  = 20
  write_capacity = 20
  hash_key       = "FileName"
  range_key      = "MD5Sum"

  attribute {
    name = "FileName"
    type = "S"
  }

  attribute {
    name = "MD5Sum"
    type = "S"
  }

  tags = {
    Name = "evidence"
  }
}

resource "aws_dynamodb_table_item" "eicar" {
  table_name = aws_dynamodb_table.evidence.name
  hash_key   = aws_dynamodb_table.evidence.hash_key
  range_key  = aws_dynamodb_table.evidence.range_key

  item = <<ITEM
{
  "FileName": {"S": "EICAR.txt"},
  "MD5Sum": {"S": "44d88612fea8a8f36de82e1278abb02f"},
  "SHA1Sum": {"S": "3395856ce81f2b7382dee72602f798b642f14140"}
}
ITEM
}

resource "random_string" "s3_suffix" {
  length  = 16
  special = false
  upper   = false
  numeric = true
  lower   = true
}

resource "aws_s3_bucket" "webcode" {
  bucket        = "webcode-${random_string.s3_suffix.result}"
  force_destroy = true
}

resource "aws_s3_bucket_website_configuration" "make_website" {
  bucket = aws_s3_bucket.webcode.bucket

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

resource "aws_s3_object" "index_file" {
  bucket = aws_s3_bucket.webcode.id
  key = "index.html"
  content = templatefile("${path.module}/webcode/index.html.tpl", 
  {
    function_url = "https://${aws_cloudfront_distribution.evidence-distribution.domain_name}/api/"
  })
  content_type = "text/html"
}

resource "aws_s3_object" "error_file" {
  bucket = aws_s3_bucket.webcode.id
  key = "error.html"
  content = "<h1>Error!</h1>"
  content_type = "text/html"
}

resource "aws_s3_object" "css_file" {
  bucket = aws_s3_bucket.webcode.id
  key = "styles.css"
  source = "${path.module}/webcode/styles.css"
  content_type = "text/css"
}

resource "aws_s3_object" "js_file" {
  bucket = aws_s3_bucket.webcode.id
  key = "script.js"
  content = templatefile("${path.module}/webcode/script.js.tpl", 
  {
    function_url = "https://${aws_cloudfront_distribution.evidence-distribution.domain_name}/api/"
  })
  content_type = "text/javascript"
}

resource "aws_s3_object" "favicon_file" {
  bucket = aws_s3_bucket.webcode.id
  key = "favicon.ico"
  source = "${path.module}/webcode/favicon.ico"
  content_type = "image/x-icon"
}

resource "aws_s3_object" "cloudace_file" {
  bucket = aws_s3_bucket.webcode.id
  key = "Cloud_Ace_Final.png"
  source = "${path.module}/webcode/Cloud_Ace_Final.png"
  content_type = "image/png"
}

resource "aws_s3_bucket" "aws-logs" {
  bucket        = "aws-logs-${random_string.s3_suffix.result}"
  force_destroy = true
}

resource "aws_s3_bucket" "evidence" {
  bucket        = "evidence-${random_string.s3_suffix.result}"
  force_destroy = true
}

resource "aws_s3_bucket" "cloudtrail_logs" {
  bucket        = "cloudtrail-${random_string.s3_suffix.result}"
  force_destroy = true
}

resource "aws_s3_bucket_policy" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
        {
            Sid = "AWSCloudTrailAclCheck"
            Effect = "Allow"
            Principal = {
              "Service": "cloudtrail.amazonaws.com"
            }
            Action = "s3:GetBucketAcl"
           Resource = aws_s3_bucket.cloudtrail_logs.arn
        },
        {
            Sid = "AWSCloudTrailWrite"
            Effect = "Allow"
            Principal = {
              "Service": "cloudtrail.amazonaws.com"
            }
            Action = "s3:PutObject"
            Resource = "${aws_s3_bucket.cloudtrail_logs.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*",
            Condition = {
                "StringEquals": {
                    "s3:x-amz-acl": "bucket-owner-full-control"
                }
            }
        }
    ]
})
}
