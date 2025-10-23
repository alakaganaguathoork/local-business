data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_hostnames = var.enable_dns_hostnames

  tags = {
    Name = "${var.environment}-vpc"
  }
}

# resource "aws_subnet" "public_subnet_count" {
#   count = try(var.public_subnets_count, 0) > 0 ? var.public_subnets_count : 0 

#   vpc_id            = aws_vpc.main.id
#   cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index)
#   availability_zone = element(data.aws_availability_zones.available.names, count.index)
#   map_public_ip_on_launch = true

#   tags = {
#     Name = "${var.environment}-public-subnet-${element(data.aws_availability_zones.available.names, count.index)}"
#   }
# }

# resource "aws_subnet" "private_subnet_count" {
#   count = try(var.private_subnets_count, 0) 

#   vpc_id            = aws_vpc.main.id
#   cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index+10)
#   availability_zone = element(data.aws_availability_zones.available.names, count.index)

#   tags = {
#     Name = "${var.environment}-private-subnet-${element(data.aws_availability_zones.available.names, count.index)}"
#   }
# }

resource "aws_subnet" "defined_public_subnet" {
  for_each = { for idx, subnet in var.public_subnets : idx => subnet }

  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value
  availability_zone       = element(data.aws_availability_zones.available.names, each.key)
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.environment}-public-subnet-${element(data.aws_availability_zones.available.names, each.key)}"
  }
}

resource "aws_subnet" "defined_private_subnet" {
  for_each = { for idx, subnet in var.private_subnets : idx => subnet }

  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value
  availability_zone       = element(data.aws_availability_zones.available.names, each.key)
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.environment}-private-subnet-${element(data.aws_availability_zones.available.names, each.key)}"
  }
}

module "igw" {
  count  = var.enable_gateway == true ? 1 : 0
  source = "./igw"

  environment    = var.environment
  vpc_id         = aws_vpc.main.id
  public_subnets = aws_subnet.defined_public_subnet
}

module "nat" {
  count  = var.enable_nat == true ? 1 : 0
  source = "./nat"

  environment     = var.environment
  vpc_id          = aws_vpc.main.id
  public_subnets  = aws_subnet.defined_public_subnet
  private_subnets = aws_subnet.defined_private_subnet

  depends_on = [module.igw]
}

module "security_groups" {
  source = "./security-group"

  vpc_id          = aws_vpc.main.id
  security_groups = var.security_groups
}

resource "aws_vpc_endpoint" "secret-manager" {
  count = var.create_secretmanager_endpoint ? 1 : 0

  vpc_id              = aws_vpc.main.id
  private_dns_enabled = true
  vpc_endpoint_type   = "Interface"
  service_name        = "com.amazonaws.${aws_vpc.main.region}.secretsmanager"
  subnet_ids          = values(aws_subnet.defined_private_subnet)[*].id
  security_group_ids  = [module.security_groups.groups["secretsmanager"].id]

  tags = {
    Name = "secretsmanager-ep"
  }
}
