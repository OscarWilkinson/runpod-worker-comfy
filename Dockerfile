# Stage 1: Base image with common dependencies
FROM nvidia/cuda:11.8.0-cudnn8-runtime-ubuntu22.04 as base

# Prevents prompts from packages asking for user input during installation
ENV DEBIAN_FRONTEND=noninteractive
# Prefer binary wheels over source distributions for faster pip installations
ENV PIP_PREFER_BINARY=1
# Ensures output from python is printed immediately to the terminal without buffering
ENV PYTHONUNBUFFERED=1 

# Upgrade apt and install Python, git, and other necessary tools
RUN apt-get update && apt-get install -y --only-upgrade apt
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    git \
    wget

# Clean up to reduce image size
RUN apt-get autoremove -y && apt-get clean -y && rm -rf /var/lib/apt/lists/*

# Clone ComfyUI repository
RUN git clone https://github.com/comfyanonymous/ComfyUI.git /comfyui

# Change working directory to ComfyUI
WORKDIR /comfyui

# Install ComfyUI dependencies
RUN pip3 install --upgrade --no-cache-dir torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121 \
    && pip3 install --upgrade -r requirements.txt

# Install runpod
RUN pip3 install runpod requests

# Support for the network volume
ADD src/extra_model_paths.yaml ./

# Go back to the root
WORKDIR /

# Add the start and the handler
ADD src/start.sh src/rp_handler.py test_input.json ./
RUN chmod +x /start.sh

# Stage 2: Download models
FROM base as downloader

ARG HUGGINGFACE_ACCESS_TOKEN
ARG MODEL_TYPE

# Change working directory to ComfyUI
WORKDIR /comfyui

# Download checkpoints/vae/LoRA to include in image based on model type
RUN wget -O models/checkpoints/fenrisxlFlux_fenrisxlSDXLLightning.safetensors https://civitai.com/api/download/models/370565?type=Model&format=SafeTensor&size=full&fp=fp16
RUN wget -O models/loras/Pencil_Sketch-06R.safetensors https://civitai.com/api/download/models/661566?type=Model&format=SafeTensor
RUN git clone https://github.com/GraftingRayman/ComfyUI_GraftingRayman custom_nodes/ComfyUI_GraftingRayman
RUN git clone https://github.com/pythongosssss/ComfyUI-Custom-Scripts.git custom_nodes/ComfyUI-Custom-Scripts
RUN git clone https://github.com/WASasquatch/was-node-suite-comfyui/ custom_nodes/was-node-suite-comfyui
RUN git clone https://github.com/sipherxyz/comfyui-art-venture/ custom_nodes/comfyui-art-venture


# Stage 3: Final image
FROM base as final

# Copy models from stage 2 to the final image
COPY --from=downloader /comfyui/models /comfyui/models
COPY --from=downloader /comfyui/custom_nodes /comfyui/custom_nodes

# Start the container by specifying the CMD again
CMD ["/start.sh"]