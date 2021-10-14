resource "aws_iam_role" "nats_data_ingest_monitor" {
  name = "${var.nats_monitor_name}-${var.namespace}-lambda"

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
    Name = "iam-${var.nats_monitor_name}-${var.naming_suffix}"
  }
}

resource "aws_iam_policy" "nats_data_ingest_monitor_policy" {
  name = "${var.nats_monitor_name}-${var.namespace}-lambda-policy"

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
        "arn:aws:s3:::${var.nats_input_bucket}-${var.namespace}",
        "arn:aws:s3:::${var.nats_input_bucket}-${var.namespace}/*"]
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

resource "aws_iam_role_policy_attachment" "nats_data_ingest_monitor_policy" {
  role       = aws_iam_role.nats_data_ingest_monitor.id
  policy_arn = aws_iam_policy.nats_data_ingest_monitor_policy.arn
}

data "archive_file" "nats_data_ingest_monitor_zip" {
  type        = "zip"
  source_dir  = "${local.path_module}/lambda/nats_monitor/code"
  output_path = "${local.path_module}/lambda/nats_monitor/package/lambda.zip"
}

resource "aws_lambda_function" "nats_data_ingest_monitor" {
  filename         = "${path.module}/lambda/nats_monitor/package/lambda.zip"
  function_name    = "${var.nats_monitor_name}-${var.namespace}-lambda"
  role             = aws_iam_role.nats_data_ingest_monitor.arn
  handler          = "function.lambda_handler"
  source_code_hash = data.archive_file.nats_data_ingest_monitor_zip.output_base64sha256
  runtime          = "python3.7"
  timeout          = "900"
  memory_size      = "2048"

  environment {
    variables = {
      bucket_name    = "${var.nats_input_bucket}-${var.namespace}"
      threashold_min = var.nats_monitor_lambda_run
      path_nats      = var.output_path_bitd
    }
  }

  tags = {
    Name = "lambda-${var.nats_monitor_name}-${var.naming_suffix}"
  }

  # lifecycle {
  #   ignore_changes = [
  #     filename,
  #     last_modified,
  #     source_code_hash,
  #   ]
  # }

}

resource "aws_cloudwatch_log_group" "nats_data_ingest_monitor" {
  name              = "/aws/lambda/${aws_lambda_function.nats_data_ingest_monitor.function_name}"
  retention_in_days = 90

  tags = {
    Name = "log-lambda-${var.nats_monitor_name}-${var.naming_suffix}"
  }
}

resource "aws_iam_policy" "nats_data_ingest_monitor_logging" {
  name        = "${var.nats_monitor_name}-${var.namespace}-lambda-logging"
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
        "${aws_cloudwatch_log_group.nats_data_ingest_monitor.arn}",
        "${aws_cloudwatch_log_group.nats_data_ingest_monitor.arn}/*"
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

resource "aws_iam_role_policy_attachment" "nats_data_ingest_monitor_logs" {
  role       = aws_iam_role.nats_data_ingest_monitor.name
  policy_arn = aws_iam_policy.nats_data_ingest_monitor_logging.arn
}

resource "aws_cloudwatch_event_rule" "nats_data_ingest_monitor" {
  name                = "${var.nats_monitor_name}-${var.namespace}-cw-event-rule"
  description         = "Fires every hour"
  schedule_expression = "rate(${var.nats_monitor_lambda_run_schedule} minutes)"
  is_enabled          = var.namespace == "prod" ? "true" : "true"
}

resource "aws_cloudwatch_event_target" "nats_data_ingest_monitor" {
  rule = aws_cloudwatch_event_rule.nats_data_ingest_monitor.name
  arn  = aws_lambda_function.nats_data_ingest_monitor.arn
}

resource "aws_lambda_permission" "nats_data_ingest_monitor_cw_permission" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.nats_data_ingest_monitor.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.nats_data_ingest_monitor.arn
}
