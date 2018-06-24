//Provider configuration
provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region     = "us-east-1"
}

//Create a VPC
resource "aws_vpc" "webVPC" {
  cidr_block = "10.0.0.0/16"
  tags {
    Name = "webVPC"
  }
}


//Creates an Internet Gateway
resource "aws_internet_gateway" "webIG" {
  vpc_id = "${aws_vpc.webVPC.id}"
  tags {
    Name = "webIG"
  }
}


//Creates Public subnet 1
resource "aws_subnet" "webPublicSubnet1" {
  vpc_id = "${aws_vpc.webVPC.id}"
  cidr_block = "10.0.0.0/24"
  availability_zone = "us-east-1a"
  tags {
    Name = "webPublicSubnet1"
  }
}

//Creates Public subnet 2
resource "aws_subnet" "webPublicSubnet2" {
  vpc_id = "${aws_vpc.webVPC.id}"
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1b"
  tags {
    Name = "webPublicSubnet2"
  }
}

//Route Table for subnet
resource "aws_route_table" "webRouteTable" {
  vpc_id = "${aws_vpc.webVPC.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.webIG.id}"
  }
}


//Attach route table to subnet 1
resource "aws_route_table_association" "webRTAssoc1" {
  subnet_id = "${aws_subnet.webPublicSubnet1.id}"
  route_table_id = "${aws_route_table.webRouteTable.id}"
}

//Attach route table to subnet 2
resource "aws_route_table_association" "webRTAssoc2" {
  subnet_id = "${aws_subnet.webPublicSubnet2.id}"
  route_table_id = "${aws_route_table.webRouteTable.id}"
}


//Create a security group
resource "aws_security_group" "web_public_sg" {
    name = "web_public_sg"
    description = "Web public access security group"
    vpc_id = "${aws_vpc.webVPC.id}"


   ingress {
      from_port = "0"
      to_port = "0"
      protocol = "-1"
      cidr_blocks = [
         "109.109.206.112/28", "217.5.240.176/29"]
   }

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

//Configuration details for the autoscaling group
resource "aws_autoscaling_group" "autoscaling-group" {
    name                        = "autoscaling-group"
    max_size                    = "${2}"
    min_size                    = "${1}"
    desired_capacity            = "${2}"
    vpc_zone_identifier         = ["${aws_subnet.webPublicSubnet1.id}", "${aws_subnet.webPublicSubnet2.id}"]
    depends_on                  = [ "aws_launch_configuration.launch-configuration" ]
    launch_configuration        = "${aws_launch_configuration.launch-configuration.name}"
    health_check_type           = "ELB"
}


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
    depends_on          = [ "aws_alb.load-balancer" ]

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


//Creates a Launch Configuration. Specified are the AMI ID, instance type, keypair name, instance profile, ebs details, security groups, user_data
resource "aws_launch_configuration" "launch-configuration" {
    name                        = "launch-configuration"
    image_id                    = "${var.ec2_ami}"
    instance_type               = "t2.micro"
    iam_instance_profile        = "${aws_iam_instance_profile.instance-profile.id}"
    key_name                    = "Test1"
    root_block_device {
      volume_type = "standard"
      volume_size = 10
      delete_on_termination = true
    }

    lifecycle {
      create_before_destroy = true
    }

    security_groups             = ["${aws_security_group.web_public_sg.id}"]
    associate_public_ip_address = "true"
    user_data                   = <<EOF
                                  #!/bin/bash
                                  echo ECS_CLUSTER="InfrastrucureAsCode" >> /etc/ecs/ecs.config
                                  EOF
}

//Name of the ECS cluster
resource "aws_ecs_cluster" "web-ecs-cluster" {
    name = "iac_demo"
}

//Creates a role for the ECS service to use. ECS uses this role to add containers to the load balancer
resource "aws_iam_role" "service-role" {
    name                = "service-role"
    path                = "/"
    assume_role_policy  = "${data.aws_iam_policy_document.service-policy.json}"
}

//Using the factory role AmazonEC2ContainerServiceRole
resource "aws_iam_role_policy_attachment" "service-role-attachment" {
    role       = "${aws_iam_role.service-role.name}"
    policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceRole"
}

//Generates a JSON file of the role
data "aws_iam_policy_document" "service-policy" {
    statement {
        actions = ["sts:AssumeRole"]

        principals {
            type        = "Service"
            identifiers = ["ecs.amazonaws.com"]
        }
    }
}

//Task Definition: Essentially specifying the task family, the container definition, container configuration
data "aws_ecs_task_definition" "nginx" {
  depends_on = [ "aws_ecs_task_definition.nginx" ]
  task_definition = "${aws_ecs_task_definition.nginx.family}"
}

resource "aws_ecs_task_definition" "nginx" {
    family                = "iac_demo"
    cpu                      = "256"
    memory                   = "512"
    container_definitions = "${file("container-definitions/service.json")}"
}


//Creates an IAM Role
resource "aws_iam_role" "instance-role" {
    name                = "instance-role"
    path                = "/"
    assume_role_policy  = "${data.aws_iam_policy_document.instance-policy.json}"
}

//Creates an IAM Policy
data "aws_iam_policy_document" "instance-policy" {
    statement {
        actions = ["sts:AssumeRole"]

        principals {
            type        = "Service"
            identifiers = ["ec2.amazonaws.com"]
        }
    }
}

//Attaches policy to the role
resource "aws_iam_role_policy_attachment" "instance-role-attachment" {
    role       = "${aws_iam_role.instance-role.name}"
    policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

//Creates an Instance profile. This is required for EC2 instances to assume a role
resource "aws_iam_instance_profile" "instance-profile" {
    name = "instance-profile"
    path = "/"
    role = "${aws_iam_role.instance-role.id}"
    provisioner "local-exec" {
      command = "sleep 10"
    }
}


//ECS Service details: Includes service name, Cluster ID, port and other configuration parameters
resource "aws_ecs_service" "web-ecs-service" {
        name            = "web-ecs-service"
        iam_role        = "${aws_iam_role.service-role.name}"
        cluster         = "${aws_ecs_cluster.web-ecs-cluster.id}"
        task_definition = "${aws_ecs_task_definition.nginx.family}:${max("${aws_ecs_task_definition.nginx.revision}", "${data.aws_ecs_task_definition.nginx.revision}")}"
        desired_count   = 2
        load_balancer {
        target_group_arn  = "${aws_alb_target_group.target-group.arn}"
        container_port    = 80
        container_name    = "nginx"
        }
}
