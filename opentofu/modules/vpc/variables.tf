variable "name" {
  type        = string
  description = "The name of the VPC used in tags and flow log groups"

  validation {
    condition     = var.name == lower(var.name)
    error_message = "The name must be lowercase"
  }
}

variable "cidr_block" {
  type        = string
  description = "The CIDR block for the VPC"
}

variable "private_subnets" {
  type        = map(string)
  description = "The CIDR blocks for the private subnets"
}

variable "public_subnets" {
  type        = map(string)
  description = "The CIDR blocks for the public subnets"
}
