variable "region" {
  type    = string
  default = ""
}

variable "environment" {
  type    = string
  default = "prod"
}

variable "backend_url" {
  type        = string
  description = "URL of the backend which would vary per environment"
}

variable "vpc_name" {
  description = "Name for the VPC"
  type        = string
  validation {
    condition     = length(var.vpc_name) > 0
    error_message = "VPC Name cannot be empty"
  }
}

variable "vpc_cidr_block" {
  description = "The CIDR block for the VPC"
  type        = string
}

variable "public_subnets" {
  description = "Map of public subnets with CIDR and AZ"
  type = map(object({
    cidr = string
    az   = string
  }))
  
  default = {
    "public-ap-south-1a" = {
      cidr = "10.0.1.0/24"
      az   = "ap-south-1a"
    }
    "public-ap-south-1b" = {
      cidr = "10.0.2.0/24"
      az   = "ap-south-1b"
    }
  }
}

variable "bucket_name" {
  description = "name of the s3 bucket"
  type        = string
}

variable "acm_certificate_arn" {
  description = "ARN of the ACM certificate (must cover both domains and be in us-east-1)"
  type        = string
}

variable "alb_acm_certificate_arn" {
  description = "ARN of the ACM certificate (must cover both domains and be in us-east-1)"
  type        = string
}

variable "domain_alias" {
  description = "CloudFront alias domain (e.g., '615915.xyz' or 'staging.615915.xyz')"
  type        = string
}

variable "ecs_service_name" {
  description = "Name for the ECS service"
  type        = string
}

variable "cluster_name" {
  description = "Name for the ECS cluster"
  type        = string
}

variable "desired_count" {
  type    = number
  default = 1
}

variable "family_name" {
  description = "Name for the ECS task family"
  type        = string
}

variable "image" {
  description = "url of the docker image"
  type        = string
}

# Container-specific variables
variable "container_memory" {
  description = "The memory (in MiB) for the container."
  type        = number
}

variable "container_port" {
  description = "The port for the container."
  type        = number
}

variable "container_cpu" {
  description = "The CPU units for the container within the ECS task."
  type        = number
}

variable "container_name" {
  description = "The name for the ECS container."
  type        = string
}

# Task-specific variables
variable "cpu" {
  description = "The CPU units for the ECS task."
  type        = number
}

variable "memory" {
  description = "The memory (in MiB) for the ECS task."
  type        = number
}

# Networking
variable "assign_public_ip" {
  description = "Whether to assign a public IP to the ECS task."
  type        = bool
  default     = true
}

# Launch type (you can remove this if always using FARGATE)
variable "service_launch_type" {
  description = "The launch type for the ECS service (e.g., FARGATE or EC2)."
  type        = string
  default     = "FARGATE"
}

variable "log_group" {
  description = "The CloudWatch log group for the ECS task."
  type        = string
}

# Secrets
variable "mongodb_uri" {
  description = "Value of the DB URI"
  type        = string
  sensitive   = true
}

variable "email_id" {
  description = "Email ID for sending emails"
  type        = string
  sensitive   = true
}

variable "email_password" {
  description = "Email password for sending emails"
  type        = string
  sensitive   = true
}

variable "jwt_secret" {
  description = "JWT secret for authentication"
  type        = string
  sensitive   = true
}

# CloudFront/CDN variables
variable "cache_policy_id" {
  description = "Value of the cache_policy_id for the cdn"
  type        = string
}

variable "origin_request_policy_id" {
  description = "Value of the origin_request_policy_id for the cdn"
  type        = string
}

variable "api_cache_policy_id" {
  description = "api_cache_policy_id"
  type        = string
}

variable "api_origin_request_policy_id" {
  description = "api_origin_request_policy_id"
  type        = string
}

# Autoscaling variables
variable "min_count" {
  description = "Minimum number of ECS tasks"
  type        = number
  default     = 1
}

variable "max_count" {
  description = "Maximum number of ECS tasks"
  type        = number
  default     = 3
}

variable "enable_autoscaling" {
  description = "Enable ECS service autoscaling"
  type        = bool
  default     = false
}

variable "cpu_target_value" {
  description = "Target CPU utilization percentage"
  type        = number
  default     = 70
}

variable "memory_target_value" {
  description = "Target memory utilization percentage"
  type        = number
  default     = 75
}

# S3 bucket for CloudFront logs
variable "logs_bucket_domain_name" {
  description = "S3 bucket domain name for CloudFront access logs"
  type        = string
}

# Security
variable "cloudfront_prefix_list_id" {
  description = "CloudFront prefix list ID for security group rules of ALB"
  type        = string
}

variable "viewer_protocol_policy" {
  type    = string
  default = "redirect-to-https"
}