variable "cluster_name" {
  description = "Name for the ECS cluster"
  type        = string
}

variable "family_name" {
  description = "Name for the ECS task definiton family"
  type        = string
}

variable "compatibilities" {
  description = "List of ECS launch types to support"
  type        = list(string)
  default     = ["FARGATE"] # Optional default
}

variable "network_mode" {
  description = "Name of the network mode"
  type        = string
  default     = "awsvpc"
}

variable "container_port" {
  description = "Port of the container"
  type        = number

}

variable "container_name" {
  description = "Name of the container"
  type        = string
}

variable "image" {
  description = "url of the image"
  type        = string
}
variable "cpu" {
  description = "url of the image"
  type        = number
}
variable "memory" {
  description = "url of the image"
  type        = number
}
variable "container_cpu" {
  description = "url of the image"
  type        = number
}
variable "container_memory" {
  description = "url of the image"
  type        = number
}

variable "aws_region" {
  description = "Name of the region"
  type        = string
}

variable "log_group" {
  description = "log group"
  type        = string
}

variable "ecs_service_name" {
  description = "Name of the ECS service"
  type        = string
}

variable "service_launch_type" {
  description = "Launch type of the ecs service"
  type        = string
}

variable "public_subnet_ids" {
  description = "A list of public subnet IDs to place the ECS tasks in."
  type        = list(string)
}

variable "ecs_security_group_ids" {
  description = "A list of security group IDs for the ECS tasks."
  type        = list(string)
}

variable "assign_public_ip" {
  description = "To decided whether to assign tasks a public ip"
  type        = bool
}

variable "environment" {
  description = "Environment (staging|prod)"
  type        = string
  validation {
    condition     = contains(["staging", "prod"], var.environment)
    error_message = "Must be 'staging' or 'prod'."
  }
}

variable "aws_lb_target_group_arn" {
  description = "target group of alb"
  type = string
}



variable "mongodb_uri" {
  description = "A map of environment variables to pass to the ECS container."
  type        = string
  sensitive = true
}

variable "email_id" {
  description = "A map of environment variables to pass to the ECS container."
  type        = string
  sensitive = true
}
variable "email_password" {
  description = "A map of environment variables to pass to the ECS container."
  type        = string
  sensitive = true
}
variable "jwt_secret" {
  description = "A map of environment variables to pass to the ECS container."
  type        = string
  sensitive = true
}