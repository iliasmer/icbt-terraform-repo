import json
import os
import urllib.parse

import boto3

sqs = boto3.client("sqs")

QUEUE_URL = os.environ["QUEUE_URL"] 


def handler(event, context):
    print("PTTSD trigger Lambda triggered")
    print("Full event:")
    print(json.dumps(event))

    record = event["Records"][0]
    bucket = record["s3"]["bucket"]["name"]
    key = urllib.parse.unquote_plus(record["s3"]["object"]["key"])
    size = record["s3"]["object"].get("size")

    print(f"S3 bucket: {bucket}")
    print(f"S3 key: {key}")
    print(f"Object size: {size} bytes")

    message_body = {
        "bucket": bucket,
        "key": key,
        "stage": "pttsd"
    }

    print("Sending message to SQS:")
    print(json.dumps(message_body))

    resp = sqs.send_message(
        QueueUrl=QUEUE_URL,
        MessageBody=json.dumps(message_body),
    )

    print(f"SQS message sent, id: {resp['MessageId']}")

    return {
        "sent": True,
        "messageId": resp["MessageId"],
        "bucket": bucket,
        "key": key
    }
