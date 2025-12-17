# Chuck Norris Jokes Application
# Simple Python Alpine container - Cloud Run handles proxying

FROM python:3.12-alpine

# Create app directory
WORKDIR /app

# Copy requirements first for better layer caching
COPY requirements.txt .

# Install Python dependencies with SSL verification disabled for proxy environments
RUN pip install --no-cache-dir --trusted-host pypi.org --trusted-host files.pythonhosted.org -r requirements.txt

# Copy application code
COPY app.py .
COPY templates/ templates/

# Expose port 8000 for Gunicorn (HTTP only, SSL at LB)
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
   CMD wget --no-verbose --tries=1 --spider http://localhost:8000/health || exit 1

# Run Gunicorn directly
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "--workers", "2", "--threads", "2", "--timeout", "30", "--access-logfile", "-", "app:app"]
