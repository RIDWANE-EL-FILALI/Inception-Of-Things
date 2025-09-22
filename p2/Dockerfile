FROM python:3.11-slim

WORKDIR /app
COPY app.py .

# Install dependencies
RUN pip install flask psutil

# Expose the container port
EXPOSE 5000

CMD ["python", "app.py"]
