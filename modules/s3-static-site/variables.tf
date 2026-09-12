variable "bucket_name" {
  type = string
}

variable "index_document" {
  type    = string
  default = "index.html"
}

variable "index_html_content" {
  description = "Fully rendered HTML for the index document. The caller renders this with templatefile() — this module just stores it."
  type        = string
}

variable "tags" {
  type    = map(string)
  default = {}
}