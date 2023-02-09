# Block_S3_Public_Access_Lambda

<h1 align="center">By using this script on aws lambda script  you can  block public access all s3 buckets as preventive measure an automated way </h1>

## create ssm parameter SSM Parameters
To avoid exposing email addresses in a GitHub repository, this project is making the use of the following SSM parameters:

s3-public-exception-list: List of S3 Buckets excluded from Scan(StringList type)
default-source-email: Default name used as a source (String type)
default-destination-emails: List of email recipients (StringList type)
Regarding the configuration of each of these SSM parameters, have a look below on these screenshots:

## terraform init

## terraform plan

## terraform apply
