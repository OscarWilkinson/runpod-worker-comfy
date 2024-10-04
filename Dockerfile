FROM oscarwilkinson/runpod-worker-comfy-base:base as base

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

# Create necessary directories
RUN mkdir -p models/loras \
    models/sam2 \
    models/grounding-dino \
    models/upscale_models \
    models/inpaint

# Download LoRA
RUN curl -L -o models/loras/Pencil_Sketch-06R.safetensors \
    "https://civitai.com/api/download/models/661566?type=Model&format=SafeTensor"

# Download Segmentation models & configs
RUN curl -L -o models/sam2/sam2_hiera_large.pt \
    "https://dl.fbaipublicfiles.com/segment_anything_2/072824/sam2_hiera_large.pt"

RUN curl -L -o models/grounding-dino/groundingdino_swint_ogc.pth \
    "https://huggingface.co/ShilongLiu/GroundingDINO/resolve/main/groundingdino_swint_ogc.pth"

RUN curl -L -o models/grounding-dino/GroundingDINO_SwinB.cfg.py \
    "https://huggingface.co/ShilongLiu/GroundingDINO/resolve/main/GroundingDINO_SwinB.cfg.py"

# Download upscale models
RUN curl -L -o models/upscale_models/4xUltrasharp_4xUltrasharpV10.pt \
    "https://civitai.com/api/download/models/125843?type=Model&format=PickleTensor"

# Download inpaint models
RUN curl -L -o models/inpaint/big-lama.pt \
    "https://github.com/Sanster/models/releases/download/add_big_lama/big-lama.pt"


# Clone custom nodes
RUN git clone https://github.com/GraftingRayman/ComfyUI_GraftingRayman custom_nodes/ComfyUI_GraftingRayman
RUN git clone https://github.com/pythongosssss/ComfyUI-Custom-Scripts.git custom_nodes/ComfyUI-Custom-Scripts
RUN git clone https://github.com/WASasquatch/was-node-suite-comfyui/ custom_nodes/was-node-suite-comfyui
RUN git clone https://github.com/sipherxyz/comfyui-art-venture/ custom_nodes/comfyui-art-venture
RUN git clone https://github.com/neverbiasu/ComfyUI-SAM2 custom_nodes/ComfyUI-SAM2
RUN git clone https://github.com/cubiq/ComfyUI_essentials custom_nodes/ComfyUI_essentials
RUN git clone https://github.com/john-mnz/ComfyUI-Inspyrenet-Rembg custom_nodes/ComfyUI-Inspyrenet-Rembg
RUN git clone https://github.com/kijai/ComfyUI-SUPIR custom_nodes/ComfyUI-SUPIR
RUN git clone https://github.com/SherryXieYuchen/ComfyUI-Image-Inpainting custom_nodes/ComfyUI-Image-Inpainting

# Replace with our own files
RUN rm -f custom_nodes/ComfyUI-SAM2/sam2/build_sam.py
RUN rm -f custom_nodes/ComfyUI-SAM2/sam2/utils/transforms.py
RUN rm -f custom_nodes/ComfyUI-SAM2/sam2/modeling/backbones/hieradet.py
ADD src/build_sam.py custom_nodes/ComfyUI-SAM2/sam2/build_sam.py
ADD src/transforms.py custom_nodes/ComfyUI-SAM2/sam2/utils/transforms.py
ADD src/hieradet.py custom_nodes/ComfyUI-SAM2/sam2/modeling/backbones/hieradet.py

# Install dependencies for custom nodes
RUN pip3 install -r custom_nodes/ComfyUI_GraftingRayman/requirements.txt
RUN pip3 install -r custom_nodes/was-node-suite-comfyui/requirements.txt
RUN pip3 install -r custom_nodes/comfyui-art-venture/requirements.txt
RUN pip3 install -r custom_nodes/ComfyUI-SAM2/requirements.txt
RUN pip3 install -r custom_nodes/ComfyUI_essentials/requirements.txt
RUN pip3 install -r custom_nodes/ComfyUI-Inspyrenet-Rembg/requirements.txt
RUN pip3 install -r custom_nodes/ComfyUI-SUPIR/requirements.txt

WORKDIR /

# Swap files with ours
RUN rm -f rp_handler.py
ADD src/rp_handler.py ./

# Start the container
CMD /start.sh