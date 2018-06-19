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
