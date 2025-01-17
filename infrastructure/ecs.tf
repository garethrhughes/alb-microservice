module "ecs" {
  source       = "terraform-aws-modules/ecs/aws"
  cluster_name = "microsite-bff-dev"
  fargate_capacity_providers = {
    FARGATE = {
      default_capacity_provider_strategy = {
        base   = 1
        weight = 100
      }
    }
  }
  services = {
    "microsite-bff-service-dev" = {
      cpu              = 512
      memory           = 1024
      assign_public_ip = true

      container_definitions = {
        microsite-bff = {
          image                    = "${data.aws_caller_identity.current.account_id}.dkr.ecr.ap-southeast-2.amazonaws.com/microsite-bff:latest"
          essential                = true
          readonly_root_filesystem = false

          port_mappings = [
            {
              name          = "http",
              containerPort = 3000,
              hostPort      = 3000,
              protocol      = "tcp",
              appProtocol   = "http"
            }
          ]
          environment = [

          ]
          log_configuration = {
            "logDriver" = "awslogs",
            "options" = {
              "awslogs-group"         = "/aws/ecs/microsite-bff-dev",
              "mode"                  = "non-blocking",
              "awslogs-create-group"  = "true",
              "max-buffer-size"       = "25m",
              "awslogs-region"        = "ap-southeast-2",
              "awslogs-stream-prefix" = "ecs"
            },
            "secretOptions" = []
          },
          health_check = {
            command      = ["CMD-SHELL", "curl -f http://localhost:3000/api/hello || exit 1"]
            interval     = 30
            timeout      = 5
            retries      = 3
            start_period = 60
          }
        }
      }
      load_balancer = {
        service = {
          target_group_arn = module.alb.target_groups["api"].arn
          container_name   = "microsite-bff"
          container_port   = 3000
        }
      }
      subnet_ids         = ["subnet-0288b13ac640294b2", "subnet-0ba961e92a57e41ee", "subnet-0718aafaaa9d6d462"]
      security_group_ids = [aws_security_group.allow_tls_bff.id]
    }
    "microsite-fe-service-dev" = {
      cpu              = 512
      memory           = 1024
      assign_public_ip = true

      # Container definition(s)
      container_definitions = {
        microsite-fe = {
          image                    = "${data.aws_caller_identity.current.account_id}.dkr.ecr.ap-southeast-2.amazonaws.com/microsite-fe:latest"
          essential                = true
          readonly_root_filesystem = false

          port_mappings = [
            {
              name          = "http",
              containerPort = 3000,
              hostPort      = 3000,
              protocol      = "tcp",
              appProtocol   = "http"
            }
          ]
          environment = [

          ]
          log_configuration = {
            "logDriver" = "awslogs",
            "options" = {
              "awslogs-group"         = "/aws/ecs/microsite-fe-dev",
              "mode"                  = "non-blocking",
              "awslogs-create-group"  = "true",
              "max-buffer-size"       = "25m",
              "awslogs-region"        = "ap-southeast-2",
              "awslogs-stream-prefix" = "ecs"
            },
            "secretOptions" = []
          },
          health_check = {
            command      = ["CMD-SHELL", "curl -f http://localhost:3000 || exit 1"]
            interval     = 30
            timeout      = 5
            retries      = 3
            start_period = 60

          }
        }
      }
      load_balancer = {
        service = {
          target_group_arn = module.alb.target_groups["http"].arn
          container_name   = "microsite-fe"
          container_port   = 3000
        }
      }
      subnet_ids         = ["subnet-0288b13ac640294b2", "subnet-0ba961e92a57e41ee", "subnet-0718aafaaa9d6d462"]
      security_group_ids = [aws_security_group.allow_tls_fe.id]
    }
  }
}

resource "aws_security_group" "allow_tls_fe" {
  name        = "microsite-fe-service-allow_tls-dev"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = data.aws_vpc.selected.id

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_security_group" "allow_tls_bff" {
  name        = "microsite-bff-service-allow_tls-dev"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = data.aws_vpc.selected.id

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}