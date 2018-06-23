
output "address" {
  value = "${aws_alb.load-balancer.dns_name}"
}
