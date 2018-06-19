resource "aws_iam_role" "instance-role" {
    name                = "instance-role"
    path                = "/"
    assume_role_policy  = "${data.aws_iam_policy_document.instance-policy.json}"
}

data "aws_iam_policy_document" "instance-policy" {
    statement {
        actions = ["sts:AssumeRole"]

        principals {
            type        = "Service"
            identifiers = ["ec2.amazonaws.com"]
        }
    }
}

resource "aws_iam_role_policy_attachment" "instance-role-attachment" {
    role       = "${aws_iam_role.instance-role.name}"
    policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "instance-profile" {
    name = "instance-profile"
    path = "/"
    role = "${aws_iam_role.instance-role.id}"
    provisioner "local-exec" {
      command = "sleep 10"
    }
}
