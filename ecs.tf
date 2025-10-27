resource "aws_ecs_task_definition" "app_task" {
  family                   = "myapp-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"

  execution_role_arn       = data.aws_iam_role.ecs_execution.arn
  task_role_arn            = data.aws_iam_role.ecs_execution.arn

  container_definitions = jsonencode([{
    name      = "web-app"
    image     = "688412148742.dkr.ecr.us-east-1.amazonaws.com/web-app:latest"
    essential = true
    portMappings = [{
      containerPort = 5000
      hostPort      = 5000
    }]
  }])
}


