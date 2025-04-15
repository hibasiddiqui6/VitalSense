FROM python:3.11-slim

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Install system dependencies for psycopg2, mysqlclient, and compilation
RUN apt-get update && apt-get install -y \
    libpq-dev \
    default-libmysqlclient-dev \
    gcc \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip && pip install -r requirements.txt

# Copy app source
COPY . .

EXPOSE 8080

CMD gunicorn app:app --bind 0.0.0.0:$PORT --worker-class gevent --timeout 120

