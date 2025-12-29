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
resource "aws_iam_role" "ecs_task_role" {
  name = "ecs-task-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })
}




# Create the IAM role that the ECS task will assume
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecs-task-execution-role-${var.environment}"

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
      },
      {
        Sid    = "SSMReadAccess",
        Effect = "Allow",
        Action = "ssm:GetParameters",
        Resource = "*"
      }
    ]
  })
}

resource "aws_ssm_parameter" "mongodb_uri" {
  name  = "/${var.environment}/caam/mongodb_uri"
  type  = "SecureString"
  value = var.secrets.mongodb_uri
}

resource "aws_ssm_parameter" "email_id" {
  name  = "/${var.environment}/caam/email_id"
  type  = "SecureString"
  value = var.secrets.email_id
}

resource "aws_ssm_parameter" "email_password" {
  name  = "/${var.environment}/caam/email_password"
  type  = "SecureString"
  value = var.secrets.email_password
}

resource "aws_ssm_parameter" "jwt_secret" {
  name  = "/${var.environment}/caam/jwt_secret"
  type  = "SecureString"
  value = var.secrets.jwt_secret
}


resource "aws_cloudwatch_log_group" "ecs_app_logs" {
  name              = var.log_group
  retention_in_days = 7

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}


resource "aws_ecs_task_definition" "this" {
  family                   = var.task.family
  requires_compatibilities = var.task.compatibilities
  network_mode             = var.task.network_mode
  cpu                      = var.task.cpu
  memory                   = var.task.memory

  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn      = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name  = var.container.name
      image = var.container.image
      cpu   = var.container.cpu
      memory = var.container.memory
      essential = true

      portMappings = [{
        containerPort = var.container.port
        protocol      = "tcp"
      }]

      secrets = [
        { name = "MONGODB_URI", valueFrom = aws_ssm_parameter.mongodb_uri.arn },
        { name = "EMAIL_ID", valueFrom = aws_ssm_parameter.email_id.arn },
        { name = "EMAIL_PASSWORD", valueFrom = aws_ssm_parameter.email_password.arn },
        { name = "JWT_SECRET", valueFrom = aws_ssm_parameter.jwt_secret.arn }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.ecs_app_logs.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = var.container.name
        }
      }
    }
  ])
}


resource "aws_appautoscaling_target" "ecs" {
  count = var.autoscaling.enabled ? 1 : 0

  max_capacity       = var.autoscaling.max
  min_capacity       = var.autoscaling.min
  resource_id        = "service/${aws_ecs_cluster.ecs_cluster.name}/${aws_ecs_service.this.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "cpu" {
  count = var.autoscaling.enabled ? 1 : 0

  name               = "${var.ecs_service_name}-cpu-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs[0].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs[0].service_namespace

  target_tracking_scaling_policy_configuration {
    target_value = var.autoscaling.cpu_target

    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
  }
}

resource "aws_appautoscaling_policy" "memory" {
  count = var.autoscaling.enabled ? 1 : 0

  name               = "${var.ecs_service_name}-memory-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs[0].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs[0].service_namespace

  target_tracking_scaling_policy_configuration {
    target_value = var.autoscaling.memory_target

    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
  }
}


resource "aws_ecs_service" "this" {
  name            = var.ecs_service_name
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.this.id
  desired_count   = var.autoscaling.min
  launch_type     = "FARGATE"
  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200

  network_configuration {
    subnets          = var.networking.subnet_ids
    security_groups  = var.networking.security_group_ids
    assign_public_ip = var.networking.assign_public_ip
  }

  load_balancer {
    target_group_arn = var.load_balancer.target_group_arn
    container_name   = var.container.name
    container_port   = var.container.port
  }

  depends_on = [
    aws_iam_role_policy_attachment.ecs_task_execution_policy_attach
  ]
}