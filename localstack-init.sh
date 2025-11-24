#!/bin/bash
echo "Initializing LocalStack SQS..."
awslocal sqs create-queue --queue-name uit-go-booking-request-queue
echo "SQS Queue created."
