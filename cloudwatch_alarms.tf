# Create an SNS Topic to broadcast critical security events
resource "aws_sns_topic" "security_alerts" {
  name = "ai-gateway-high-severity-alerts"
}

# Subscribe an operational email address to the notification chain
resource "aws_sns_topic_subscription" "email_sub" {
  topic_arn = aws_sns_topic.security_alerts.arn
  protocol  = "email"
  endpoint  = "security-ops@yourcompany.com" # Replace with your real team inbox
}

# Create a Log Group explicitly tracking the API gateway output
resource "aws_cloudwatch_log_group" "gateway_log_group" {
  name              = "/aws/ecs/ai-gateway-api"
  retention_in_days = 90
}

# Define the Metric Filter that parses the JSON structure looking for injections
resource "aws_cloudwatch_log_metric_filter" "injection_metric_filter" {
  name           = "PromptInjectionCountFilter"
  pattern        = "{ $.event_type = \"PROMPT_INJECTION_DETECTED\" }"
  log_group_name = aws_cloudwatch_log_group.gateway_log_group.name

  metric_transformation {
    name      = "InjectionAttempts"
    namespace = "AIGatewayDefenses"
    value     = "1"
  }
}

# Establish the Threshold Alarm
resource "aws_cloudwatch_metric_alarm" "injection_rate_alarm" {
  alarm_name          = "ai-gateway-brute-force-injection-alert"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = aws_cloudwatch_log_metric_filter.injection_metric_filter.metric_transformation[0].name
  namespace           = aws_cloudwatch_log_metric_filter.injection_metric_filter.metric_transformation[0].namespace
  period              = 60 # 60 Second sliding evaluation window
  statistic           = "Sum"
  threshold           = 3
  alarm_description   = "CRITICAL: Multiple AI prompt injection attempts intercepted in under 60 seconds. High risk of automated attack vector probing."
  alarm_actions       = [aws_sns_topic.security_alerts.arn]
}


