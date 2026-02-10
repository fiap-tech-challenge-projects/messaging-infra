# CLAUDE.md - Messaging Infrastructure

This file provides guidance to Claude Code when working with the messaging infrastructure.

## Overview

This repository contains the AWS EventBridge and SQS infrastructure that enables asynchronous event-driven communication between Phase 4 microservices.

## Key Principles

1. **Event-Driven Architecture**: All inter-service communication for async operations uses EventBridge + SQS
2. **Database Per Service**: No service directly accesses another service's database
3. **Decoupled Services**: EventBridge acts as the central event routing hub
4. **Reliability**: SQS provides message durability, retry logic, and dead letter queues

## Infrastructure Components

### EventBridge
- **Custom Event Bus**: `fiap-tech-challenge-events-{env}`
- **Event Rules**: Route events based on `detail-type` to appropriate SQS queues
- **Event Archive**: Optional (disabled by default, enable for production)

### SQS Queues
- **os-service-events-{env}**: Receives BudgetGenerated, PaymentCompleted, ExecutionCompleted
- **billing-service-events-{env}**: Receives OrderCreated, ExecutionCompleted
- **execution-service-events-{env}**: Receives PaymentCompleted, BudgetApproved

### Dead Letter Queues (DLQs)
- Capture messages that fail processing after 3 retries
- Retain messages for 14 days for troubleshooting

## Event Schema Standard

All events published to EventBridge must follow this schema:

```typescript
interface DomainEvent {
  eventId: string;        // UUID
  eventType: string;      // e.g., "OrderCreated"
  eventVersion: string;   // e.g., "1.0"
  source: string;         // e.g., "os-service"
  timestamp: string;      // ISO 8601
  correlationId?: string; // For tracing
  causationId?: string;   // Event that caused this
  data: Record<string, any>;
  metadata?: {
    userId?: string;
    traceId?: string;
  };
}
```

## Deployment

### Prerequisites
- AWS CLI configured
- Terraform >= 1.5
- AWS credentials with EventBridge and SQS permissions

### Deploy
```bash
cd terraform
terraform init
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars
terraform plan
terraform apply
```

### Verify
```bash
# Test event publishing
../scripts/test-event-publish.sh development

# Check queue
aws sqs get-queue-attributes \
  --queue-url https://sqs.us-east-1.amazonaws.com/ACCOUNT/billing-service-events-development \
  --attribute-names ApproximateNumberOfMessages
```

## Monitoring

### CloudWatch Dashboard
- View at: AWS Console > CloudWatch > Dashboards > `fiap-tech-challenge-messaging-{env}`
- Metrics: Message counts, queue depth, DLQ messages

### CloudWatch Alarms
- Queue depth > 1000 (backlog alert)
- DLQ has messages (processing failures)
- Old messages > 5 minutes (slow consumers)

## Troubleshooting

### Messages Not Arriving in Queue
1. Check EventBridge rule is enabled: `aws events describe-rule --name route-to-{service}-{env}`
2. Verify event pattern matches published event detail-type
3. Check SQS queue policy allows EventBridge to send messages

### Messages in DLQ
1. Retrieve messages: `aws sqs receive-message --queue-url {dlq-url}`
2. Inspect error details in message attributes
3. Fix consumer code bug
4. Manually reprocess or purge DLQ

### High Queue Depth
1. Check consumer service is running: `kubectl get pods -n ftc-app-{env}`
2. Check consumer logs for errors: `kubectl logs -f {pod-name}`
3. Increase consumer replicas if needed: `kubectl scale deployment/{service} --replicas=3`

## Cost Optimization

- EventBridge: Free tier covers 14M events/month
- SQS: Free tier covers 1M requests/month
- Enable long polling (already configured) to reduce empty receives
- Use batch operations where possible

## CI/CD

GitHub Actions automatically:
- Validates Terraform on PR
- Plans infrastructure changes (comments on PR)
- Applies changes on merge to main/develop

## Related Services

This messaging infrastructure is consumed by:
- [os-service](../os-service) - Publishes OrderCreated, consumes Budget/Payment/Execution events
- [billing-service](../billing-service) - Publishes Budget/Payment events, consumes OrderCreated
- [execution-service](../execution-service) - Publishes Execution events, consumes PaymentCompleted
- [saga-orchestrator-service](../saga-orchestrator-service) - Consumes saga-related events

## Making Changes

### Adding a New Event Type
1. Update `eventbridge.tf` to add event type to appropriate rule's `event_pattern`
2. Document new event in this file
3. Update consuming service to handle new event
4. Test with `scripts/test-event-publish.sh`

### Adding a New Service Queue
1. Add queue name to `locals.queue_names` in `main.tf`
2. Add DLQ in `sqs.tf`
3. Add main queue in `sqs.tf`
4. Add IAM consumer policy in `sqs.tf`
5. Add EventBridge rule and target in `eventbridge.tf`
6. Add SQS queue policy to allow EventBridge
7. Add outputs in `outputs.tf`
8. Update monitoring dashboard and alarms in `monitoring.tf`

### Environment Variables

Terraform outputs are used by microservices:
- `EVENT_BUS_NAME`: EventBridge bus name for publishing
- `SQS_QUEUE_URL`: Queue URL for consuming messages

## Security

- SQS queues use server-side encryption (SSE-SQS)
- IAM policies follow least privilege principle
- EventBridge requires IAM permissions to publish events
- SQS queue policies restrict access to EventBridge service principal

## AWS Academy Notes

- Session tokens expire every 4 hours
- Update GitHub secrets before deployment
- No custom IAM roles (uses LabRole)
