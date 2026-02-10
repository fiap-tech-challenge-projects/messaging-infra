# EventBridge Outputs

output "event_bus_name" {
  description = "Name of the EventBridge custom event bus"
  value       = aws_cloudwatch_event_bus.main.name
}

output "event_bus_arn" {
  description = "ARN of the EventBridge custom event bus"
  value       = aws_cloudwatch_event_bus.main.arn
}

# SQS Queue Outputs

output "os_service_queue_url" {
  description = "URL of the OS Service SQS queue"
  value       = aws_sqs_queue.os_service.url
}

output "os_service_queue_arn" {
  description = "ARN of the OS Service SQS queue"
  value       = aws_sqs_queue.os_service.arn
}

output "os_service_dlq_url" {
  description = "URL of the OS Service Dead Letter Queue"
  value       = aws_sqs_queue.os_service_dlq.url
}

output "billing_service_queue_url" {
  description = "URL of the Billing Service SQS queue"
  value       = aws_sqs_queue.billing_service.url
}

output "billing_service_queue_arn" {
  description = "ARN of the Billing Service SQS queue"
  value       = aws_sqs_queue.billing_service.arn
}

output "billing_service_dlq_url" {
  description = "URL of the Billing Service Dead Letter Queue"
  value       = aws_sqs_queue.billing_service_dlq.url
}

output "execution_service_queue_url" {
  description = "URL of the Execution Service SQS queue"
  value       = aws_sqs_queue.execution_service.url
}

output "execution_service_queue_arn" {
  description = "ARN of the Execution Service SQS queue"
  value       = aws_sqs_queue.execution_service.arn
}

output "execution_service_dlq_url" {
  description = "URL of the Execution Service Dead Letter Queue"
  value       = aws_sqs_queue.execution_service_dlq.url
}

# IAM Policy Outputs (for attachment to service roles)

output "os_service_sqs_consumer_policy_arn" {
  description = "ARN of IAM policy for OS Service to consume SQS messages"
  value       = aws_iam_policy.os_service_sqs_consumer.arn
}

output "billing_service_sqs_consumer_policy_arn" {
  description = "ARN of IAM policy for Billing Service to consume SQS messages"
  value       = aws_iam_policy.billing_service_sqs_consumer.arn
}

output "execution_service_sqs_consumer_policy_arn" {
  description = "ARN of IAM policy for Execution Service to consume SQS messages"
  value       = aws_iam_policy.execution_service_sqs_consumer.arn
}

output "eventbridge_publisher_policy_arn" {
  description = "ARN of IAM policy for services to publish events to EventBridge"
  value       = aws_iam_policy.eventbridge_publisher.arn
}

# Monitoring Outputs

output "cloudwatch_dashboard_name" {
  description = "Name of the CloudWatch dashboard for messaging"
  value       = var.enable_cloudwatch_alarms ? aws_cloudwatch_dashboard.messaging[0].dashboard_name : null
}

output "sns_topic_arn" {
  description = "ARN of SNS topic for alarms (if email configured)"
  value       = var.enable_cloudwatch_alarms && var.alarm_email != "" ? aws_sns_topic.alarms[0].arn : null
}

# Summary Output

output "summary" {
  description = "Summary of deployed messaging infrastructure"
  value = {
    event_bus = {
      name = aws_cloudwatch_event_bus.main.name
      arn  = aws_cloudwatch_event_bus.main.arn
    }
    queues = {
      os_service = {
        queue_url = aws_sqs_queue.os_service.url
        dlq_url   = aws_sqs_queue.os_service_dlq.url
      }
      billing_service = {
        queue_url = aws_sqs_queue.billing_service.url
        dlq_url   = aws_sqs_queue.billing_service_dlq.url
      }
      execution_service = {
        queue_url = aws_sqs_queue.execution_service.url
        dlq_url   = aws_sqs_queue.execution_service_dlq.url
      }
    }
    monitoring = {
      dashboard_name = var.enable_cloudwatch_alarms ? aws_cloudwatch_dashboard.messaging[0].dashboard_name : "disabled"
      alarms_enabled = var.enable_cloudwatch_alarms
    }
  }
}
