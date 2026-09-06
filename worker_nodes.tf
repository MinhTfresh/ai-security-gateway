# Fetch latest optimized ECS Amazon Linux 2 AMI
data "aws_ssm_parameter" "ecs_ami" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2/recommended"
}

resource "aws_iam_role" "ec2_instance_role" {
  name = "ai-ec2-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "://amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_ec2_policy" {
  role       = aws_iam_role.ec2_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "ecs_instance_profile" {
  name = "ai-ecs-instance-profile"
  role = aws_iam_role.ec2_instance_role.name
}

resource "aws_security_group" "ec2_pool_sg" {
  name   = "ai-ec2-pool-sg"
  vpc_id = aws_vpc.ai_defense_vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# The EC2 Auto Scaling Launch Template
resource "aws_launch_template" "ecs_worker_template" {
  name_prefix   = "ecs-worker-tpl-"
  image_id      = jsondecode(data.aws_ssm_parameter.ecs_ami.value).image_id
  instance_type = "t3.medium" # Choose a size capable of sustaining small docker execution frames

  iam_instance_profile {
    arn = aws_iam_instance_profile.ecs_instance_profile.arn
  }

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.ec2_pool_sg.id]
  }

  # Crucial script injection: Registers the EC2 machine natively to your targeted ECS core
  user_data = base64encode(<<-EOF
              #!/bin/bash
              echo ECS_CLUSTER=${aws_ecs_cluster.ai_cluster.name} >> /etc/ecs/ecs.config
              EOF
  )
}

resource "aws_autoscaling_group" "ecs_worker_asg" {
  name                = "ai-ecs-worker-asg"
  vpc_zone_identifier = [aws_subnet.private_subnet.id]
  desired_capacity    = 2
  max_size            = 5
  min_size            = 1

  launch_template {
    id      = aws_launch_template.ecs_worker_template.id
    version = "$Latest"
  }

  tag {
    key                 = "AmazonECSManaged"
    value               = true
    propagate_at_launch = true
  }
}