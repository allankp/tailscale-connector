locals {
  name       = "tailscale-connector"
  account_id = "127348474572"
}

module "tags" {
  source = "git::https://github.com/allankp/tf-module-tags.git?ref=v0.0.2"

  repo        = "tailscale-connector"
  environment = var.environment
}

resource "aws_ssm_parameter" "tailscale_auth_key" {
  name  = "/${local.name}/${var.environment}/TS_AUTHKEY"
  type  = "SecureString"
  value = var.tailscale_auth_key
  tags  = module.tags.tags

  lifecycle {
    ignore_changes = [value]
  }
}

module "connector" {
  source = "git::https://github.com/allankp/tf-module-tailscale-subnet-router.git?ref=v0.0.3"

  name              = "${local.name}-${var.environment}"
  vpc_id            = data.terraform_remote_state.platform.outputs.vpc_id
  subnet_id         = data.terraform_remote_state.platform.outputs.public_subnet_ids[0]
  auth_key_ssm_name = aws_ssm_parameter.tailscale_auth_key.name
  auth_key_ssm_arn  = aws_ssm_parameter.tailscale_auth_key.arn
  tags              = module.tags.tags
}

# ── EventBridge Scheduler: stop at 22:00, start at 06:00 Europe/London ────────

resource "aws_iam_role" "connector_scheduler" {
  name = "${local.name}-${var.environment}-scheduler"
  tags = module.tags.tags

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "scheduler.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "connector_scheduler" {
  name = "stop-start-ec2"
  role = aws_iam_role.connector_scheduler.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["ec2:StopInstances", "ec2:StartInstances"]
      Resource = "arn:aws:ec2:${var.aws_region}:${local.account_id}:instance/${module.connector.instance_id}"
    }]
  })
}

resource "aws_scheduler_schedule" "connector_stop" {
  name       = "${local.name}-${var.environment}-stop"
  group_name = "default"

  flexible_time_window { mode = "OFF" }

  schedule_expression          = "cron(0 22 * * ? *)"
  schedule_expression_timezone = "Europe/London"

  target {
    arn      = "arn:aws:scheduler:::aws-sdk:ec2:stopInstances"
    role_arn = aws_iam_role.connector_scheduler.arn
    input    = jsonencode({ InstanceIds = [module.connector.instance_id] })
  }
}

resource "aws_scheduler_schedule" "connector_start" {
  name       = "${local.name}-${var.environment}-start"
  group_name = "default"

  flexible_time_window { mode = "OFF" }

  schedule_expression          = "cron(0 6 * * ? *)"
  schedule_expression_timezone = "Europe/London"

  target {
    arn      = "arn:aws:scheduler:::aws-sdk:ec2:startInstances"
    role_arn = aws_iam_role.connector_scheduler.arn
    input    = jsonencode({ InstanceIds = [module.connector.instance_id] })
  }
}
