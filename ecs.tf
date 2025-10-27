resource "aws_ecs_cluster" "main" {
  name = "myapp-cluster"
}

resource "aws_ecs_task_definition" "app_task" {
  family                   = "myapp-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  

  container_definitions    = jsonencode([{
    name      = "myapp"
    image     = aws_ecr_repository.myapp_repo.repository_url
    essential = true
    portMappings = [{
      containerPort = 5000
      hostPort      = 5000
    }]
  }])
}

resource "aws_ecs_service" "app_service" {
  name            = "myapp-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  network_configuration {
    subnets         = ["subnet-0ec4b7b9c1a047f37"] # Replace with actual subnet IDs
    assign_public_ip = true
    security_groups  = ["sg-01be0a13917110067"]
  }
}
