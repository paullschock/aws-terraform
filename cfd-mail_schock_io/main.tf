provider "aws" {
  region = "${var.aws-region}"
}

provider "aws" {
  alias = "east"
  region = "us-east-1"
}

data "aws_route53_zone" "validation" {
  name = "${var.root-name}"
}

resource "aws_acm_certificate" "main" {
  domain_name = "${var.root-name}"
  subject_alternative_names = ["*.${var.root-name}"]
  validation_method = "DNS"
  tags {
    terraform = "true"
  }
  provider = "aws.east"
}

resource "aws_route53_record" "validation" {
  name    = "${aws_acm_certificate.main.domain_validation_options.0.resource_record_name}"
  type    = "${aws_acm_certificate.main.domain_validation_options.0.resource_record_type}"
  zone_id = "${data.aws_route53_zone.validation.zone_id}"
  records = ["${aws_acm_certificate.main.domain_validation_options.0.resource_record_value}"]
  ttl     = "60"
}

resource "aws_acm_certificate_validation" "main" {
  certificate_arn = "${aws_acm_certificate.main.arn}"
  validation_record_fqdns = ["${aws_route53_record.validation.*.fqdn}"]
  provider = "aws.east"
}


resource "aws_cloudfront_distribution" "mail_schock_io" {
  origin {
    domain_name = "${var.backend-name}"
    origin_id   = "${var.frontend-name}"
    origin_path = "${var.uri}"

    custom_origin_config {
      // These are all the defaults.
      http_port              = "80"
      https_port             = "443"
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.1", "TLSv1.2"]
    }
  }

  enabled = true
  comment = "Managed by terraform"
  aliases = ["${var.frontend-name}"]

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "${var.frontend-name}"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = ["US"]
      }
    }

  viewer_certificate {
    acm_certificate_arn = "${aws_acm_certificate_validation.main.certificate_arn}"
    ssl_support_method = "sni-only"
  }
}

resource "aws_route53_record" "frontend-name" {
  zone_id = "${data.aws_route53_zone.validation.zone_id}"

  // NOTE: name is blank here.
  name = "${var.frontend-name}"
  type = "A"

  alias = {
    name                   = "${aws_cloudfront_distribution.mail_schock_io.domain_name}"
    zone_id                = "${aws_cloudfront_distribution.mail_schock_io.hosted_zone_id}"
    evaluate_target_health = false
  }
}
