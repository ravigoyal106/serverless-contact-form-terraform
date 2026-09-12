variable "role_name" {
  description = "Name of the IAM role Lambda will assume."
  type = string
}

variable "dynamodb_table_arn" {
  description = "ARN of the Dynamodb table"
  type = string

}

variable "tags" {
  description = "Tags to apply to the role"
type = map(string)
default = {}
}
