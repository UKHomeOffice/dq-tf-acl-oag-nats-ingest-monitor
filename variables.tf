locals {
  naming_suffix = "${var.pipeline_name}-${var.naming_suffix}"
  path_module   = var.path_module != "unset" ? var.path_module : path.module
}

variable "path_module" {
  default = "unset"
}

variable "naming_suffix" {
  default = "apps-test-dq"
}


variable "namespace" {
  default = "test"
}

variable "monitor_name" {
  default = "acl-data-ingest-monitor"
}

variable "monitor_lambda_run" {
  default = "1680"
}

variable "monitor_lambda_run_schedule" {
  default = "60"
}

variable "input_bucket" {
  default = "s3-dq-acl-archive"
}

variable "kms_key_s3" {
  description = "The ARN of the KMS key that is used to encrypt S3 buckets"
  default     = "arn:aws:kms:eu-west-2:797728447925:key/ad7169c4-6d6a-4d21-84ee-a3b54f4bef87"
}
