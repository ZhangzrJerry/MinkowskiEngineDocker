# Define build arguments (with default values matching Minkowski Engine's typical setup)
ARG UBUNTU_VERSION=20.04
ARG CUDA_VERSION=11.3.1
ARG CUDNN_VERSION=8

# Base image with customizable CUDA and cuDNN
FROM nvidia/cuda:${CUDA_VERSION}-cudnn${CUDNN_VERSION}-runtime-ubuntu${UBUNTU_VERSION}

# Set environment variables to avoid interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies (Python 3.8 for Ubuntu 20.04/18.04 compatibility)
RUN apt-get update && apt-get install -y \
    python3.8 \
    python3.8-dev \
    python3-pip \
    git \
    cmake \
    build-essential \
    libopenblas-dev \
    && rm -rf /var/lib/apt/lists/*

# Make Python 3.8 the default
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3.8 1

# Install PyTorch 1.12.0 with matching CUDA support
# Note: CUDA 11.3 → torch==1.12.0+cu113; CUDA 10.2 → torch==1.12.0+cu102
ARG PYTORCH_VERSION=1.12.0
ARG PYTORCH_CUDA=cu113
RUN pip install --no-cache-dir \
    torch==${PYTORCH_VERSION}+${PYTORCH_CUDA} \
    torchvision==0.13.0+${PYTORCH_CUDA} \
    torchaudio==0.12.0 \
    --extra-index-url https://download.pytorch.org/whl/${PYTORCH_CUDA}

# Install Minkowski Engine dependencies
RUN pip install --no-cache-dir \
    numpy==1.21.6 \
    ninja

# Clone and install Minkowski Engine (default: v0.5.4)
ARG MINKOWSKI_VERSION=v0.5.4
RUN git clone https://github.com/NVIDIA/MinkowskiEngine.git && \
    cd MinkowskiEngine && \
    git checkout ${MINKOWSKI_VERSION} && \
    python setup.py install --blas_include_dirs=/usr/include/openblas --force_cuda

# Set the working directory
WORKDIR /workspace
