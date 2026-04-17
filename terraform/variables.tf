variable "environment" {
  type = string
}

variable "aws_region" {
  type    = string
  default = "eu-west-1"
}

variable "tailscale_auth_key" {
  description = "Tailscale OAuth client secret (TS_AUTHKEY). Set via CI secret, not tfvars."
  type        = string
  sensitive   = true
}
