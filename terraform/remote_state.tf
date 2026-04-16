data "terraform_remote_state" "platform" {
  backend = "s3"
  config = {
    bucket       = "tf-state-allankp"
    key          = "platform/production/terraform.tfstate"
    region       = "eu-west-1"
    use_lockfile = true
  }
}
