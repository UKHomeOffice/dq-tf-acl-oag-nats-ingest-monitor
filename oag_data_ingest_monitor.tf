resource "aws_iam_role" "oag_data_ingest_monitor" {
  name = "${var.oag_monitor_name}-${var.namespace}-lambda"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF


  tags = {
    Name = "iam-${var.oag_monitor_name}-${var.naming_suffix}"
  }
}

resource "aws_iam_policy" "oag_data_ingest_monitor_policy" {
  name = "${var.oag_monitor_name}-${var.namespace}-lambda-policy"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:PutObject",
        "s3:List*"
      ],
      "Effect": "Allow",
      "Resource": [
        "arn:aws:s3:::${var.oag_input_bucket}-${var.namespace}",
        "arn:aws:s3:::${var.oag_input_bucket}-${var.namespace}/*"]
    },
    {
      "Action": [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:GenerateDataKey*",
        "kms:DescribeKey"
      ],
      "Effect": "Allow",
      "Resource": "${var.kms_key_s3}"
    },
    {
      "Action": [
        "ssm:GetParameter",
        "ssm:GetParameters"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/slack_notification_webhook"
    }
  ]
}
EOF

}

resource "aws_iam_role_policy_attachment" "oag_data_ingest_monitor_policy" {
  role       = aws_iam_role.oag_data_ingest_monitor.id
  policy_arn = aws_iam_policy.oag_data_ingest_monitor_policy.arn
}

data "archive_file" "oag_data_ingest_monitor_zip" {
  type        = "zip"
  source_dir  = "${local.path_module}/lambda/oag_monitor/code"
  output_path = "${local.path_module}/lambda/oag_monitor/package/lambda.zip"
}

resource "aws_lambda_function" "oag_data_ingest_monitor" {
  filename         = "${path.module}/lambda/oag_monitor/package/lambda.zip"
  function_name    = "${var.oag_monitor_name}-${var.namespace}-lambda"
  role             = aws_iam_role.oag_data_ingest_monitor.arn
  handler          = "function.lambda_handler"
  source_code_hash = data.archive_file.oag_data_ingest_monitor_zip.output_base64sha256
  runtime          = "python3.11"
  timeout          = "900"
  memory_size      = "2048"

  environment {
    variables = {
      bucket_name    = "${var.oag_input_bucket}-${var.namespace}"
      threashold_min = var.oag_monitor_lambda_run
    }
  }

  tags = {
    Name = "lambda-${var.oag_monitor_name}-${var.naming_suffix}"
  }

  lifecycle {
    ignore_changes = [
      filename,
      last_modified,
      runtime,
      source_code_hash,
    ]
  }

}

resource "aws_cloudwatch_log_group" "oag_data_ingest_monitor" {
  name              = "/aws/lambda/${aws_lambda_function.oag_data_ingest_monitor.function_name}"
  retention_in_days = 90

  tags = {
    Name = "log-lambda-${var.oag_monitor_name}-${var.naming_suffix}"
  }
}

resource "aws_iam_policy" "oag_data_ingest_monitor_logging" {
  name        = "${var.oag_monitor_name}-${var.namespace}-lambda-logging"
  path        = "/"
  description = "IAM policy for monitor lambda"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "logs:CreateLogGroup",
      "Resource": "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "${aws_cloudwatch_log_group.oag_data_ingest_monitor.arn}:log-stream:*"
    }
  ]
}
EOF

}

resource "aws_iam_role_policy_attachment" "oag_data_ingest_monitor_logs" {
  role       = aws_iam_role.oag_data_ingest_monitor.name
  policy_arn = aws_iam_policy.oag_data_ingest_monitor_logging.arn
}

resource "aws_cloudwatch_event_rule" "oag_data_ingest_monitor" {
  name                = "${var.oag_monitor_name}-${var.namespace}-cw-event-rule"
  description         = "Fires every hour"
  schedule_expression = "rate(${var.oag_monitor_lambda_run_schedule} minutes)"
  is_enabled          = var.namespace == "prod" ? "true" : "true"
}

resource "aws_cloudwatch_event_target" "oag_data_ingest_monitor" {
  rule = aws_cloudwatch_event_rule.oag_data_ingest_monitor.name
  arn  = aws_lambda_function.oag_data_ingest_monitor.arn
}

resource "aws_lambda_permission" "oag_data_ingest_monitor_cw_permission" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.oag_data_ingest_monitor.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.oag_data_ingest_monitor.arn
}
