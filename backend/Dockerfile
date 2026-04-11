# ─────────────────────────────────────────────────────────────────────────────
# GreenBin Genius – Hugging Face Spaces Dockerfile
#
# Hugging Face Spaces requires:
#   • Port 7860 exposed
#   • Non-root user 'user'
#   • HOME set to /home/user
# ─────────────────────────────────────────────────────────────────────────────

FROM python:3.10-slim

# System dependencies needed by OpenCV / Pillow / ultralytics
RUN apt-get update && apt-get install -y --no-install-recommends \
        libglib2.0-0 \
        libsm6 \
        libxext6 \
        libxrender-dev \
        libgl1-mesa-glx \
        git \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user as required by Hugging Face Spaces
RUN useradd -m -u 1000 user
USER user
ENV HOME=/home/user \
    PATH=/home/user/.local/bin:$PATH

WORKDIR /home/user/app

# Install Python dependencies
COPY --chown=user requirements.txt .
RUN pip install --no-cache-dir --upgrade pip \
 && pip install --no-cache-dir -r requirements.txt

# Copy backend source code
COPY --chown=user . .

# Create the ml/ directory for models
# (models are uploaded separately to the HF Space repo or Model Hub)
RUN mkdir -p ml

# Expose Hugging Face Spaces port
EXPOSE 7860

# Launch FastAPI with uvicorn
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "7860"]
