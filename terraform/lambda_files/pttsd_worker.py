import json
import os
import time
import urllib.request
import urllib.parse
import boto3
import threading


AWS_REGION = os.getenv("AWS_REGION", "eu-central-1")
QUEUE_URL = os.environ["QUEUE_URL"]

INPUT_PREFIX = os.getenv("INPUT_PREFIX", "summaries/")
OUTPUT_PREFIX = os.getenv("OUTPUT_PREFIX", "pttsd_results/")
INFERENCE_URL = os.getenv("INFERENCE_URL", "http://localhost:8000/predict/text")

sqs = boto3.client("sqs", region_name=AWS_REGION)
s3 = boto3.client("s3", region_name=AWS_REGION)


def output_key_for(input_key: str) -> str:
    rel = input_key[len(INPUT_PREFIX):] if input_key.startswith(INPUT_PREFIX) else input_key
    base = rel.rsplit(".", 1)[0]
    return f"{OUTPUT_PREFIX}{base}_pttsd.json"


def call_model(payload_dict: dict) -> str:
    payload = json.dumps(payload_dict).encode("utf-8")
    req = urllib.request.Request(
        INFERENCE_URL,
        data=payload,
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    with urllib.request.urlopen(req, timeout=300) as resp:
        body = resp.read().decode("utf-8", errors="replace")
        if resp.status < 200 or resp.status >= 300:
            raise RuntimeError(f"Model HTTP {resp.status}: {body[:300]}")
        return body


def visibility_heartbeat(receipt: str, stop_evt: threading.Event):
    # Every 10s, set visibility to 30s from "now"
    while not stop_evt.wait(10):
        try:
            sqs.change_message_visibility(
                QueueUrl=QUEUE_URL,
                ReceiptHandle=receipt,
                VisibilityTimeout=30,
            )
        except Exception as e:
            print(f"VISIBILITY HEARTBEAT ERROR: {e}")


def stop_heartbeat(stop_evt: threading.Event, hb: threading.Thread) -> None:
    stop_evt.set()
    try:
        hb.join(timeout=1)
    except Exception:
        pass


def main():
    print("pttsd-worker started")
    print(f"QUEUE_URL={QUEUE_URL}")
    print(f"INFERENCE_URL={INFERENCE_URL}")
    print(f"INPUT_PREFIX={INPUT_PREFIX}")
    print(f"OUTPUT_PREFIX={OUTPUT_PREFIX}")

    while True:
        resp = sqs.receive_message(
            QueueUrl=QUEUE_URL,
            MaxNumberOfMessages=1,
            WaitTimeSeconds=20,
            VisibilityTimeout=30,
        )
        msgs = resp.get("Messages", [])
        if not msgs:
            continue

        msg = msgs[0]
        receipt = msg["ReceiptHandle"]

        stop_evt = None
        hb = None

        try:
            body = json.loads(msg["Body"])
            bucket = body["bucket"]
            key = urllib.parse.unquote_plus(body["key"])
            print(f"job: s3://{bucket}/{key}")

            if not key.startswith(INPUT_PREFIX):
                print(f"Skipping due to prefix mismatch: {key}")
                sqs.delete_message(QueueUrl=QUEUE_URL, ReceiptHandle=receipt)
                continue

            stop_evt = threading.Event()
            hb = threading.Thread(target=visibility_heartbeat, args=(receipt, stop_evt), daemon=True)
            hb.start()

            obj = s3.get_object(Bucket=bucket, Key=key)
            input_text = obj["Body"].read().decode("utf-8", errors="replace")
            print(f"Downloaded chars: {len(input_text)}")

            utterances = [ln.strip() for ln in input_text.splitlines() if ln.strip()]
            payload_dict = {"utterances": [utterances]}

            response_body = call_model(payload_dict)

            out_key = output_key_for(key)
            s3.put_object(
                Bucket=bucket,
                Key=out_key,
                Body=response_body.encode("utf-8"),
                ContentType="application/json",
            )
            print(f"wrote: s3://{bucket}/{out_key}")

            if stop_evt is not None and hb is not None:
                stop_heartbeat(stop_evt, hb)

            sqs.delete_message(QueueUrl=QUEUE_URL, ReceiptHandle=receipt)
            print("deleted message")

        except Exception as e:
            if stop_evt is not None and hb is not None:
                stop_heartbeat(stop_evt, hb)
            print(f"ERROR: {e}")
            time.sleep(2)
            # do not delete message, SQS will retry and DLQ later


if __name__ == "__main__":
    main()
