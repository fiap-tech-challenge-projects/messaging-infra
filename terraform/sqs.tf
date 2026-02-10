# Dead Letter Queues (DLQs) - Must be created before main queues

resource "aws_sqs_queue" "os_service_dlq" {
  name                      = local.dlq_names.os_service
  message_retention_seconds = 1209600 # 14 days (maximum)

  tags = merge(local.common_tags, {
    Name    = local.dlq_names.os_service
    Service = "os-service"
    Type    = "DLQ"
  })
}

resource "aws_sqs_queue" "billing_service_dlq" {
  name                      = local.dlq_names.billing_service
  message_retention_seconds = 1209600

  tags = merge(local.common_tags, {
    Name    = local.dlq_names.billing_service
    Service = "billing-service"
    Type    = "DLQ"
  })
}

resource "aws_sqs_queue" "execution_service_dlq" {
  name                      = local.dlq_names.execution_service
  message_retention_seconds = 1209600

  tags = merge(local.common_tags, {
    Name    = local.dlq_names.execution_service
    Service = "execution-service"
    Type    = "DLQ"
  })
}

# Main SQS Queues

resource "aws_sqs_queue" "os_service" {
  name                       = local.queue_names.os_service
  delay_seconds              = 0
  max_message_size           = 262144 # 256 KB
  message_retention_seconds  = var.message_retention_seconds
  receive_wait_time_seconds  = 20 # Long polling enabled
  visibility_timeout_seconds = var.visibility_timeout_seconds

  # DLQ configuration
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.os_service_dlq.arn
    maxReceiveCount     = var.max_receive_count
  })

  # Server-side encryption
  sqs_managed_sse_enabled = true

  tags = merge(local.common_tags, {
    Name    = local.queue_names.os_service
    Service = "os-service"
    Type    = "EventQueue"
  })
}

resource "aws_sqs_queue" "billing_service" {
  name                       = local.queue_names.billing_service
  delay_seconds              = 0
  max_message_size           = 262144
  message_retention_seconds  = var.message_retention_seconds
  receive_wait_time_seconds  = 20
  visibility_timeout_seconds = var.visibility_timeout_seconds

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.billing_service_dlq.arn
    maxReceiveCount     = var.max_receive_count
  })

  sqs_managed_sse_enabled = true

  tags = merge(local.common_tags, {
    Name    = local.queue_names.billing_service
    Service = "billing-service"
    Type    = "EventQueue"
  })
}

resource "aws_sqs_queue" "execution_service" {
  name                       = local.queue_names.execution_service
  delay_seconds              = 0
  max_message_size           = 262144
  message_retention_seconds  = var.message_retention_seconds
  receive_wait_time_seconds  = 20
  visibility_timeout_seconds = var.visibility_timeout_seconds

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.execution_service_dlq.arn
    maxReceiveCount     = var.max_receive_count
  })

  sqs_managed_sse_enabled = true

  tags = merge(local.common_tags, {
    Name    = local.queue_names.execution_service
    Service = "execution-service"
    Type    = "EventQueue"
  })
}

# IAM Policies for microservices to consume from their queues

resource "aws_iam_policy" "os_service_sqs_consumer" {
  name        = "os-service-sqs-consumer-${var.environment}"
  description = "Allow OS Service to consume messages from its SQS queue"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowSQSReceive"
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:GetQueueUrl"
        ]
        Resource = aws_sqs_queue.os_service.arn
      },
      {
        Sid    = "AllowDLQRead"
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = aws_sqs_queue.os_service_dlq.arn
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_policy" "billing_service_sqs_consumer" {
  name        = "billing-service-sqs-consumer-${var.environment}"
  description = "Allow Billing Service to consume messages from its SQS queue"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowSQSReceive"
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:GetQueueUrl"
        ]
        Resource = aws_sqs_queue.billing_service.arn
      },
      {
        Sid    = "AllowDLQRead"
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = aws_sqs_queue.billing_service_dlq.arn
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_policy" "execution_service_sqs_consumer" {
  name        = "execution-service-sqs-consumer-${var.environment}"
  description = "Allow Execution Service to consume messages from its SQS queue"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowSQSReceive"
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:GetQueueUrl"
        ]
        Resource = aws_sqs_queue.execution_service.arn
      },
      {
        Sid    = "AllowDLQRead"
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = aws_sqs_queue.execution_service_dlq.arn
      }
    ]
  })

  tags = local.common_tags
}

# IAM Policy for all services to publish to EventBridge

resource "aws_iam_policy" "eventbridge_publisher" {
  name        = "eventbridge-publisher-${var.environment}"
  description = "Allow microservices to publish events to EventBridge"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowEventBridgePublish"
        Effect = "Allow"
        Action = [
          "events:PutEvents"
        ]
        Resource = aws_cloudwatch_event_bus.main.arn
      }
    ]
  })

  tags = local.common_tags
}
