# Use an official Python runtime as a parent image
FROM python:3.11-slim

# Set the working directory in the container
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    git \
    && rm -rf /var/lib/apt/lists/*

# Copy only the backend and job-pipeline/data (for the DB)
COPY backend/ /app/backend/
COPY job-pipeline/data/ /app/job-pipeline/data/

# Set working directory to backend
WORKDIR /app/backend

# Install python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Pre-download NLP models to speed up startup and avoid runtime downloads
RUN python -m spacy download en_core_web_sm
RUN python -c "import nltk; nltk.download('punkt_tab'); nltk.download('stopwords'); nltk.download('wordnet'); nltk.download('averaged_perceptron_tagger_eng')"

# Expose port 7860 (Hugging Face default)
EXPOSE 7860

# Command to run the application
# We use 0.0.0.0 to bind to all interfaces in the container
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "7860"]
