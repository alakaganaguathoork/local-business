locals {
  env            = "test"
  region         = "us-east-1"
  vpc_cidr_block = "10.0.0.0/16"
  sg_allowed_ips_list = ["91.198.233.56/32"]
  account_id = data.aws_caller_identity.current.account_id

  access_users = [
    "arn:aws:iam::${local.account_id}:user/dev-cli",
    "arn:aws:iam::${local.account_id}:root"
  ]

  cluster = {
    name           = "sandbox"
    k8s_version    = "1.34"
  }

  security_groups = {
    # custom = {
    # "ingress-allowed-ips" = {
    # type              = "ingress"
    # from_port         = 22
    # to_port           = 22
    # protocol          = "tcp"
    # cidr_blocks       = ["91.198.233.56/32"]
    # description       = "Allow ssh from personal IPs"
    # }
    # "egress" = {
    # type              = "egress"
    # from_port         = 0
    # to_port           = 0
    # protocol          = "-1"
    # cidr_blocks       = ["0.0.0.0/0"]
    # description       = "Allow outbound traffic"
    # }
    # }
    argocd = {
      "ingress-http" = {
        type        = "ingress"
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        description = "Allow inbound http traffic"
      }
      "ingress-https" = {
        type        = "ingress"
        from_port   = 443
        to_port     = 443
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        description = "Allow inbound https traffic"
      }
      "ingress-30080" = {
        type        = "ingress"
        from_port   = 30080
        to_port     = 30080
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        description = "Allow inbound traffic on port 30080"
      }
      "egress" = {
        type        = "egress"
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
        description = "Allow outbound traffic"
      }
    }
  }

  buckets = {
    logs = {
      name = "sandbox-logs-test-6g6g6"
    }
    alerts = {
      name = "sandbox-alerts-test"
    }
  }
}
