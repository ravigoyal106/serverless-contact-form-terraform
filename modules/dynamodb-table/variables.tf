variable "table_name" {
  description = "Name of the DynamoDB table"
  type = string
}

variable "hash_key" {
  description = "Name of the partition key attribute"
  type = string
  default = "submissionId"
}

variable "tags" {
description = "Tags to apply to the table"
type = map(string)
default = {}  
}

