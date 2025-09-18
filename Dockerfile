# Use Python image
FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Copy frontend files
COPY . /app

# Expose port
EXPOSE 5000

# Run simple HTTP server
CMD ["python", "-m", "http.server", "5000", "--bind", "0.0.0.0"]
