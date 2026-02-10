#!/bin/bash

# Test script to publish a sample event to EventBridge
# Usage: ./test-event-publish.sh [environment]

set -e

ENVIRONMENT="${1:-development}"
EVENT_BUS_NAME="fiap-tech-challenge-events-${ENVIRONMENT}"

echo "📤 Publishing test event to ${EVENT_BUS_NAME}..."

# Sample OrderCreated event
aws events put-events \
  --entries "[
    {
      \"Source\": \"os-service\",
      \"DetailType\": \"OrderCreated\",
      \"Detail\": \"{\\\"eventId\\\":\\\"test-$(date +%s)\\\",\\\"orderId\\\":\\\"ord-test-123\\\",\\\"clientId\\\":\\\"cli-456\\\",\\\"vehicleId\\\":\\\"veh-789\\\",\\\"requestedServices\\\":[\\\"Oil Change\\\"],\\\"timestamp\\\":\\\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\\\"}\",
      \"EventBusName\": \"${EVENT_BUS_NAME}\"
    }
  ]"

echo "✅ Test event published successfully!"
echo ""
echo "Check the SQS queues for the event:"
echo "  - Billing Service queue should receive this OrderCreated event"
echo ""
echo "Monitor in AWS Console:"
echo "  EventBridge: https://console.aws.amazon.com/events/home?region=us-east-1"
echo "  SQS: https://console.aws.amazon.com/sqs/home?region=us-east-1"
