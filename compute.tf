data "archive_file" "evidence_lambda_zip" {
  type = "zip"
  source {
    content = templatefile("${path.module}/evidence.py.tpl",
      {
        bucket = aws_s3_bucket.evidence.id
    })
    filename = "evidence.py"
  }
  output_path = "${path.module}/evidence.zip"
}

resource "time_sleep" "wait_15_seconds_compute" {
  depends_on      = [data.archive_file.evidence_lambda_zip]
  create_duration = "15s"
}

resource "aws_lambda_function" "evidence" {
  filename      = "${path.module}/evidence.zip"
  function_name = "evidence"
  role          = aws_iam_role.evidence_lambda.arn
  handler       = "evidence.lambda_handler"
  runtime       = "python3.8"
  publish       = true
  depends_on    = [time_sleep.wait_15_seconds_compute]
}

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${aws_lambda_function.evidence.function_name}"
  retention_in_days = 1
}
