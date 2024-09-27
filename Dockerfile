# Stage 1: Base image
FROM nvidia/cuda:11.8.0-cudnn8-runtime-ubuntu22.04 AS base

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV PIP_PREFER_BINARY=1
ENV PYTHONUNBUFFERED=1

# Install dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    python3-dev \
    build-essential \
    git \
    wget \
    curl \
 && rm -rf /var/lib/apt/lists/*

# Stage 2: Build dependencies and download models
FROM base AS downloader

# Clone ComfyUI repository
RUN git clone https://github.com/comfyanonymous/ComfyUI.git /comfyui

WORKDIR /comfyui

# Download models and custom nodes
RUN mkdir -p models/checkpoints models/loras

# Download checkpoints
RUN curl -L -o models/checkpoints/fenrisxlFlux_fenrisxlSDXLLightning.safetensors \
    "https://civitai.com/api/download/models/370565?type=Model&format=SafeTensor&size=full&fp=fp16" \
 && ls -l models/checkpoints/

# Download LoRA
RUN curl -L -o models/loras/Pencil_Sketch-06R.safetensors \
    "https://civitai.com/api/download/models/661566?type=Model&format=SafeTensor" \
 && ls -l models/loras/

# Clone custom nodes
RUN git clone https://github.com/GraftingRayman/ComfyUI_GraftingRayman custom_nodes/ComfyUI_GraftingRayman
RUN git clone https://github.com/pythongosssss/ComfyUI-Custom-Scripts.git custom_nodes/ComfyUI-Custom-Scripts
RUN git clone https://github.com/WASasquatch/was-node-suite-comfyui/ custom_nodes/was-node-suite-comfyui
RUN git clone https://github.com/sipherxyz/comfyui-art-venture/ custom_nodes/comfyui-art-venture

# Add extra model paths
ADD src/extra_model_paths.yaml ./

# Add scripts and set permissions
WORKDIR /
ADD src/start.sh src/rp_handler.py test_input.json ./
RUN chmod +x /start.sh

# Stage 3: Final image
FROM base

# Copy ComfyUI from downloader stage
COPY --from=downloader /comfyui /comfyui
COPY --from=downloader /start.sh /start.sh
COPY --from=downloader /rp_handler.py /rp_handler.py
COPY --from=downloader /test_input.json /test_input.json

# Set working directory
WORKDIR /comfyui

# Install dependencies
RUN pip3 install --upgrade --no-cache-dir torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121 \
    && pip3 install --upgrade -r requirements.txt

# Install runpod and requests
RUN pip3 install runpod requests

# Install dependencies for custom nodes
RUN pip3 install -r custom_nodes/ComfyUI_GraftingRayman/requirements.txt
RUN pip3 install -r custom_nodes/was-node-suite-comfyui/requirements.txt
RUN pip3 install -r custom_nodes/comfyui-art-venture/requirements.txt

# Ensure start.sh is executable
RUN chmod +x /start.sh

# Reset ENTRYPOINT
ENTRYPOINT []

# Set CMD
CMD ["/start.sh"]