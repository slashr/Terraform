
output "address" {
  value = "${aws_alb.load-balancer.dns_name}"
}

output "ami-id" {
  value = "${var.ec2_ami}"
}
