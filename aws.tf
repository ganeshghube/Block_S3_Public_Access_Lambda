terraform {
  #required_version = "~> 0.12.0"
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
