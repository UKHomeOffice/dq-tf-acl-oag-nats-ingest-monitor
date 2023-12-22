# pylint: disable=missing-docstring, line-too-long, protected-access, E1101, C0202, E0602, W0109
import unittest
import hashlib
from runner import Runner


class TestE2E(unittest.TestCase):
    @classmethod
    def setUpClass(self):
        self.snippet = """


            provider "aws" {
              region = "eu-west-2"
              skip_credentials_validation = true
            }

            module "acl_oag_nats_data_ingest_monitor" {
              source = "./mymodule"

              providers = {
                aws = aws
              }

            path_module = "./"
            naming_suffix                   = "apps-preprod-dq"
            namespace                       = "preprod"
            }
        """
        self.runner = Runner(self.snippet)
        self.result = self.runner.result

    def test_name_suffix_acl_data_ingest_lambda_monitor(self):
        self.assertEqual(self.runner.get_value("module.acl_oag_nats_data_ingest_monitor.aws_lambda_function.acl_data_ingest_monitor", "tags"), {"Name": "lambda-acl-data-ingest-monitor-apps-preprod-dq"})

    def test_name_suffix_oag_data_ingest_lambda_monitor(self):
        self.assertEqual(self.runner.get_value("module.acl_oag_nats_data_ingest_monitor.aws_lambda_function.oag_data_ingest_monitor", "tags"), {"Name": "lambda-oag-data-ingest-monitor-apps-preprod-dq"})

    def test_name_suffix_nats_data_ingest_lambda_monitor(self):
        self.assertEqual(self.runner.get_value("module.acl_oag_nats_data_ingest_monitor.aws_lambda_function.nats_data_ingest_monitor", "tags"), {"Name": "lambda-nats-data-ingest-monitor-apps-preprod-dq"})
