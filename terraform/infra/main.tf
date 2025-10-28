###
## Data
###
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_eks_cluster" "main" {
  name = aws_eks_cluster.main.name
}

data "aws_eks_cluster_auth" "main" {
  name = aws_eks_cluster.main.name
}

data "aws_caller_identity" "current" {
}

locals {
  issuer = replace(data.aws_eks_cluster.main.identity[0].oidc[0].issuer, "https://", "")
}

###
## Networking
###
resource "aws_vpc" "main" {
  cidr_block = local.vpc_cidr_block
}

resource "aws_subnet" "subnet" {
  # provisions subnets dynamically with `count`, not from `input_data` 
  count                   = 2
  vpc_id                  = aws_vpc.main.id
  map_public_ip_on_launch = true
  cidr_block              = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index)
  availability_zone       = element(data.aws_availability_zones.available.names, count.index)

  tags = {
    "kubernetes.io/role/elb"                      = "1"
    "kubernetes.io/cluster/${local.cluster.name}" = "owned"
    "Name"                                        = "public-subnet-${local.cluster.name}-${count.index}"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "public_assoc" {
  count          = 2
  subnet_id      = aws_subnet.subnet[count.index].id
  route_table_id = aws_route_table.public.id
}

###
## Security groups
###
module "security-groups" {
  source = "../modules/vpc/security-group"

  vpc_id          = aws_vpc.main.id
  security_groups = local.security_groups
}

###
## Roles and policies
###
resource "aws_iam_role" "node" {
  name = "eks-auto-node"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = ["sts:AssumeRole"]
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "node_AmazonEKSWorkerNodeMinimalPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodeMinimalPolicy"
  role       = aws_iam_role.node.name
}

resource "aws_iam_role_policy_attachment" "node_AmazonEC2ContainerRegistryPullOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPullOnly"
  role       = aws_iam_role.node.name
}

resource "aws_iam_role_policy_attachment" "node_AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node.name
}

# Cluster IAM role
resource "aws_iam_role" "cluster" {
  name = "eks-cluster"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster.name
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSComputePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSComputePolicy"
  role       = aws_iam_role.cluster.name
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSBlockStoragePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSBlockStoragePolicy"
  role       = aws_iam_role.cluster.name
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSLoadBalancingPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSLoadBalancingPolicy"
  role       = aws_iam_role.cluster.name
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSNetworkingPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSNetworkingPolicy"
  role       = aws_iam_role.cluster.name
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSServicePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.cluster.name
}

resource "aws_iam_role" "loki" {
  name = "loki"
  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "oidc.eks.${local.region}.amazonaws.com/id/${aws_iam_openid_connect_provider.eks.id}:aud" = "sts.amazonaws.com"
          "oidc.eks.${local.region}.amazonaws.com/id/${aws_iam_openid_connect_provider.eks.id}:sub" = "system:serviceaccount:loki:loki"
        }
      }
      Effect = "Allow"
      Principal = {
        # Federated = "arn:aws:iam::${local.account_id}:oidc-provider/oidc.eks.${local.region}.amazonaws.com/id/${aws_iam_openid_connect_provider.eks.id}"
        Federated = aws_iam_openid_connect_provider.eks.arn
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy" "loki" {
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "LokiStorage",
        Effect = "Allow",
        Action = [
          "s3:ListBucket",
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject"
        ]

        Resource = [
          "arn:aws:s3:::${aws_s3_bucket.loki["chunk"].name}",
          "arn:aws:s3:::${aws_s3_bucket.loki["chunk"].name}/*",
          "arn:aws:s3:::${aws_s3_bucket.loki["ruler"].name}",
          "arn:aws:s3:::${aws_s3_bucket.loki["ruler"].name}/*"
        ]
      }
    ]
  })
  role = aws_iam_role.loki.name

  depends_on = [aws_s3_bucket.loki]
}

###
## Cluster
###
resource "aws_eks_cluster" "main" {
  name = local.cluster.name

  access_config {
    authentication_mode = "API"
  }

  role_arn = aws_iam_role.cluster.arn
  version  = local.cluster.k8s_version

  bootstrap_self_managed_addons = false

  compute_config {
    enabled       = true
    node_pools    = ["general-purpose"]
    node_role_arn = aws_iam_role.node.arn
  }

  kubernetes_network_config {
    elastic_load_balancing {
      enabled = true
    }
  }

  storage_config {
    block_storage {
      enabled = true
    }
  }

  vpc_config {
    endpoint_private_access = false
    endpoint_public_access  = true
    subnet_ids              = aws_subnet.subnet[*].id
  }

  # Ensure that IAM Role permissions are created before and deleted
  # after EKS Cluster handling. Otherwise, EKS will not be able to
  # properly delete EKS managed EC2 infrastructure such as Security Groups.
  depends_on = [
    aws_iam_role_policy_attachment.cluster_AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.cluster_AmazonEKSComputePolicy,
    aws_iam_role_policy_attachment.cluster_AmazonEKSBlockStoragePolicy,
    aws_iam_role_policy_attachment.cluster_AmazonEKSLoadBalancingPolicy,
    aws_iam_role_policy_attachment.cluster_AmazonEKSNetworkingPolicy,
    aws_iam_role_policy_attachment.cluster_AmazonEKSServicePolicy,
  ]
}


resource "aws_iam_openid_connect_provider" "eks" {
  url             = data.aws_eks_cluster.main.identity[0].oidc[0].issuer
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [local.oidc_thumbprint]

  depends_on = [aws_eks_cluster.main]
}

###
## Access management
###
resource "aws_eks_access_entry" "access_users" {
  for_each = { for users in local.access_users : users => users }

  cluster_name  = aws_eks_cluster.main.name
  principal_arn = each.value
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "access_users" {
  for_each = aws_eks_access_entry.access_users

  cluster_name  = aws_eks_cluster.main.name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = each.value.principal_arn
  access_scope {
    type = "cluster"
  }
}

resource "aws_s3_bucket" "loki" {
  for_each = local.buckets

  bucket = each.value["name"]
}
