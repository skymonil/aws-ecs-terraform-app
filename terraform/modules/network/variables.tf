variable "vpc_cidr_block" {
  type        = string
  description = "Primary CIDR block for the VPC"
  validation {
    condition     = can(cidrnetmask(var.vpc_cidr_block)) && tonumber(split("/", var.vpc_cidr_block)[1]) <= 24
    error_message = "Must be a valid CIDR block with a mask of /24 or smaller (e.g., /24, /23, /22, etc.)."
  }
}


variable "region" {
  type        = string
  description = "AWS Region"
}

variable "public_subnets" {
  description = "Map of public subnets with their CIDR and AZ"
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
  
  validation {
    condition = length(var.public_subnets) >= 1
    error_message = "At least one public subnet is required."
  }
}

variable "vpc_name" {
  description = "Name for the VPC"
  type        = string

  validation {
    condition     = length(var.vpc_name) > 0
    error_message = "VPC Name cannot be empty"
  }
}

variable "environment" {
  description = "Deployment environment (e.g. dev, staging, prod)"
  type        = string
  validation {
    condition     = contains(["staging", "prod"], var.environment)
    error_message = "Must be staging or prod"
  }
}

