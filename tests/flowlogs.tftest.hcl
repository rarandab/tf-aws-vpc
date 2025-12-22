mock_provider "aws" {
  override_data {
    target = data.aws_iam_policy_document.trust_flow_logs
    values = {
      json = "{}"
    }
  }
  override_data {
    target = data.aws_iam_policy_document.permissions_cw_flow_logs[0]
    values = {
      json = "{}"
    }
  }
  override_data {
    target = data.aws_iam_policy_document.permissions_kms_flog_logs[0]
    values = {
      json = "{}"
    }
  }
  override_resource {
    target = aws_iam_role.flow_logs[0]
    values = {
      arn = "arn:aws:logs::012345678901:role/test/test-irl-flowlogs"
      //arn:aws:iam::account:role/role-name-with-path
    }
  }
  override_resource {
    target = aws_cloudwatch_log_group.flow_logs[0]
    values = {
      arn = "arn:aws:logs:eu-west-1:012345678901:log-group:test"
    }
  }
}

variables {
  name_prefix           = "test"
  region                = "eu-west-1"
  availability_zone_ids = ["euw1-az1", "euw1-az2"]
  cidrs                 = ["10.0.0.0/20"]
  subnet_layers = {
    pri = {
      cidr_blocks = ["10.0.0.0/25", "10.0.0.128/25"]
    }
  }
  flow_logs = {}
}

run "default" {
  command = apply

  assert {
    condition     = aws_iam_role.flow_logs[0].name == "test-irl-flowlogs"
    error_message = "Flow logs IAM role name should be 'test-irl-flowlogs'"
  }

  assert {
    condition     = aws_cloudwatch_log_group.flow_logs[0].name == "/flowlogs/test-vpc"
    error_message = "Flow logs CloudWatch log group name should be '/flowlogs/test-vpc'"
  }

  assert {
    condition     = aws_flow_log.this[0].traffic_type == "ALL"
    error_message = "Flow log traffic type should be 'ALL'"
  }

  assert {
    condition     = aws_iam_role_policy.permissions_cw_flow_logs[0].role == aws_iam_role.flow_logs[0].id
    error_message = "Flow logs IAM role policy should be attached to the correct role"
  }
  assert {
    condition     = aws_flow_log.this[0].log_destination == aws_cloudwatch_log_group.flow_logs[0].arn
    error_message = "Flow log destination should match the CloudWatch log group ARN"
  }

  assert {
    condition     = aws_flow_log.this[0].iam_role_arn == aws_iam_role.flow_logs[0].arn
    error_message = "Flow log IAM role ARN should match the created IAM role"
  }

  assert {
    condition     = aws_flow_log.this[0].log_destination_type == "cloud-watch-logs"
    error_message = "Flow log destination type should be 'cloud-watch-logs'"
  }

  assert {
    condition     = aws_cloudwatch_log_group.flow_logs[0].retention_in_days != null
    error_message = "CloudWatch log group should have retention period configured"
  }

}

run "with_kms_key" {
  command = apply

  variables {
    flow_logs = {
      kms_key_arn = "arn:aws:kms:eu-west-1:012345678901:key/12345678-1234-1234-1234-123456789012"
    }
  }

  assert {
    condition     = aws_iam_role.flow_logs[0].name == "test-irl-flowlogs"
    error_message = "Flow logs IAM role name should be 'test-irl-flowlogs'"
  }

  assert {
    condition     = aws_cloudwatch_log_group.flow_logs[0].name == "/flowlogs/test-vpc"
    error_message = "Flow logs CloudWatch log group name should be '/flowlogs/test-vpc'"
  }

  assert {
    condition     = aws_flow_log.this[0].traffic_type == "ALL"
    error_message = "Flow log traffic type should be 'ALL'"
  }

  assert {
    condition     = aws_iam_role_policy.permissions_cw_flow_logs[0].role == aws_iam_role.flow_logs[0].id
    error_message = "Flow logs IAM role policy should be attached to the correct role"
  }

  assert {
    condition     = aws_flow_log.this[0].log_destination == aws_cloudwatch_log_group.flow_logs[0].arn
    error_message = "Flow log destination should match the CloudWatch log group ARN"
  }

  assert {
    condition     = aws_flow_log.this[0].iam_role_arn == aws_iam_role.flow_logs[0].arn
    error_message = "Flow log IAM role ARN should match the created IAM role"
  }

  assert {
    condition     = aws_flow_log.this[0].log_destination_type == "cloud-watch-logs"
    error_message = "Flow log destination type should be 'cloud-watch-logs'"
  }

  assert {
    condition     = aws_cloudwatch_log_group.flow_logs[0].retention_in_days != null
    error_message = "CloudWatch log group should have retention period configured"
  }

  assert {
    condition     = aws_cloudwatch_log_group.flow_logs[0].kms_key_id == "arn:aws:kms:eu-west-1:012345678901:key/12345678-1234-1234-1234-123456789012"
    error_message = "CloudWatch log group should use the provided KMS key"
  }

  assert {
    condition     = aws_iam_role_policy.permissions_kms_flog_logs[0].role == aws_iam_role.flow_logs[0].id
    error_message = "KMS permissions policy should be attached to the flow logs IAM role"
  }
}

run "with_existing_iam_role" {
  command = apply

  variables {
    flow_logs = {
      iam_role_arn = "arn:aws:iam::012345678901:role/existing-flow-logs-role"
    }
  }

  assert {
    condition     = length(aws_iam_role.flow_logs) == 0
    error_message = "No IAM role should be created when iam_role_arn is provided"
  }

  assert {
    condition     = aws_cloudwatch_log_group.flow_logs[0].name == "/flowlogs/test-vpc"
    error_message = "Flow logs CloudWatch log group name should be '/flowlogs/test-vpc'"
  }

  assert {
    condition     = aws_flow_log.this[0].traffic_type == "ALL"
    error_message = "Flow log traffic type should be 'ALL'"
  }

  assert {
    condition     = length(aws_iam_role_policy.permissions_cw_flow_logs) == 0
    error_message = "No IAM role policy should be created when iam_role_arn is provided"
  }

  assert {
    condition     = aws_flow_log.this[0].log_destination == aws_cloudwatch_log_group.flow_logs[0].arn
    error_message = "Flow log destination should match the CloudWatch log group ARN"
  }

  assert {
    condition     = aws_flow_log.this[0].iam_role_arn == "arn:aws:iam::012345678901:role/existing-flow-logs-role"
    error_message = "Flow log IAM role ARN should match the provided existing role ARN"
  }

  assert {
    condition     = aws_flow_log.this[0].log_destination_type == "cloud-watch-logs"
    error_message = "Flow log destination type should be 'cloud-watch-logs'"
  }

  assert {
    condition     = aws_cloudwatch_log_group.flow_logs[0].retention_in_days != null
    error_message = "CloudWatch log group should have retention period configured"
  }
}
