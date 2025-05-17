variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region to deploy resources"
  type        = string
  default     = "us-central1"
}

variable "db_user" {
  description = "Database user"
  type        = string
  default     = "resume_admin"
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}

variable "container_image" {
  description = "The container image to deploy"
  type        = string
}

variable "domain_name" {
  description = "The domain name for the website"
  type        = string
  default     = ""
}

variable "REGION" {}
variable "PROJECT_NAME" {}

variable "VPC_CIDR" {}
variable "PUB_SUB_1_CIDR" {}
variable "PUB_SUB_2_CIDR" {}
variable "PRI_SUB_1_CIDR" {}
variable "PRI_SUB_2_CIDR" {}
variable "HOSTED_ZONE" {}