terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# 1. ISOLATED CORPORATE VPC
resource "aws_vpc" "corp_ai_vpc" {
  cidr_block           = "10.100.0.0/16"
  enable_dns_hostnames = true
  tags                 = { Name = "corp-ai-security-vpc", Environment = "Production" }
}

resource "aws_subnet" "private_subnet_1" {
  vpc_id            = aws_vpc.corp_ai_vpc.id
  cidr_block        = "10.100.1.0/24"
  availability_zone = "us-east-1a"
  tags              = { Name = "corp-ai-private-1a" }
}

resource "aws_subnet" "private_subnet_2" {
  vpc_id            = aws_vpc.corp_ai_vpc.id
  cidr_block        = "10.100.2.0/24"
  availability_zone = "us-east-1b"
  tags              = { Name = "corp-ai-private-1b" }
}

# 2. ENCRYPTED MANAGED STATE LAYER (Amazon ElastiCache)
resource "aws_security_group" "elasticache_sg" {
  name        = "corp-ai-redis-sg"
  description = "Restricts Redis cluster access strictly to internal gateway components"
  vpc_id      = aws_vpc.corp_ai_vpc.id

  ingress {
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = [aws_subnet.private_subnet_1.cidr_block, aws_subnet.private_subnet_2.cidr_block]
  }
}

resource "aws_elasticache_subnet_group" "redis_subnet_group" {
  name       = "corp-ai-redis-subnet-group"
  subnet_ids = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]
}

resource "aws_elasticache_replication_group" "redis_cluster" {
  replication_group_id        = "corp-ai-redis-cluster"
  description                 = "Production Replicated Encrypted Redis for Gateway State"
  node_type                   = "cache.t4g.small"
  num_cache_nodes             = 2 # Configured for high availability multi-AZ failover
  automatic_failover_enabled  = true
  engine                      = "redis"
  engine_version              = "7.0"
  subnet_group_name           = aws_elasticache_subnet_group.redis_subnet_group.name
  security_group_ids          = [aws_security_group.elasticache_sg.id]
  at_rest_encryption_enabled  = true # SOC2 / ISO27017 Compliance Requirements
  transit_encryption_enabled = true
}

# 3. ENTERPRISE CONTAINER ORCHESTRATION CLUSTER (ECS)
resource "aws_ecs_cluster" "corp_ecs_cluster" {
  name = "corp-ai-gateway-cluster"
  setting {
    name  = "containerInsights"
    value = "enabled" # Enforces logging of micro-container metrics for corporate audit reviews
  }
}

# 4. ENTRYPOINT GATEWAY PROXY TASK DEFINITION (AWS Fargate Serverless)
resource "aws_ecs_task_definition" "corp_gateway_api" {
  family                   = "corp-ai-gateway-api"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"

  container_definitions = jsonencode([{
    name      = "gateway-api"
    image     = "${aws_ecr_repository.corp_api_repo.repository_url}:latest"
    essential = true
    portMappings = [{ containerPort = 8000, hostPort = 8000 }]
    environment = [
      { name = "REDIS_URL", value = "rediss://${aws_elasticache_replication_group.redis_cluster.primary_endpoint_address}:6379/0" },
      { name = "EXPECTED_GATEWAY_TOKEN", value = "SECURE_VAULT_FETCHED_TOKEN" }
    ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = "/aws/ecs/corp-ai-gateway-api"
        awslogs-region        = "us-east-1"
        awslogs-stream-prefix = "gateway"
      }
    }
  }])
}

resource "aws_ecr_repository" "corp_api_repo" {
  name                 = "corp-ai-gateway-api"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration { scan_on_push = true } # Enforces automatic CVE scanning during CI pipeline run loops
}