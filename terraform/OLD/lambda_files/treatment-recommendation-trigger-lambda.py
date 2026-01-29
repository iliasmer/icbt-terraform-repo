import json
import urllib.parse
import urllib.request

import boto3

s3 = boto3.client("s3")

# Hardcoded for POC
EC2_INFERENCE_URL = "http://18.197.209.19:3000/predict_treatment"
INPUT_PREFIX = "summaries/"
OUTPUT_PREFIX = "treatment_recommendations/"


def handler(event, context):
    print("Treatment recommendation Lambda triggered")
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

        # 1) Read summary file from S3
        print("Reading summary from S3")
        obj = s3.get_object(Bucket=bucket, Key=key)
        summary_text = obj["Body"].read().decode("utf-8", errors="replace")
        print(f"Read {len(summary_text)} characters from summary file")

        # 2) POC: hardcoded feature payload
        # Replace this later with real feature extraction from summary_text
        payload_dict = {
            "phq9": 10,
            "gad7": 2,
            "keds": 28,
            "minispin": 8,
            "padis": 5,
            "isi": 14,
            "ptsd": 0,
            "bgq": 8,
            "scoff": 0,
            "iowa": 11,
            "pss4": 10,
            "phobia_screener": 2,
            "health_anxiety_screener": 2,
            "gaf": 2,
        }

        print(f"Calling treatment endpoint at {EC2_INFERENCE_URL}")
        payload = json.dumps(payload_dict).encode("utf-8")
        request = urllib.request.Request(
            EC2_INFERENCE_URL,
            data=payload,
            headers={"Content-Type": "application/json"},
            method="POST",
        )

        with urllib.request.urlopen(request, timeout=30) as response:
            status_code = response.status
            response_body = response.read().decode("utf-8")

        print(f"Received response from model (HTTP {status_code})")
        print(f"Raw response body: {response_body}")

        # 3) Write result back to S3 (JSON)
        relative = key[len(INPUT_PREFIX):]
        base_name = relative.rsplit(".", 1)[0]
        output_key = f"{OUTPUT_PREFIX}{base_name}_treatment.json"

        print(f"Writing treatment recommendation to s3://{bucket}/{output_key}")
        s3.put_object(
            Bucket=bucket,
            Key=output_key,
            Body=response_body.encode("utf-8"),
            ContentType="application/json",
        )

        print("Write completed successfully")
        results.append({"input": key, "output": output_key, "status": "ok"})

    print("Treatment recommendation Lambda execution finished")
    return {"results": results}
