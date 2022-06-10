"""
evidence AWS Lambda function code
"""

import json
import base64
import os
import boto3

def get_evidence():
    """
    When GET request is made to function, return all entries in evidence DynamoDB table.
    """

    client = boto3.client('dynamodb')
    results = client.scan(TableName="evidence")
    return {
        'statusCode': 200,
        'body': str(results)
    }

def post_evidence(event: dict):
    """
    When POST request is made to function, upload data to S3 and write hash values to
    evidence DynamoDB table.
    """

    req_body = json.loads(base64.b64decode(event["body"]))

    # Write file to S3
    client = boto3.client('s3')
    client.put_object(
        Body = base64.b64decode(req_body["file_data"]),
        Bucket = "${bucket}",
        Key = req_body["file_name"]
        )

    # Determine hashes
    filename = "/tmp/" + req_body["file_name"]
    temp_file = open(filename, "wb")
    temp_file.write(base64.b64decode(req_body["file_data"]))
    temp_file.close()

    md5_sum = os.popen("md5sum " + filename).read().split("  ")[0]
    sha1_sum = os.popen("sha1sum " + filename).read().split("  ")[0]

    # Write results to database
    client = boto3.client('dynamodb')
    client.put_item(
        TableName='evidence',
        Item={
            'FileName': {
                'S': req_body["file_name"]
            },
            'MD5Sum': {
                'S': md5_sum
            },
            'SHA1Sum': {
                'S': sha1_sum
            }
        }
    )

    return {
        'statusCode': 200,
        'body': "Success"
    }

# pylint: disable=unused-argument
def lambda_handler (event, context):
    """
    Entrypoint for AWS Lambda Function - evidence
    """

    request_method = event['requestContext']['httpMethod']
    if request_method == "GET":
        response = get_evidence()
    elif request_method == "POST":
        response = post_evidence(event)
    else:
        response = {
            'statusCode': 403,
            'body': "Unauthorized HTTP Method: " + request_method
        }
    return response
