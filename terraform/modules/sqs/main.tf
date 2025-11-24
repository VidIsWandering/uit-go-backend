resource "aws_sqs_queue" "booking_dlq" {
  name = "uit-go-booking-request-dlq"
}

resource "aws_sqs_queue" "booking_queue" {
  name                      = "uit-go-booking-request-queue"
  delay_seconds             = 0
  max_message_size          = 262144
  message_retention_seconds = 86400 # 1 day
  receive_wait_time_seconds = 10    # Long polling

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.booking_dlq.arn
    maxReceiveCount     = 3
  })

  tags = {
    Name = "uit-go-booking-request-queue"
  }
}
