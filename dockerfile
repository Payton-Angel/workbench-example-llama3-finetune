# ===== Base image: CUDA 13.0 + PyTorch =====
# Pick a recent PyTorch image that ships with CUDA 13.0
# (25.01 and newer tags are CUDA 13.0 based)
FROM nvcr.io/nvidia/pytorch:25.01-py3

# Non-interactive apt and sane Python/pip defaults
ENV DEBIAN_FRONTEND=noninteractive \
    PIP_NO_CACHE_DIR=1 \
    PIP_DEFAULT_TIMEOUT=60 \
    PYTHONUNBUFFERED=1

# Optional but useful system packages (add/remove as needed)
# build-essential/python3-dev: compile native wheels when required
# git: pull private repos
# ffmpeg, libgl1: common runtime deps (opencv, media)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential python3-dev git ffmpeg libgl1 && \
    rm -rf /var/lib/apt/lists/*

# Project working directory inside the container
WORKDIR /opt/project

# ---- Python dependencies ----
# Ensure requirements.txt is present inside the image BEFORE installing
# Adjust the left-hand path if your repo uses a different location.
COPY build/requirements.txt /opt/project/build/requirements.txt

# Keep pip toolchain fresh, then install deps system-wide (no --user)
RUN python3 -m pip install --upgrade pip setuptools wheel && \
    python3 -m pip install --no-cache-dir -r /opt/project/build/requirements.txt

# ---- Project source ----
# Copy the rest of your project last, so code changes don’t bust the pip cache layer
COPY . /opt/project

# (Optional) common cache locations for model hubs; uncomment if you want them inside the project
# ENV HF_HOME=/opt/project/.cache/huggingface \
#     TRANSFORMERS_CACHE=/opt/project/.cache/huggingface/transformers \
#     TORCH_HOME=/opt/project/.cache/torch

# Workbench will inject your secrets at runtime (don’t bake them into the image):
#   NVIDIA_API_KEY
#   HUGGING_FACE_HUB_TOKEN
#   (anything else you configured in Project Settings → Environment)

# Default to an interactive shell; Workbench overrides as needed
CMD ["/bin/bash"]
