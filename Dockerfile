FROM timpietruskyblibla/runpod-worker-comfy:3.1.0-base as base

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

WORKDIR /comfyui

RUN pip3 install --no-cache-dir torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118

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

# Install dependencies for custom nodes
RUN pip3 install -r custom_nodes/ComfyUI_GraftingRayman/requirements.txt
RUN pip3 install -r custom_nodes/was-node-suite-comfyui/requirements.txt
RUN pip3 install -r custom_nodes/comfyui-art-venture/requirements.txt

WORKDIR /

# Start the container
CMD /start.sh