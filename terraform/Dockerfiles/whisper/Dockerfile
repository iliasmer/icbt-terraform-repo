FROM python:3.11-slim
RUN pip install --no-cache-dir boto3

WORKDIR /app
COPY lambda_files/whisper_worker.py /app/worker.py

CMD ["python", "/app/worker.py"]
