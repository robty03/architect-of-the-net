FROM python:3.11-slim

WORKDIR /app

COPY cli/requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir -r /app/requirements.txt

COPY cli /app

CMD ["python", "main.py"]