# 1. THE PERIMETER IP BLACKLIST BLOCK
resource "aws_wafv2_ip_set" "attacker_blocklist" {
  name               = "ai-gateway-attacker-blocklist"
  description        = "Dynamic IP blocklist populated automatically by CloudWatch AI intrusion alarms."
  scope              = "REGIONAL"
  ip_address_version = "IPV4"
  addresses          = [] # Starts empty; dynamically populated by our Lambda function
}

# 2. THE AWS WAF WEB ACL RULE
resource "aws_wafv2_web_acl" "gateway_waf" {
  name        = "ai-gateway-perimeter-shield"
  description = "Protects the AI Load Balancer by dropping traffic from high-risk IPs."
  scope       = "REGIONAL"

  default_action {
    allow {} # Allow untrusted traffic by default unless explicitly blacklisted
  }

  rule {
    name     = "BlocklistEnforcementRule"
    priority = 1 # Top priority execution check

    action {
      block {} # DROP connection immediately
    }

    statement {
      ip_set_reference_statement {
        arn = aws_wafv2_ip_set.attacker_blocklist.arn
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "BlocklistEnforcementMetric"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "AIGatewayWAFMetric"
    sampled_requests_enabled   = true
  }
}

# 3. INTERCEPT LAMBDA ENGINE ROLES
resource "aws_iam_role" "lambda_waf_role" {
  name = "ai-lambda-waf-automation-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "://amazonaws.com" }
    }]
  })
}

resource "aws_iam_policy" "lambda_waf_policy" {
  name = "ai-lambda-waf-automation-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["wafv2:GetIPSet", "wafv2:UpdateIPSet"]
        Resource = [aws_wafv2_ip_set.attacker_blocklist.arn]
      },
      {
        Effect   = "Allow"
        Action   = ["logs:FilterLogEvents"]
        Resource = ["${aws_cloudwatch_log_group.gateway_log_group.arn}:*"]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_attach" {
  role       = aws_iam_role.lambda_waf_role.name
  policy_arn = aws_iam_policy.lambda_waf_policy.arn
}

# 4. LAMBDA DISPATCH ENGINE
resource "aws_lambda_function" "waf_blocker" {
  filename         = "lambda_payload.zip" # Auto-generated during manual compilation step below
  function_name    = "ai-gateway-waf-blocker"
  role             = aws_iam_role.lambda_waf_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.11"
  timeout          = 15

  environment {
    variables = {
      WAF_IP_SET_ID  = aws_wafv2_ip_set.attacker_blocklist.id
      WAF_IP_SET_ARN = aws_wafv2_ip_set.attacker_blocklist.arn
      WAF_IP_SET_NAME= aws_wafv2_ip_set.attacker_blocklist.name
      LOG_GROUP_NAME = aws_cloudwatch_log_group.gateway_log_group.name
    }
  }
}

# 5. ATTACH LAMBDA ACTION TO EXISTING CLOUDWATCH ALARM
resource "aws_sns_topic_subscription" "lambda_sub" {
  topic_arn = aws_sns_topic.security_alerts.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.waf_blocker.arn
}

resource "aws_lambda_permission" "allow_sns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.waf_blocker.function_name
  principal     = "://amazonaws.com"
  source_arn    = aws_sns_topic.security_alerts.arn
}