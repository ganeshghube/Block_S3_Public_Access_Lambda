data "aws_caller_identity" "current" {}

# -----------------------------------------------------------
# set up AWS Cloudwatch Event every Monday to Friday at 9am
# -----------------------------------------------------------

resource "aws_cloudwatch_event_rule" "schedule" {
  name                = "event-invoke-s3-public-lambda1"
  schedule_expression = "cron(0 9 ? * MON-FRI *)"
}

# -----------------------------------------------------------
# Create IAM Role for s3 public lambda
# -----------------------------------------------------------

resource "aws_iam_role" "lambda_s3_public_role" {
  provider = aws.security
  
  name = var.lambda_s3_public_role

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

# -----------------------------------------------------------
# set up AWS Cloudwatch Event to target a lambda function
# -----------------------------------------------------------

resource "aws_cloudwatch_event_target" "main" {
  rule = aws_cloudwatch_event_rule.schedule.name
  arn  = aws_lambda_function.lambda_s3_public.arn
}

resource "aws_lambda_function" "lambda_s3_public" {
  filename         = var.filename
  function_name    = var.lambda_function_name
  role             = aws_iam_role.lambda_s3_public_role.arn
  handler          = "s3_public.lambda_handler"
  source_code_hash = base64sha256(var.filename)
  runtime          = "python3.7"
  timeout          = "300"

  environment {
    variables = {
      AWS_ACCOUNT   = data.aws_caller_identity.current.account_id
      SNS_TOPIC_ARN = aws_cloudformation_stack.sns_topic.outputs["ARN"]
      S3_EXCEPTION  = var.ssm_s3_list_parameter
    }
  }
}

resource "aws_cloudwatch_log_group" "lambda_s3_public_log" {
  name              = "/aws/lambda/${var.lambda_function_name}"
  retention_in_days = 14
}

# -----------------------------------------------------------
# Collect Source Email SSM Parameters
# -----------------------------------------------------------

data "aws_ssm_parameter" "display_name" {
  name = var.display_name
}

# -----------------------------------------------------------
# Collect destination emails SSM Parameters
# -----------------------------------------------------------

data "aws_ssm_parameter" "s3_public_emails" {
  name = var.ssm_s3_public_emails
}

# -----------------------------------------------------------
# Create policy for logging
# -----------------------------------------------------------

resource "aws_iam_policy" "s3_public_log_policy" {
  provider = aws.security
  name        = var.s3_public_log_policy
  description = "IAM policy for logging from lambda"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*",
      "Effect": "Allow"
    }
  ]
}
EOF
}

# -----------------------------------------------------------
# Create policy for CloudWatch Event - SNS
# -----------------------------------------------------------

data "aws_iam_policy_document" "sns_publish" {
  statement {
    effect    = "Allow"
    actions   = ["SNS:Publish"]
    resources = ["${aws_cloudformation_stack.sns_topic.outputs["ARN"]}"]
  }
}

resource "aws_iam_policy" "sns" {
  provider = aws.security
  policy = data.aws_iam_policy_document.sns_publish.json
  name   = var.sns_iam_access
}

# -----------------------------------------------------------
# Attach SNS Policy to Lambda role
# -----------------------------------------------------------

resource "aws_iam_role_policy_attachment" "lambda_sns" {
  provider = aws.security
  role       = aws_iam_role.lambda_s3_public_role.name
  policy_arn = aws_iam_policy.sns.arn
}

# -----------------------------------------------------------
# READONLY SSM policy
# -----------------------------------------------------------

resource "aws_iam_policy" "access_ssm_policy" {
  provider = aws.security
  name        = var.access_ssm_policy
  description = "IAM policy for reading SSM parameter"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ssm:GetParameter*"
      ],
      "Resource": "*",
      "Effect": "Allow"
    }
  ]
}
EOF
}

# -----------------------------------------------------------
# READONLY IAM policy
# -----------------------------------------------------------

resource "aws_iam_policy" "access_s3_policy" {
  provider = aws.security
  name        = var.access_s3_policy
  description = "IAM policy for read and write public access block"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:GetBucketAcl",
        "s3:GetAccountPublicAccessBlock",
        "s3:GetBucketPublicAccessBlock",
        "s3:List*",
        "s3:PutBucketPublicAccessBlock"
      ],
      "Resource": "*",
      "Effect": "Allow"
    }
  ]
}
EOF
}

# -----------------------------------------------------------
# Attach Logging Policy to Lambda role
# -----------------------------------------------------------

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  provider = aws.security
  role       = aws_iam_role.lambda_s3_public_role.name
  policy_arn = aws_iam_policy.s3_public_log_policy.arn
}

# -----------------------------------------------------------
# Attach iam Policy to Lambda role
# -----------------------------------------------------------

resource "aws_iam_role_policy_attachment" "lambda_ssm" {
  provider = aws.security
  role       = aws_iam_role.lambda_s3_public_role.name
  policy_arn = aws_iam_policy.access_ssm_policy.arn
}

# -----------------------------------------------------------
# Attach iam Policy to Lambda role
# -----------------------------------------------------------

resource "aws_iam_role_policy_attachment" "lambda_s3" {
  provider = aws.security
  role       = aws_iam_role.lambda_s3_public_role.name
  policy_arn = aws_iam_policy.access_s3_policy.arn
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_s3_public.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.schedule.arn
}

# -----------------------------------------------------------
# AWS SNS topic (https://www.terraform.io/docs/providers/aws/r/sns_topic_subscription.html#email)
# -----------------------------------------------------------

resource "aws_cloudformation_stack" "sns_topic" {
  name          = var.stack_name
  template_body = data.template_file.cloudformation_sns_stack.rendered
}

# -----------------------------------------------------------
# Use Cloudformation template for EMAIL SNS Topic
# -----------------------------------------------------------

data "template_file" "cloudformation_sns_stack" {
  template = file("${path.module}/email-sns-stack.json.tpl")

  vars = {
    display_name  = data.aws_ssm_parameter.display_name.value
    subscriptions = "${join("," , formatlist("{ \"Endpoint\": \"%s\", \"Protocol\": \"%s\" }", split(",", data.aws_ssm_parameter.s3_public_emails.value), var.protocol))}"
  }
}
