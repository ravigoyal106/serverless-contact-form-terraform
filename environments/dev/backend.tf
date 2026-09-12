terraform {
  backend "s3" {
    bucket       = "serverless-contact-form-tfstate-ravigoyal106"
    key          = "environments/dev/terraform.tfstate"
    region       = "ap-south-1"
    use_lockfile = true
    encrypt      = true
  }
}