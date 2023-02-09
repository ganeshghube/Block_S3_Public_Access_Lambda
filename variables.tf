variable "filename" {
  description = "(Optional) Zip file containing lambda code. Default s3-public-payload.zip"
  default     = "s3-public-payload.zip"
}

variable "lambda_function_name" {
  description = "(Optional) Lambda name. Default s3-public"
  default     = "s3-public1"
}

variable "lambda_s3_public_role" {
  description = "(Optional) Lambda IAM Role name. Default s3-public-role"
  default     = "s3-public-role1"
}

variable "s3_public_log_policy" {
  description = "(Optional) Lambda log group name. Default s3-public-log"
  default     = "s3-public-log1"
}

variable "access_s3_policy" {
  description = "(Optional) IAM Policy name for S3 policy. Default s3-public-s3-policy"
  default     = "s3-public-s3-policy1"
}

variable "access_ssm_policy" {
  description = "(Optional) Access SSM IAM Policy name. Default s3-public-ssm-policy"
  default     = "s3-public-ssm-policy1"
}

variable "protocol" {
  default     = "email"
  description = "SNS Protocol to use. email or email-json"
}

variable "stack_name" {
  description = "(Optional) Cloudformation stack name. Default s3-public-sns-cloudformation"
  default     = "s3-public-sns-cloudformation1"
}

variable "ssm_s3_public_emails" {
  description = "(Optional) SSM Parameter name containing list of recipient's email address. Default default-destination-emails"
  default     = "default-destination-emails"
}

variable "display_name" {
  description = "(Optional) SSM parameter containing the source email address used to send emails. Default default-source-email"
  default     = "default-source-email"
}

variable "sns_iam_access" {
  description = "(Optional) SNS IAM Policy name. Default s3-public-sns-iam-access"
  default     = "s3-public-sns-iam-access1"
}

variable "ssm_s3_list_parameter" {
  description = "(Optional) SSM Parameter name containing list of S3 buckets exempt from scanning. Default s3-public-exception-list"
  default     = "s3-public-exception-list"
}


