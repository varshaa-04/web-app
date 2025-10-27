# Fetch the IAM role dynamically
data "aws_iam_role" "ecs_execution" {
  name = "ecsTaskExecutionRole"
}

# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "myapp-cluster"
}

# ECS Task Definition
resource "aws_ecs_task_definition" "app_task" {
  family                   = "myapp-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = data.aws_iam_role.ecs_execution.arn

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

# ECS Service
resource "aws_ecs_service" "app_service" {
  name            = "myapp-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = ["subnet-0ec4b7b9c1a047f37"] # Replace with your actual subnet ID
    assign_public_ip = true
    security_groups  = ["sg-01be0a13917110067"]    # Replace with your actual security group ID
  }
}
