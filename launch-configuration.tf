variable ecs_key_pair_name {}
variable ec2_ami {}


resource "aws_launch_configuration" "launch-configuration" {
    name                        = "launch-configuration"
    image_id                    = "${var.ec2_ami}"
    instance_type               = "t2.micro"
    iam_instance_profile        = "${aws_iam_instance_profile.instance-profile.id}"
    key_name			= "Test1"
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
