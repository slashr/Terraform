resource "aws_ecs_task_definition" "nginx" {
    family = "nginx" 
    container_definitions = "${file("service.json")}"
}

resource "aws_ecs_service" "web-ecs-service" {
  	name            = "web-ecs-service"
  	iam_role        = "${aws_iam_role.ecs-service-role.name}"
  	task_definition = "${aws_ecs_task_definition.nginx.family}:${max("${aws_ecs_task_definition.nginx.revision}", "${data.aws_ecs_task_definition.nginx.revision}")}"

  	load_balancer {
    	target_group_arn  = "${aws_alb_target_group.ecs-target-group.arn}"
    	container_port    = 80
    	container_name    = "webpage"
	}
}
