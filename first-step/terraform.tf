
terraform {
  backend "s3" {
    bucket = "terraform-state-bucket-harunuts"
    key = "first-step"
    region = "ap-northeast-2"

  }
}


provider "aws" {
  region = "ap-northeast-2"
}

