variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "aws_region" {default = "us-east-1"}
variable "ec2_ami" {default = "ami-43a15f3e"}

provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region     = "us-east-1"
}


resource "aws_instance" "webpage" {
  ami           = "${var.ec2_ami}"
  instance_type = "t2.micro"
}

resource "aws_eip" "ip" {
  instance = "${aws_instance.webpage.id}"
}


