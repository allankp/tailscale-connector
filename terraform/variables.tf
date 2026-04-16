variable "environment" {
  type = string
}

variable "aws_region" {
  type    = string
  default = "eu-west-1"
}

variable "hostname" {
  description = "Hostname shown for the connector in the Tailscale admin console"
  type        = string
}

variable "tailscale_auth_key" {
  description = "Tailscale OAuth client secret (TS_AUTHKEY). Set via CI secret, not tfvars."
  type        = string
  sensitive   = true
}

variable "tailscale_version" {
  description = "Tailscale Docker image tag"
  type        = string
  default     = "stable"
}
