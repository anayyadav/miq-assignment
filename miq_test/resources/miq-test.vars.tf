############# Variable Def for miq-test ##################
variable "miq_test_cidr" {
  description = "The CIDR block for the VPC."
}

variable "miq_test_public_subnets" {
  description = "Comma separated list of public subnets"
}

variable "miq_test_private_subnets" {
  description = "Comma separated list of public subnets"
}

variable "miq_test_name" {
  description = "Name tag, e.g stack"
  default     = "miq-test"
}

variable "miq_test_tag_purpose" {
}

variable "miq_test_root_volume_size" {
}
variable "miq_test_root_volume_type" {
}
variable "miq_test_image" {
}
variable "miq_test_type" {
}
variable "miq_test_region" {
}