import json
import os
import time
import tempfile
import urllib.parse
import urllib.request
import uuid
import wave
import struct
import math

import boto3
import threading

AWS_REGION = os.getenv("AWS_REGION", "eu-central-1")
QUEUE_URL = os.environ["QUEUE_URL"]

INPUT_PREFIX = os.getenv("INPUT_PREFIX", "audio/")
OUTPUT_PREFIX = os.getenv("OUTPUT_PREFIX", "transcripts/")
INFERENCE_URL = os.getenv("INFERENCE_URL", "http://whisper:3000/transcribe")

sqs = boto3.client("sqs", region_name=AWS_REGION)
s3 = boto3.client("s3", region_name=AWS_REGION)


def output_key_for(input_key: str, ext: str) -> str:
    rel = input_key[len(INPUT_PREFIX) :] if input_key.startswith(INPUT_PREFIX) else input_key
    base = rel.rsplit(".", 1)[0]
    return f"{OUTPUT_PREFIX}{base}.{ext}"


def plain_text_from_result(result_json: str) -> str:
    data = json.loads(result_json)

    segments = data.get("segments")
    if not isinstance(segments, list):
        raise ValueError("Model output missing 'segments' list")

    lines = []
    for seg in segments:
        t = seg.get("text")
        if t is None:
            t = ""
        # Keep everything (including gibberish), only trim edge whitespace.
        lines.append(str(t).strip())

    # Join by newline so you keep rough sentence boundaries.
    return "\n".join(lines).rstrip("\n") + "\n"


def call_model(audio_path: str) -> str:
    # BentoML expects multipart/form-data with field name matching the parameter: audio_file
    boundary = "----bentomlwhisperxboundary"
    with open(audio_path, "rb") as f:
        audio_bytes = f.read()

    filename = os.path.basename(audio_path) or "audio.wav"

    head = (
        f"--{boundary}\r\n"
        f'Content-Disposition: form-data; name="audio_file"; filename="{filename}"\r\n'
        f"Content-Type: application/octet-stream\r\n\r\n"
    ).encode("utf-8")
    tail = f"\r\n--{boundary}--\r\n".encode("utf-8")

    body = head + audio_bytes + tail

    req = urllib.request.Request(
        INFERENCE_URL,
        data=body,
        headers={"Content-Type": f"multipart/form-data; boundary={boundary}"},
        method="POST",
    )
    with urllib.request.urlopen(req, timeout=900) as resp:
        resp_body = resp.read().decode("utf-8", errors="replace")
        if resp.status < 200 or resp.status >= 300:
            raise RuntimeError(f"Model HTTP {resp.status}: {resp_body[:300]}")
        return resp_body


def warmup_model():
    print("WARMUP: starting model warmup")

    warmup_path = None
    warmup_id = uuid.uuid4().hex

    try:
        with tempfile.NamedTemporaryFile(
            prefix=f"warmup_{warmup_id}_",
            suffix=".wav",
            delete=False,
        ) as tmp:
            warmup_path = tmp.name

        print(f"WARMUP: creating local test file at {warmup_path}")

        sample_rate = 16000
        duration = 1
        freq = 440.0
        amp = 16000

        with wave.open(warmup_path, "w") as w:
            w.setnchannels(1)
            w.setsampwidth(2)
            w.setframerate(sample_rate)
            for i in range(sample_rate * duration):
                v = int(amp * math.sin(2 * math.pi * freq * i / sample_rate))
                w.writeframes(struct.pack("<h", v))

        attempt = 0
        while True:
            attempt += 1
            try:
                print(f"WARMUP: attempt {attempt}, calling model at {INFERENCE_URL}")
                _ = call_model(warmup_path)
                print("WARMUP: success, result discarded")
                break
            except Exception as e:
                print(f"WARMUP: attempt {attempt} failed: {e}")
                print("WARMUP: waiting 30 seconds before retry")
                time.sleep(30)

    finally:
        if warmup_path:
            try:
                os.remove(warmup_path)
                print(f"WARMUP: deleted local test file {warmup_path}")
            except OSError:
                print(f"WARMUP: failed to delete local test file {warmup_path}")

    print("WARMUP: finished")


def visibility_heartbeat(receipt: str, stop_evt: threading.Event):
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
    print("whisper-worker started")
    print(f"QUEUE_URL={QUEUE_URL}")
    print(f"INFERENCE_URL={INFERENCE_URL}")
    print(f"INPUT_PREFIX={INPUT_PREFIX}")
    print(f"OUTPUT_PREFIX={OUTPUT_PREFIX}")

    warmup_model()

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

        tmp_path = None
        stop_evt = None
        hb = None

        try:
            body = json.loads(msg["Body"])
            bucket = body["bucket"]
            key = urllib.parse.unquote_plus(body["key"])
            print(f"job: s3://{bucket}/{key}")

            stop_evt = threading.Event()
            hb = threading.Thread(target=visibility_heartbeat, args=(receipt, stop_evt), daemon=True)
            hb.start()

            with tempfile.NamedTemporaryFile(
                prefix="whisperx_",
                suffix=os.path.splitext(key)[1] or ".wav",
                delete=False,
            ) as tmp:
                tmp_path = tmp.name

            s3.download_file(bucket, key, tmp_path)

            result_json = call_model(tmp_path)

            plain = plain_text_from_result(result_json)
            out_txt_key = output_key_for(key, "txt")
            s3.put_object(
                Bucket=bucket,
                Key=out_txt_key,
                Body=plain.encode("utf-8"),
                ContentType="text/plain; charset=utf-8",
            )
            print(f"wrote: s3://{bucket}/{out_txt_key}")

            if stop_evt is not None and hb is not None:
                stop_heartbeat(stop_evt, hb)

            sqs.delete_message(QueueUrl=QUEUE_URL, ReceiptHandle=receipt)
            print("deleted message")

        except Exception as e:
            if stop_evt is not None and hb is not None:
                stop_heartbeat(stop_evt, hb)
            print(f"ERROR: {e}")
            time.sleep(2)
            # do not delete message, SQS will retry / DLQ later

        finally:
            if tmp_path:
                try:
                    os.remove(tmp_path)
                except OSError:
                    pass


if __name__ == "__main__":
    main()