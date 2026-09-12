output "identity_arn" {
  value = aws_ses_email_identity.this.arn
}

output "email_address" {
  value = aws_ses_email_identity.this.email
}