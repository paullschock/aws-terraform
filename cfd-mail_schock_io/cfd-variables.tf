variable "frontend-name" {
  description = "Name used for cloudfront distribution origin"
  type = "string"
  default = "mail.schock.io"
}

variable "root-name" {
  description = " Root Namespace for Name used for cloudfront distribution origin"
  type = "string"
  default = "schock.io"
}

variable "backend-name" {
  description = "cloudfront target domain name"
  type = "string"
  default = "schock.awsapps.com"
}

variable "uri" {
  description = "uri path for cloudfront origin"
  type = "string"
  default = "/mail"
}
