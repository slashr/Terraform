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
