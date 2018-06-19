resource "aws_alb" "load-balancer" {
    name                = "load-balancer"    
    security_groups     = ["${aws_security_group.web_lb_sg.id}"]
    subnets             = ["${aws_subnet.webPublicSubnet1.id}", "${aws_subnet.webPublicSubnet2.id}"]

    tags {
      Name = "load-balancer"
    }
}

resource "aws_alb_target_group" "target-group" {
    name                = "target-group"
    port                = "80"
    protocol            = "HTTP"
    vpc_id              = "${aws_vpc.webVPC.id}"
    depends_on = [ "aws_alb.load-balancer" ]

    health_check {
        healthy_threshold   = "5"
        unhealthy_threshold = "2"
        interval            = "30"
        matcher             = "200"
        path                = "/"
        port                = "traffic-port"
        protocol            = "HTTP"
        timeout             = "5"
    }

    tags {
      Name = "target-group"
    }
}

resource "aws_alb_listener" "alb-listener" {
    load_balancer_arn = "${aws_alb.load-balancer.arn}"
    port              = "80"
    protocol          = "HTTP"

    default_action {
        target_group_arn = "${aws_alb_target_group.target-group.arn}"
        type             = "forward"
    }
}
