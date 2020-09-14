resource "aws_iam_role" "acl_data_ingest_monitor" {
  name = "${var.acl_monitor_name}-${var.namespace}-lambda"

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
    Name = "iam-${var.acl_monitor_name}-lambda-${local.naming_suffix}"
  }
}

resource "aws_iam_role_policy" "acl_data_ingest_monitor_policy" {
  name = "${var.acl_monitor_name}-${var.namespace}-lambda-policy"
  role = aws_iam_role.acl_data_ingest_monitor.id

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
        "arn:aws:s3:::${var.acl_input_bucket}-${var.namespace}",
        "arn:aws:s3:::${var.acl_input_bucket}-${var.namespace}/*"]
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

data "archive_file" "acl_data_ingest_monitor_zip" {
  type        = "zip"
  source_dir  = "${local.path_module}/lambda/monitor/code"
  output_path = "${local.path_module}/lambda/monitor/package/lambda.zip"
}

resource "aws_lambda_function" "acl_data_ingest_monitor" {
  filename         = "${path.module}/lambda/monitor/package/lambda.zip"
  function_name    = "${var.acl_monitor_name}-${var.namespace}-lambda"
  role             = aws_iam_role.acl_data_ingest_monitor.arn
  handler          = "function.lambda_handler"
  source_code_hash = data.archive_file.acl_data_ingest_monitor_zip.output_base64sha256
  runtime          = "python3.7"
  timeout          = "900"
  memory_size      = "2048"

  environment {
    variables = {
      bucket_name    = "${var.acl_input_bucket}-${var.namespace}"
      threashold_min = var.acl_monitor_lambda_run
    }
  }

  tags = {
    Name = "lambda-${var.acl_monitor_name}-${local.naming_suffix}"
  }

  # lifecycle {
  #   ignore_changes = [
  #     filename,
  #     last_modified,
  #     source_code_hash,
  #   ]
  # }

}

resource "aws_cloudwatch_log_group" "acl_data_ingest_monitor" {
  name              = "/aws/lambda/${aws_lambda_function.acl_data_ingest_monitor.function_name}"
  retention_in_days = 90

  tags = {
    Name = "log-lambda-${local.naming_suffix}"
  }
}

resource "aws_iam_policy" "acl_data_ingest_monitor_logging" {
  name        = "${var.acl_monitor_name}-${var.namespace}-lambda-logging"
  path        = "/"
  description = "IAM policy for monitor lambda"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": [
        "${aws_cloudwatch_log_group.acl_data_ingest_monitor.arn}",
        "${aws_cloudwatch_log_group.acl_data_ingest_monitor.arn}/*"
      ],
      "Effect": "Allow"
    },
    {
       "Action": "logs:CreateLogGroup",
       "Resource": "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*",
       "Effect": "Allow"
    }
  ]
}
EOF

}

resource "aws_iam_role_policy_attachment" "acl_data_ingest_monitor_logs" {
  role       = aws_iam_role.acl_data_ingest_monitor.name
  policy_arn = aws_iam_policy.acl_data_ingest_monitor_logging.arn
}

resource "aws_cloudwatch_event_rule" "acl_data_ingest_monitor" {
  name                = "${var.acl_monitor_name}-${var.namespace}-cw-event-rule"
  description         = "Fires every hour"
  schedule_expression = "rate(${var.acl_monitor_lambda_run_schedule} minutes)"
  is_enabled          = var.namespace == "prod" ? "false" : "true"
}

resource "aws_cloudwatch_event_target" "acl_data_ingest_monitor" {
  rule = aws_cloudwatch_event_rule.acl_data_ingest_monitor.name
  arn  = aws_lambda_function.acl_data_ingest_monitor.arn
}

resource "aws_lambda_permission" "acl_data_ingest_monitor_cw_permission" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.acl_data_ingest_monitor.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.acl_data_ingest_monitor.arn
}
