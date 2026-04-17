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
  source = "git::https://github.com/allankp/tf-module-tailscale-subnet-router.git?ref=v0.0.1"

  name              = "${local.name}-${var.environment}"
  vpc_id            = data.terraform_remote_state.platform.outputs.vpc_id
  subnet_id         = data.terraform_remote_state.platform.outputs.public_subnet_ids[0]
  auth_key_ssm_name = aws_ssm_parameter.tailscale_auth_key.name
  auth_key_ssm_arn  = aws_ssm_parameter.tailscale_auth_key.arn
  tags              = module.tags.tags
}
