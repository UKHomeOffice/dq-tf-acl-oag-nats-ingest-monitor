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
  default = "1440"
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

# variable "int_tab_monitor_name" {
#   default = "int-tab-monitor"
# }
#
# variable "int_tab_monitor_lambda_run" {
#   default = "900"
# }
#
# variable "int_tab_input_bucket" {
#   default = "s3-dq-data-archive-bucket"
# }
#
# variable "output_path_int_tab" {
#   default = "tableau-int/green/"
# }

