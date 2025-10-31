variable "region" {
  type    = string
  default = "ap-south-1"
}

variable "environment" {
  type    = string
  default = "staging"
}

variable "vpc_name" {
  description = "Name of the shared VPC"
  type        = string
}

variable "bucket_name" {
  description = "S3 bucket name for staging"
  type        = string
}

variable "acm_certificate_arn" {
  description = "ACM certificate ARN in us-east-1"
  type        = string
}

variable "alb_acm_certificate_arn" {
  description = "ACM certificate ARN in ap-south-1 for ALB"
  type        = string
}

variable "domain_alias" {
  description = "CloudFront domain alias (e.g., staging.615915.xyz)"
  type        = string
}

variable "ecs_service_name" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "family_name" {
  type = string
}

variable "image" {
  type = string
}

variable "container_memory" {
  type    = number
  default = 128
}

variable "container_port" {
  type    = number
  default = 5000
}

variable "cpu" {
  type    = number
  default = 128
}

variable "assign_public_ip" {
  type    = bool
  default = true
}

variable "container_name" {
  type = string
}

variable "service_launch_type" {
  type    = string
  default = "FARGATE"
}

variable "memory" {
  type    = number
  default = 256
}

variable "log_group" {
  type = string
}

variable "container_cpu" {
  type    = number
  default = 128
}

variable "mongodb_uri" {
  type      = string
  sensitive = true
}

variable "email_id" {
  type      = string
  sensitive = true
}

variable "email_password" {
  type      = string
  sensitive = true
}

variable "jwt_secret" {
  type      = string
  sensitive = true
}

variable "cache_policy_id" {
  type = string
}

variable "origin_request_policy_id" {
  type = string
}

variable "api_cache_policy_id" {
  type = string
}

variable "api_origin_request_policy_id" {
  type = string
}

variable "availability_zones" {
  description = "List of availability zones to use"
  type        = list(string)
  default     = []
}

variable "public_subnet_cidrs" {
  description = "List of CIDR blocks for public subnets"
  type        = list(string)
  default     = []
}