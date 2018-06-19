//Creates a application load balancer
resource "aws_alb" "load-balancer" {
    name                = "load-balancer"    
    security_groups     = ["${aws_security_group.loadbalancer-sg.id}"]
    subnets             = ["${aws_subnet.webPublicSubnet1.id}", "${aws_subnet.webPublicSubnet2.id}"]

    tags {
      Name = "load-balancer"
    }
}

//Creates a target group for the ALB
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

//Opens ports on the ALB
resource "aws_alb_listener" "alb-listener" {
    load_balancer_arn = "${aws_alb.load-balancer.arn}"
    port              = "80"
    protocol          = "HTTP"

    default_action {
        target_group_arn = "${aws_alb_target_group.target-group.arn}"
        type             = "forward"
    }
}

//Creates a security group for the ALB
resource "aws_security_group" "loadbalancer-sg" {
    name = "loadbalancer-sg"
    description = "Load Balancer security group"
    vpc_id = "${aws_vpc.webVPC.id}"


   ingress {
      from_port = "80"
      to_port = "80"
      protocol = "tcp"
      cidr_blocks = [
         "0.0.0.0/0"]
   }

    egress {
        # allow all traffic to private SN
        from_port = "0"
        to_port = "0"
        protocol = "-1"
        cidr_blocks = [
            "0.0.0.0/0"]
    }
}
