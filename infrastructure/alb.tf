module "alb" {
  source     = "terraform-aws-modules/alb/aws"
  depends_on = [aws_acm_certificate_validation.cert_validation]

  name    = "microsite-alb-dev"
  vpc_id  = data.aws_vpc.selected.id
  subnets = ["subnet-0bb23f0bc0878a3a9", "subnet-05d5a6401b0bdc24c", "subnet-0908c952e37fb2e40"]

  # Security Group
  security_group_ingress_rules = {
    all_https = {
      from_port   = 443
      to_port     = 443
      ip_protocol = "tcp"
      description = "HTTPS web traffic"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }
  security_group_egress_rules = {
    all = {
      ip_protocol = "-1"
      cidr_ipv4   = data.aws_vpc.selected.cidr_block
    }
  }

  listeners = {
    ex-https = {
      port            = 443
      protocol        = "HTTPS"
      certificate_arn = aws_acm_certificate.cert.arn

      rules = {
        api = {
          priority = 1

          actions = [{
            type             = "forward"
            target_group_key = "api"
          }]

          conditions = [{
            path_pattern = {
              values = ["/api/*"]
            }
          }]
        }
      }

      forward = {
        target_group_key = "http"
      }
    }
  }

  target_groups = {
    http = {
      name_prefix = "fe"
      protocol    = "HTTP"
      port        = 80
      target_type = "ip"
      health_check = {
        enabled             = true
        interval            = 30
        path                = "/"
        port                = 3000
        healthy_threshold   = 5
        unhealthy_threshold = 2
        timeout             = 5
        protocol            = "HTTP"
        matcher             = "200-399"
      }
      create_attachment = false
    }
    api = {
      name_prefix = "api"
      protocol    = "HTTP"
      port        = 3000
      target_type = "ip"
      health_check = {
        enabled             = true
        interval            = 30
        path                = "/api/hello"
        port                = 3000
        healthy_threshold   = 5
        unhealthy_threshold = 2
        timeout             = 5
        protocol            = "HTTP"
        matcher             = "200-399"
      }
      create_attachment = false
    }
  }
}