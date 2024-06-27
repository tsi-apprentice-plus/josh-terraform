variable "my_name" {
  type    = string
}

variable "my_email" {
  type    = string
}

variable "region" {
  type    = string
  default = "us-east-1"
}

variable "domain" {
  type    = string
  default = "netbuildertraining.com"
}

variable "access_key" {
  type = string
  sensitive = true
}

variable "secret_key" {
  type = string
  sensitive = true
}

variable "backend_port" {
  type = string
}

variable "frontend_port" {
  type = string
}

variable "pem_path" {
  type = string
}

variable "mongodb_uri" {
  type = string
}