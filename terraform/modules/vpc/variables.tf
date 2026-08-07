variable "environment" {
  description = "Environment name (dev, qa, prod) - used for tagging and naming"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "az_count" {
  description = "Number of Availability Zones to span"
  type        = number
  default     = 3
}

variable "single_nat_gateway" {
  description = "Use one shared NAT Gateway instead of one per AZ - saves cost in dev/qa, set false for prod HA"
  type        = bool
  default     = true
}

variable "enable_vpc_endpoints" {
  description = "Create private VPC endpoints for S3 and ECR to reduce NAT data-transfer cost"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Common tags applied to all resources - used for cost allocation (FinOps)"
  type        = map(string)
  default     = {}
}
