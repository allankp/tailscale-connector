locals {
  name = "tailscale-connector"
}

module "tags" {
  source = "git::https://github.com/allankp/tf-module-tags.git?ref=v0.0.1"

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
  source = "git::https://github.com/allankp/tf-module-tailscale-app-connector.git?ref=v0.0.1"

  name               = "${local.name}-${var.environment}"
  hostname           = var.hostname
  cluster_arn        = data.terraform_remote_state.platform.outputs.ecs_cluster_arn
  vpc_id             = data.terraform_remote_state.platform.outputs.vpc_id
  subnet_ids         = data.terraform_remote_state.platform.outputs.public_subnet_ids
  execution_role_arn = data.terraform_remote_state.platform.outputs.execution_role_arn
  auth_key_ssm_arn   = aws_ssm_parameter.tailscale_auth_key.arn
  tailscale_version  = var.tailscale_version
  tags               = module.tags.tags
}
