variable "environment" {
  type = string
  validation {
    condition     = contains(["staging", "prod"], var.environment)
    error_message = "Must be staging or prod"
  }
}


variable "aws_region" {
  type = string
}


variable "ecs_config" {
  description = "ECS application configuration"
  type = object({
    cluster_name = string
    service_name = string

     task = object({
      family          = string
      cpu             = number
      memory          = number
      # Setting defaults means you don't HAVE to put them in .tfvars
      network_mode    = optional(string, "awsvpc")           
      compatibilities = optional(list(string), ["FARGATE"])
    })

    container = object({
      name   = string
      image  = string
      port   = number
      cpu    = number
      memory = number
    })

    

     

    logging = object({
      log_group = string
    })

    autoscaling = optional(object({
      enabled       = bool
      min           = number
      max           = number
      cpu_target    = number
      memory_target = number
    }), {
      enabled = false
      min     = 1
      max     = 3
      cpu_target = 70
      memory_target = 75
    })

    secrets = object({
      mongodb_uri    = string
      email_id       = string
      email_password = string
      jwt_secret     = string
    })
  })

  sensitive = true
}


variable "load_balancer" {
  description = "Load balancer integration"
  type = object({
    target_group_arn = string
  })
}


variable "networking" {
  type = object({
    subnet_ids         = list(string)
    security_group_ids = list(string)
    assign_public_ip   = bool
  })
}
#################################
# Load balancer
#################################



