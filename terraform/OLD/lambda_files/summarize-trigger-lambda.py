import json
import urllib.parse
import urllib.request

import boto3

s3 = boto3.client("s3")

# Hardcoded for POC
EC2_INFERENCE_URL = "http://35.159.33.141:3000/summarize"
INPUT_PREFIX = "raw_text/"
OUTPUT_PREFIX = "summaries/"


def handler(event, context):
    print("Lambda triggered")
    print(f"Received event: {json.dumps(event)}")

    results = []

    for record in event["Records"]:
        bucket = record["s3"]["bucket"]["name"]
        key = urllib.parse.unquote_plus(record["s3"]["object"]["key"])

        print(f"Processing object s3://{bucket}/{key}")

        if not key.startswith(INPUT_PREFIX):
            print(f"Skipping object due to prefix mismatch: {key}")
            results.append({"key": key, "status": "skipped"})
            continue

        # 1. Read uploaded text file from S3
        print("Reading object from S3")
        obj = s3.get_object(Bucket=bucket, Key=key)
        text = obj["Body"].read().decode("utf-8", errors="replace")
        print(f"Read {len(text)} characters from input file")

        # 2. Call BentoML service running on EC2
        print(f"Calling BentoML endpoint at {EC2_INFERENCE_URL}")
        payload = json.dumps({"text": text}).encode("utf-8")
        request = urllib.request.Request(
            EC2_INFERENCE_URL,
            data=payload,
            headers={"Content-Type": "application/json"},
            method="POST",
        )

        with urllib.request.urlopen(request, timeout=30) as response:
            status_code = response.status
            summary_text = response.read().decode("utf-8")

        print(f"Received response from model (HTTP {status_code})")
        print(f"Summary length: {len(summary_text)} characters")

        # 3. Write summary back to S3 (as plain text)
        relative = key[len(INPUT_PREFIX):]
        base_name = relative.rsplit(".", 1)[0]
        output_key = f"{OUTPUT_PREFIX}{base_name}_summary.txt"

        print(f"Writing summary to s3://{bucket}/{output_key}")
        s3.put_object(
            Bucket=bucket,
            Key=output_key,
            Body=summary_text.encode("utf-8"),
            ContentType="text/plain; charset=utf-8",
        )

        print("Write completed successfully")
        results.append({"input": key, "output": output_key, "status": "ok"})

    print("Lambda execution finished")
    return {"results": results}