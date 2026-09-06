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

# 1. NETWORKING LAYER (Isolated VPC)
resource "aws_vpc" "ai_defense_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags                 = { Name = "ai-defense-vpc" }
}

resource "aws_subnet" "private_subnet" {
  vpc_id            = aws_vpc.ai_defense_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  tags              = { Name = "ai-private-subnet" }
}

# 2. STATE LAYER (Managed ElastiCache Redis)
resource "aws_security_group" "redis_sg" {
  name   = "ai-redis-sg"
  vpc_id = aws_vpc.ai_defense_vpc.id

  ingress {
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = [aws_subnet.private_subnet.cidr_block]
  }
}

resource "aws_elasticache_subnet_group" "redis_subnets" {
  name       = "ai-redis-subnet-group"
  subnet_ids = [aws_subnet.private_subnet.id]
}

resource "aws_elasticache_cluster" "redis" {
  cluster_id           = "ai-defense-redis"
  engine               = "redis"
  node_type            = "cache.t4g.micro"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis7"
  subnet_group_name    = aws_elasticache_subnet_group.redis_subnets.name
  security_group_ids   = [aws_security_group.redis_sg.id]
}

# 3. ECS CLUSTER 
resource "aws_ecs_cluster" "ai_cluster" {
  name = "ai-defense-cluster"
}

# IAM Execution Role for Tasks
resource "aws_iam_role" "ecs_execution_role" {
  name = "ai-ecs-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "://amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# 4. ENTRYPOINT BLOCK TASK DEFINITION (AWS Fargate Type)
resource "aws_ecs_task_definition" "gateway_api" {
  family                   = "ai-gateway-api"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn

  container_definitions = jsonencode([{
    name      = "gateway-api"
    image     = "://amazonaws.com"
    essential = true
    portMappings = [{
      containerPort = 8000
      hostPort      = 8000
    }]
    environment = [
      { name = "REDIS_URL", value = "redis://${aws_elasticache_cluster.redis.cache_nodes[0].address}:6379/0" },
      { name = "EXPECTED_GATEWAY_TOKEN", value = "prod-super-secure-token-991" }
    ]
  }])
}

# 5. SANDBOX ENGINE TASK DEFINITION (EC2 Type to enable Docker Socket Passthrough)
resource "aws_ecs_task_definition" "celery_worker" {
  family                   = "ai-celery-worker"
  network_mode             = "bridge" # Essential for linking with standard EC2 daemon host interfaces
  requires_compatibilities = ["EC2"]
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn

  volume {
    name      = "docker-socket"
    host_path = "/var/run/docker.sock" # MAP HOST DEAMON INTO TASK
  }

  container_definitions = jsonencode([{
    name      = "celery-worker"
    image     = "://amazonaws.com"
    essential = true
    cpu       = 512
    memory    = 1024
    environment = [
      { name = "REDIS_URL", value = "redis://${aws_elasticache_cluster.redis.cache_nodes[0].address}:6379/0" }
    ]
    volumeMounts = [{
      sourceVolume  = "docker-socket"
      containerPath = "/var/run/docker.sock"
    }]
  }])
}