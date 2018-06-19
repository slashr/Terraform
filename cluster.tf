variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "aws_region" {default = "us-east-1"}


//Provider configuration
provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region     = "us-east-1"
}


//Name of the ECS cluster
resource "aws_ecs_cluster" "web-ecs-cluster" {
    name = "iac_demo"
}
