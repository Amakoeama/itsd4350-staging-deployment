FROM python:3.11-slim

WORKDIR /app

#--- Install application dependencies ---
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

#--- Copy Flask application ---
COPY app.py .

#--- Configure staging application ---
ENV APP_ENV=staging
EXPOSE 8000

#--- Start application using Gunicorn ---
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "app:app"]
