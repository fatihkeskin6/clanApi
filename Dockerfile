FROM python:3.11-slim

WORKDIR /app

# Install deps first (cache-friendly)
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy source
COPY . .

# Cloud Run uses PORT env var (usually 8080)
ENV PORT=8080

# Start API
CMD ["sh", "-c", "uvicorn app.main:app --host 0.0.0.0 --port ${PORT}"]
