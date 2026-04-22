variable "aws_region" {
  description = "AWS Region to provison resources"
  type        = string
  default     = "us-west-2"
}

variable "instance_type" {
  description = "OpenClaw EC2 Instance Type"
  type        = string
  default     = "t3.xlarge"
}

variable "instance_volume_size" {
  description = "OpenClaw EC2 Instance Volume Size"
  type        = number
  default     = 20
}

variable "ssh_key_name" {
  description = "SSH Key Name to access the OpenClaw EC2 Instance. If null, Use EC2 Connect or SessionManager"
  type        = string
  default     = null
}

variable "openclaw_port" {
  description = "OpenClaw Port"
  type        = number
  default     = 18789
}

variable "openclaw_model" {
  description = "OpenClaw Default Model"
  type        = string
  default     = "amazon-bedrock/global.amazon.nova-2-lite-v1:0"
}

variable "enable_poweruser" {
  description = "Enable PowerUser Access or only Bedrock Access? If true, PowerUser Access will be enabled."
  type        = bool
  default     = true
}
