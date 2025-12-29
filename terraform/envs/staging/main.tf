# --- Shared Infrastructure (VPC + ALB) ---
data "aws_vpc" "existing_vpc" {
  filter {
    name   = "tag:Name"
    values = [var.vpc_name]
  }
}

provider "aws" {
  region = var.region
}

# --- Create new public subnets for staging ---
resource "aws_subnet" "public_a_staging" {
  vpc_id                  = data.aws_vpc.existing_vpc.id
  cidr_block              = "192.168.128.0/24" # Choose a non-overlapping range with prod subnets
  availability_zone       = "ap-south-1a"
  map_public_ip_on_launch = true

  tags = {
    Name        = "public-ap-south-1a-staging"
    Type        = "public"
    Environment = "staging"
  }
}

resource "aws_subnet" "public_b_staging" {
  vpc_id                  = data.aws_vpc.existing_vpc.id
  cidr_block              = "192.168.129.0/24" # Choose another non-overlapping range
  availability_zone       = "ap-south-1b"
  map_public_ip_on_launch = true

  tags = {
    Name        = "public-ap-south-1b-staging"
    Type        = "public"
    Environment = "staging"
  }
}

# --- Associate subnets with route table (so internet access works) ---
data "aws_route_table" "main" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.existing_vpc.id]
  }

  filter {
    name   = "association.main"
    values = ["true"]
  }
}

resource "aws_route_table_association" "a_staging_assoc" {
  subnet_id      = aws_subnet.public_a_staging.id
  route_table_id = data.aws_route_table.main.id
}

resource "aws_route_table_association" "b_staging_assoc" {
  subnet_id      = aws_subnet.public_b_staging.id
  route_table_id = data.aws_route_table.main.id
}

# --- ALB (Shared) ---
data "aws_lb" "existing_alb" {
  name = "shared-prod-alb"
}

data "aws_lb_listener" "https_listener" {
  load_balancer_arn = data.aws_lb.existing_alb.arn
  port              = 443
}

# --- S3 + CloudFront ---
module "s3" {
  source      = "../../modules/s3"
  bucket_name = var.bucket_name
  environment = var.environment
  backend_url = var.backend_url
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
  alb_dns_name                   = data.aws_lb.existing_alb.dns_name
  api_origin_request_policy_id   = var.api_origin_request_policy_id
  viewer_protocol_policy = var.viewer_protocol_policy
  logs_bucket_domain_name = var.logs_bucket_domain_name
}

# --- Allow CloudFront to access S3 ---
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

# --- Target Group + Listener Rule ---
resource "aws_lb_target_group" "backend_staging" {
  name        = "backend-staging-tg"
  port        = 5000
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.existing_vpc.id
  target_type = "ip"

  health_check {
    path = "/health"
    port = "5000"
  }

  tags = {
    Environment = "staging"
  }
}

resource "aws_lb_listener_rule" "staging_rule" {
  listener_arn = data.aws_lb_listener.https_listener.arn
  priority     = 20 # Lower than prod (10)

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend_staging.arn
  }

  condition {
    host_header {
      values = ["staging.615915.xyz"]
    }
  }
}

# --- ECS Service + Cluster ---
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
  public_subnet_ids       = [aws_subnet.public_a_staging.id, aws_subnet.public_b_staging.id]
  service_launch_type     = var.service_launch_type
  memory                  = var.memory
  log_group               = var.log_group
  container_cpu           = var.container_cpu
  ecs_security_group_ids  = [] # assuming using default ECS SG
  aws_lb_target_group_arn = aws_lb_target_group.backend_staging.arn
  mongodb_uri             = var.mongodb_uri
  email_id                = var.email_id
  email_password          = var.email_password
  jwt_secret              = var.jwt_secret
  desired_count = var.desired_count
}
