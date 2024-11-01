variable "splunk_hec_url" {
  description = "The URL for the Splunk HTTP Event Collector (HEC)"
  type        = string
}

variable "splunk_hec_access_key" {
  description = "The access token for the Splunk HEC"
  type        = string
  sensitive   = true
}

variable "firehose_role_name" {
  description = "The name of the IAM role for Firehose"
  type        = string
  default     = "firehose_delivery_role"
}

variable "firehose_bucket_name" {
  description = "The name of the S3 bucket for Firehose backup"
  type        = string
  default     = "firehose-backup-example-bucket"
}

variable "cloudwatch_log_group_infra" {
  description = "The log group name for EC2 infrastructure logs"
  type        = string
  default     = "aws/ec2/infralogs"
}

variable "cloudwatch_log_group_app" {
  description = "The log group name for EC2 application logs"
  type        = string
  default     = "aws/ec2/applogs"
}

variable "buffering_size" {
  description = "Buffer size for Firehose delivery stream (in MB)"
  type        = number
  default     = 5
}

variable "buffering_interval" {
  description = "Buffer interval for Firehose delivery stream (in seconds)"
  type        = number
  default     = 300
}
