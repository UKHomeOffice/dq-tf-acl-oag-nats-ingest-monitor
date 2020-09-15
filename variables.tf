locals {
  path_module = var.path_module != "unset" ? var.path_module : path.module
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

variable "acl_monitor_name" {
  default = "acl-data-ingest-monitor"
}

variable "acl_monitor_lambda_run" {
  default = "1680"
}

variable "acl_monitor_lambda_run_schedule" {
  default = "60"
}

variable "acl_input_bucket" {
  default = "s3-dq-acl-archive"
}

variable "oag_monitor_name" {
  default = "oag-data-ingest-monitor"
}

variable "oag_monitor_lambda_run" {
  default = "15"
}

variable "oag_monitor_lambda_run_schedule" {
  default = "15"
}

variable "oag_input_bucket" {
  default = "s3-dq-oag-archive"
}

variable "nats_monitor_name" {
  default = "nats-data-ingest-monitor"
}

variable "nats_monitor_lambda_run" {
  default = "15"
}

variable "nats_monitor_lambda_run_schedule" {
  default = "15"
}

variable "nats_input_bucket" {
  default = "s3-dq-nats-archive"
}

variable "output_path_bitd" {
  default = "nats/"
}

variable "kms_key_s3" {
  description = "The ARN of the KMS key that is used to encrypt S3 buckets"
  default     = "arn:aws:kms:eu-west-2:797728447925:key/ad7169c4-6d6a-4d21-84ee-a3b54f4bef87"
}
