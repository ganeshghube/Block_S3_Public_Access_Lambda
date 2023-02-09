"""
# Function:
# Purpose:  A Python function to list out any AWS S3 buckets in the account that have
# public access based on their ACLs, either Read or Write permissions.
"""

import os
import logging
from botocore.exceptions import ClientError
import boto3

SNS_TOPIC_ARN = os.getenv('SNS_TOPIC_ARN')
S3_EXCEPTION = os.getenv('S3_EXCEPTION')
AWS_ACCOUNT = os.getenv('AWS_ACCOUNT')
LOGGER = logging.getLogger()
LOGGER.setLevel(logging.INFO)

def lambda_handler(event, _):
    """
    Lambda handler function
    """
    LOGGER.info('Event: %s', event)
    private_buckets = []
    exception_buckets = []
    exception_buckets = ssm_s3_list(S3_EXCEPTION)
    if exception_buckets is None:
        LOGGER.error('SSM Parameter missing')
        sns_notify_public_bucket(private_buckets)
        return None
    client = boto3.client('s3')
    list_bucket_response = list_buckets(client)
    for bucket_info in list_bucket_response:
        if bucket_info['Name'] not in exception_buckets:
            response = retrieve_block_access(client, bucket_info['Name'])
            if block_configuration(client, bucket_info['Name'], response):
                private_buckets.append(bucket_info['Name'])
    LOGGER.info('Private Buckets: %s', private_buckets)
    if private_buckets:
        LOGGER.info('Sending sns message')
        sns_notify_public_bucket(private_buckets)
    return None

def list_buckets(client):
    """
    Return list of buckets
    """
    return client.list_buckets()['Buckets']

def ssm_s3_list(ssm_name):
    """
    Return list of buckets from SSM Parameters
    """
    ssmclient = boto3.client('ssm', region_name='eu-west-1')
    s3_exception_list = []
    if ssm_name:
        try:
            s3_exception_list = ssmclient.get_parameter(
                Name=ssm_name
                )['Parameter']['Value'].split(',')
            LOGGER.info('Buckets in list of exception: %s', s3_exception_list)
        except ClientError as client_error:
            LOGGER.error('No SSM parameter found: %s', client_error)
            return None
    else:
        return None
    return s3_exception_list

def retrieve_block_access(client, bucket_name):
    """
    Return public access block if exists
    """
    try:
        return client.get_public_access_block(Bucket=bucket_name)
    except ClientError as client_error:
        LOGGER.error('Get Access Block Exception: %s', client_error)
        return None

def block_configuration(client, bucket_name, response):
    """
    Return True if PublicAccessBlockConfiguration is missing
    """
    if response is not None:
        for _, value in response['PublicAccessBlockConfiguration'].items():
            if str(value) == "False":
                apply_block_access(client, bucket_name)
                return True
    else:
        apply_block_access(client, bucket_name)
        return True
    return False

def apply_block_access(client, bucket_name):
    """
    Apply public access block
    """
    try:
        LOGGER.info('Put Access Block on S3 Bucket: %s', bucket_name)
        return client.put_public_access_block(
            Bucket=bucket_name,
            PublicAccessBlockConfiguration={
                'BlockPublicAcls': True,
                'IgnorePublicAcls': True,
                'BlockPublicPolicy': True,
                'RestrictPublicBuckets': True
                })
    except ClientError as client_error:
        LOGGER.error('Put Access Block Exception: %s', client_error)
        return None

def sns_notify_public_bucket(private_buckets):
    """
    Notify the list of buckets where Public Access Block has been turn ON
    """
    sns_client = boto3.client('sns', region_name='eu-west-1')
    subject = 'AWS Account - {} S3 Bucket Public Status'.format(AWS_ACCOUNT)
    message_body = ''
    if private_buckets:
        message_body = '\n Public Access Block configuration applied to: {}'.format(private_buckets)
        message_body += '\n Configuration applied to {} buckets'.format(len(private_buckets))
        message_body += '\n Add your S3 Bucket to exception list if it is supposed to be public'
    else:
        message_body = 'Missing SSM Parameter, please configure it'
    sns_client.publish(TopicArn=SNS_TOPIC_ARN, Message=message_body, Subject=subject)
