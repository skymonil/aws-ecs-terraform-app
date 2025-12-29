variable "environment" {
  type = string
  validation {
    condition     = contains(["staging", "prod"], var.environment)
    error_message = "Must be staging or prod"
  }
}

variable "cluster_name" {
  type = string
}

variable "ecs_service_name" {
  type = string
}

variable "aws_region" {
  type = string
}

#################################
# Container
#################################

variable "container" {
  description = "ECS container configuration"
  type = object({
    name   = string
    image  = string
    port   = number
    cpu    = number
    memory = number
  })
}

#################################
# Task definition
#################################

variable "task" {
  description = "ECS task-level configuration"
  type = object({
    family          = string
    cpu             = number
    memory          = number
    compatibilities = optional(list(string), ["FARGATE"])
    network_mode    = optional(string, "awsvpc")
  })
}

#################################
# Networking
#################################

variable "networking" {
  description = "ECS networking configuration"
  type = object({
    subnet_ids         = list(string)
    security_group_ids = list(string)
    assign_public_ip   = optional(bool, true)
  })
}

#################################
# Autoscaling
#################################

variable "autoscaling" {
  description = "ECS autoscaling configuration"
  type = object({
    enabled       = optional(bool, false)
    min           = optional(number, 1)
    max           = optional(number, 3)
    cpu_target    = optional(number, 70)
    memory_target = optional(number, 75)
  })
  default = {}
}

#################################
# Load balancer
#################################

variable "load_balancer" {
  description = "Load balancer integration"
  type = object({
    target_group_arn = string
  })
}

#################################
# Logging
#################################

variable "log_group" {
  description = "CloudWatch log group name"
  type        = string
}

#################################
# Secrets
#################################

variable "secrets" {
  description = "Application secrets"
  type = object({
    mongodb_uri     = string
    email_id        = string
    email_password  = string
    jwt_secret      = string
  })
  sensitive = true
}
