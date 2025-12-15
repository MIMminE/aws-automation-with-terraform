# provider "aws" {
#   region     = "ap-northeast-2"
# }
#
# resource "aws_instance" "example" {
#   ami           = "ami-0b818a04bc9c2133c"
#   instance_type = "t3.micro"
# }

provider "aws" {
  region = "ap-northeast-2"
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"]
}

resource "aws_instance" "example" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type

  subnet_id = module.vpc.public_subnets[0]

  tags = {
    Name = "example-instance"
  }
}
