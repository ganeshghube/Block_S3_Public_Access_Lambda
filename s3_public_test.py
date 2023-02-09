import pytest
import s3_public
import os
import mock
from moto import mock_s3, mock_ssm
import boto3

@mock_s3()
def test_list_buckets():
    conn = boto3.client('s3')
    conn.create_bucket(Bucket='mybucket1')
    conn.create_bucket(Bucket='mybucket2')
    list = s3_public.list_buckets(conn)
    assert len(list) == 2
    assert list[0]['Name'] == ('mybucket1')
    assert list[1]['Name'] == ('mybucket2')


@mock_s3()
def test_retrieve_block_access():
    conn = boto3.client('s3')
    conn.create_bucket(Bucket='mybucket1')
    result = s3_public.retrieve_block_access(conn, 'mybucket1')
    assert result['PublicAccessBlockConfiguration'] == {}

@mock.patch.dict(os.environ,{'S3_EXCEPTION':'listbuckets'})
@mock_ssm()
def test_ssm_s3_list():
    client = boto3.client('ssm', region_name='eu-west-1')
    ssm_name = os.getenv('S3_EXCEPTION')
    client.put_parameter(
        Name='listbuckets',
        Description='A test parameter (list)',
        Value='value1,value2,value3',
        Type='StringList')
    response = s3_public.ssm_s3_list(ssm_name)
    assert response == ['value1', 'value2', 'value3']
