output "booking_queue_url" {
  value = aws_sqs_queue.booking_queue.url
}

output "booking_queue_arn" {
  value = aws_sqs_queue.booking_queue.arn
}
