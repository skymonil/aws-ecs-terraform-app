variable "bucket_name" {
  description = "Name of the S3 bucket"
  type        = string
}

variable "environment" {
  description = "Deployment environment (e.g. prod, stage)"
  type        = string
}

variable "backend_url" {
  type = string
  description = "URL of the backend which would vary per environment"
}

