


# Prevent accidental deletion


module "vpc" {
  source              = "../../modules/network"
  vpc_name            = var.vpc_name
  environment         = var.environment
  vpc_cidr_block      = var.vpc_cidr_block
  region              = var.region
  public_subnets      = var.public_subnets
}

module "s3" {
  source      = "../../modules/s3"
  bucket_name = var.bucket_name
  environment = var.environment
  backend_url = var.backend_url
}

module "cloudfront_logs" {
  source = "../../modules/s3-logs"
  providers = {
    aws = aws.us_east_1
  }
  bucket_name = "prod-caam-cloudfront-logs-us-east-1"
  environment = "prod"
}

module "cdn" {
  source                         = "../../modules/cloudfront"
  s3_bucket_id                   = module.s3.bucket_id
  s3_bucket_arn                  = module.s3.bucket_arn
  environment                    = var.environment
  s3_bucket_regional_domain_name = module.s3.s3_bucket_regional_domain_name
  domain_alias                   = var.domain_alias
  acm_certificate_arn            = var.acm_certificate_arn
  cache_policy_id                = var.cache_policy_id
  origin_request_policy_id       = var.origin_request_policy_id
  api_cache_policy_id            = var.api_cache_policy_id
  alb_dns_name                   = module.alb.alb_dns_name
  api_origin_request_policy_id   = var.api_origin_request_policy_id
  logs_bucket_domain_name = module.cloudfront_logs.bucket_domain_name
  viewer_protocol_policy = var.viewer_protocol_policy
}

resource "aws_s3_bucket_policy" "cf_access" {
  bucket = module.s3.bucket_id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontServicePrincipalReadOnly"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = ["s3:GetObject"]
        Resource = "${module.s3.bucket_arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = module.cdn.cloudfront_distribution_arn
          }
        }
      }
    ]
  })
}


resource "aws_lb_listener_rule" "prod_rule" {
  listener_arn = module.alb.alb_listener_arn
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend_prod.arn
  }

  condition {
    host_header {
      values = ["615915.xyz"]
    }
  }
}

resource "aws_lb_target_group" "backend_prod" {
  name        = "backend-${var.environment}-tg"
  port        = 5000
  protocol    = "HTTP"
  vpc_id      = module.vpc.vpc_id
  target_type = "ip"
  health_check {
    path = "/health"
    port = "5000"
  }

  tags = {
    Environment = "prod"
  }
}

module "security_groups" {
  source      = "../../modules/security-groups"
  vpc_id      = module.vpc.vpc_id
  environment = var.environment
  container_port = var.container_port
  cloudfront_prefix_list_id = var.cloudfront_prefix_list_id
}

module "alb" {
  source                  = "../../modules/alb"
  vpc_id                  = module.vpc.vpc_id
  public_subnet_ids       = module.vpc.public_subnet_ids
  environment             = var.environment
  alb_acm_certificate_arn = var.alb_acm_certificate_arn
  cloudfront_prefix_list_id = var.cloudfront_prefix_list_id
  alb_security_group_id = module.security_groups.alb_security_group_id
}




module "ecs" {
  source           = "../../modules/ecs"
  environment      = var.environment
  cluster_name     = var.cluster_name
  aws_region       = var.region
  ecs_service_name = var.ecs_service_name
  
  # Container configuration
  container = {
    name   = var.container_name
    image  = var.image
    port   = var.container_port
    cpu    = var.container_cpu
    memory = var.container_memory
  }
  
  # Task definition
  task = {
    family          = var.family_name
    cpu             = var.cpu
    memory          = var.memory
    compatibilities = ["FARGATE"] # Or var.service_launch_type == "FARGATE" ? ["FARGATE"] : ["EC2"]
    network_mode    = "awsvpc"
  }
  
  # Networking
  networking = {
    subnet_ids         = module.vpc.public_subnet_ids
    security_group_ids = [module.security_groups.ecs_security_group_id]
    assign_public_ip   = var.assign_public_ip
  }
  
  # Load balancer
  load_balancer = {
    target_group_arn = aws_lb_target_group.backend_prod.arn
  }
  
  # Autoscaling
  autoscaling = {
    enabled       = var.enable_autoscaling
    min           = var.min_count
    max           = var.max_count
    cpu_target    = var.cpu_target_value
    memory_target = var.memory_target_value
  }
  
  # Logging
  log_group = var.log_group
  
  # Secrets
  secrets = {
    mongodb_uri    = var.mongodb_uri
    email_id       = var.email_id
    email_password = var.email_password
    jwt_secret     = var.jwt_secret
  }
}

