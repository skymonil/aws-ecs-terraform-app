


# Prevent accidental deletion



module "vpc" {
  source              = "../../modules/network"
  vpc_name            = var.vpc_name
  environment         = var.environment
  availability_zones  = var.availability_zones
  public_subnet_cidrs = var.public_subnet_cidrs
  vpc_cidr_block      = var.vpc_cidr_block
  region              = var.region
}

module "s3" {
  source      = "../../modules/s3"
  bucket_name = var.bucket_name
  environment = var.environment

}

module "cdn" {
  source                         = "../../modules/cloudfront"
  s3_bucket_id                   = module.s3.bucket_id
  s3_bucket_arn                  = module.s3.bucket_arn
  environment                    = var.environment
  s3_bucket_regional_domain_name = module.s3.s3_bucket_regional_domain_name
  domain_alias                   = var.domain_alias
  acm_certificate_arn            = var.acm_certificate_arn
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
      values = ["api.615915.xyz"]
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
module "alb" {
  source                  = "../../modules/alb"
  vpc_id                  = module.vpc.vpc_id
  public_subnet_ids       = module.vpc.public_subnet_ids
  environment             = var.environment
  alb_acm_certificate_arn = var.alb_acm_certificate_arn

}

module "ecs" {
  source                  = "../../modules/ecs"
  environment             = var.environment
  ecs_service_name        = var.ecs_service_name
  aws_region              = var.region
  cluster_name            = var.cluster_name
  family_name             = var.family_name
  image                   = var.image
  container_memory        = var.container_memory
  container_port          = var.container_port
  cpu                     = var.cpu
  assign_public_ip        = var.assign_public_ip
  container_name          = var.container_name
  public_subnet_ids       = module.vpc.public_subnet_ids
  service_launch_type     = var.service_launch_type
  memory                  = var.memory
  log_group               = var.log_group
  container_cpu           = var.container_cpu
  ecs_security_group_ids  = [module.vpc.ecs_security_group_ids]
  aws_lb_target_group_arn = aws_lb_target_group.backend_prod.arn
  mongodb_uri             = "mongodb+srv://m98513313:Mongo123@e-commerce.qrafroh.mongodb.net/caamdb?retryWrites=true&w=majority&appName=E-Commerce"
  email_id                = "m98513313@gmail.com"
  email_password          = "dsizuudkjrnmybde"
  jwt_secret              = "JWT_SECRET"
}

