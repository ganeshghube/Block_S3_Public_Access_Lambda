terraform {
  #required_version = "~> 0.12.0"

#  backend "s3" {
#    acl     = "bucket-owner-full-control"
#    bucket  = "tf-state-cdcloudlogix"
#    encrypt = true
#    key     = "lambda_s3_public.tfstate"
#    region  = "eu-west-1"
#  }
}

provider "aws" {
  #alias  = "poweruser"
  region = "eu-west-1"
  access_key = "xxxxxxxxxxx"
  secret_key = "xxxxxxxxxxxxxxxxxxx"
}


provider "aws" {
  alias  = "security"
  region = "eu-west-1"
  access_key = "xxxxxxxxxxxxx"
  secret_key = "xxxxxxxxxxxxxxxxxxxxx"
}
