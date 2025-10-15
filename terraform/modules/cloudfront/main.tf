resource "aws_cloudfront_origin_access_control" "s3_oac" {
  name                              = "${var.environment}-oac"
  description                       = "OAC for ${var.environment} S3 access"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}


resource "aws_cloudfront_distribution" "cdn" {

  origin {
    domain_name = var.alb_dns_name
    origin_id   = "alb-origin"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  origin {

    domain_name = var.s3_bucket_regional_domain_name
    origin_id   = "s3-origin"

    origin_access_control_id = aws_cloudfront_origin_access_control.s3_oac.id

  }



  custom_error_response {
    error_code         = 404
    response_code      = 200
    response_page_path = "/index.html"
  }

  custom_error_response {
    error_code         = 403
    response_code      = 200
    response_page_path = "/index.html"
  }


  enabled             = true
  aliases             = [var.domain_alias]
  default_root_object = "index.html"






  default_cache_behavior {

    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "s3-origin"

    origin_request_policy_id = var.origin_request_policy_id
    cache_policy_id          = var.cache_policy_id

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = var.acm_certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }

  ordered_cache_behavior {
    path_pattern = "/api/*"
    target_origin_id = "alb-origin"

     allowed_methods  = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    viewer_protocol_policy = "redirect-to-https"

    cache_policy_id = var.api_cache_policy_id
    origin_request_policy_id = var.api_origin_request_policy_id

    min_ttl = 0
    default_ttl = 0
    max_ttl = 0

  
  }
  
}

# Update S3 bucket policy to allow only CloudFront access
resource "aws_s3_bucket_policy" "cdn_access" {
  bucket = var.s3_bucket_id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "AllowCloudFrontServicePrincipalReadOnly"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = ["s3:GetObject"]
        Resource = "${var.s3_bucket_arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.cdn.arn
          }
        }
      }
    ]
  })
}
