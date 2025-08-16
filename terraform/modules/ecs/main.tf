

resource "aws_ecs_cluster" "ecs_cluster" {
  name = var.cluster_name
  # The setting block within the aws_ecs_cluster resource in Terraform is used to configure specific cluster-wide settings for an Amazon ECS (Elastic Container Service) cluster.
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
  tags = {
    Environment = var.environment
  }
}

# Create the IAM role that the ECS task will assume
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

# Attach the standard AWS managed policy for ECS task execution
resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy_attach" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Define a custom policy for additional permissions
resource "aws_iam_role_policy" "custom_ecs_policy" {
  name = "custom-ecs-policy"
  role = aws_iam_role.ecs_task_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "ECRReadAccess",
        Effect = "Allow",
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability"
        ],
        Resource = "*"
      },
      {
        Sid    = "CloudWatchWriteAccess",
        Effect = "Allow",
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "*" # Best practice is to limit this to a specific log group ARN
      }
    ]
  })
}

resource "aws_cloudwatch_log_group" "ecs_app_logs" {
  name              = var.log_group
  retention_in_days = 7

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}


resource "aws_ecs_task_definition" "aw_ecs_task" {
  family                   = var.family_name
  requires_compatibilities = var.compatibilities
  network_mode             = var.network_mode
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = var.container_name
      image     = var.image
      cpu       = var.container_cpu    # per-container CPU (relative for EC2, hard limit for Fargate)
      memory    = var.container_memory # per-container Memory
      essential = true
      portMappings = [
        {
          containerPort = var.container_port
          hostPort      = var.container_port
          protocol      = "tcp"
        }
        
      ]
       environment = [
        # Use a for loop to dynamically create key-value pairs from a variable
        for key, value in var.env_variables : {
          name  = key
          value = value
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
         awslogs-group = aws_cloudwatch_log_group.ecs_app_logs.name

          awslogs-region        = var.aws_region
          awslogs-stream-prefix = var.container_name
        }
      }
    }
  ])
}


resource "aws_ecs_service" "example" {
  name            = var.ecs_service_name
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.aw_ecs_task.id
  launch_type     = var.service_launch_type
  desired_count   = 1 # We want 1 instance of the task running

  network_configuration {
    subnets          = var.public_subnet_ids
    security_groups  = var.ecs_security_group_ids
    assign_public_ip = var.assign_public_ip
  }

  depends_on = [
    aws_iam_role_policy_attachment.ecs_task_execution_policy_attach
  ]

    load_balancer {
    target_group_arn = var.aws_lb_target_group_arn
    container_name   = var.container_name # must match Task Definition container name
    container_port   = 5000
  }

}