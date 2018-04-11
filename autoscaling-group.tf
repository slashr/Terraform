resource "aws_autoscaling_group" "ecs-autoscaling-group" {
    name                        = "ecs-autoscaling-group"
    max_size                    = "${2}"
    min_size                    = "${1}"
    desired_capacity            = "${2}"
    vpc_zone_identifier         = ["${aws_subnet.webPublicSubnet1.id}", "${aws_subnet.webPublicSubnet2.id}"]
    launch_configuration        = "${aws_launch_configuration.ecs-launch-configuration.name}"
    health_check_type           = "ELB"
}
