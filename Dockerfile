ARG BASE_IMAGE=ubuntu:20.04

FROM ${BASE_IMAGE} AS dev-base
ENV DEBIAN_FRONTEND=noninteractive
RUN --mount=type=cache,id=apt-dev,target=/var/cache/apt \
    apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        ccache \
        cmake \
        curl \
        git \
        libjpeg-dev \
        libpng-dev && \
    rm -rf /var/lib/apt/lists/*
RUN /usr/sbin/update-ccache-symlinks
RUN mkdir /opt/ccache && ccache --set-config=cache_dir=/opt/ccache
ENV PATH=/opt/conda/bin:$PATH

FROM dev-base AS conda
ARG PYTHON_VERSION=3.10
RUN curl -fsSL -v -o ~/miniconda.sh -O  https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh  && \
    chmod +x ~/miniconda.sh && \
    ~/miniconda.sh -b -p /opt/conda && \
    rm ~/miniconda.sh && \
    /opt/conda/bin/conda install -y python=${PYTHON_VERSION} conda-build pyyaml ipython pip && \
    /opt/conda/bin/pip install numpy==1.22.4 && \
    /opt/conda/bin/conda clean -ya

FROM dev-base AS submodule-update
WORKDIR /opt/pytorch
COPY . .
RUN git submodule update --init --recursive --jobs 0

FROM conda AS build
WORKDIR /opt/pytorch
COPY --from=conda /opt/conda /opt/conda
COPY --from=submodule-update /opt/pytorch /opt/pytorch
RUN --mount=type=cache,target=/opt/ccache \
    TORCH_CUDA_ARCH_LIST="3.5 5.2 6.0 6.1 7.0+PTX 8.0" TORCH_NVCC_FLAGS="-Xfatbin -compress-all" \
    CMAKE_PREFIX_PATH="$(dirname $(which conda))/../" \
    python setup.py install

FROM conda AS conda-installs
ARG CUDA_CHANNEL=nvidia
ARG INSTALL_CHANNEL=pytorch-nightly
ARG CUDA_VERSION=11.3
ENV CONDA_OVERRIDE_CUDA=${CUDA_VERSION}
RUN /opt/conda/bin/conda install -c "${INSTALL_CHANNEL}" -c "${CUDA_CHANNEL}" -y python=${PYTHON_VERSION} pytorch torchvision torchtext "cudatoolkit=${CUDA_VERSION}" && \
    /opt/conda/bin/conda clean -ya
RUN /opt/conda/bin/pip install torchelastic

FROM ${BASE_IMAGE} AS torch
ARG PYTORCH_VERSION=1.12.0
LABEL com.nvidia.volumes.needed="nvidia_driver"
RUN --mount=type=cache,id=apt-final,target=/var/cache/apt \
    apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates \
        libjpeg-dev \
        libpng-dev && \
    rm -rf /var/lib/apt/lists/*
COPY --from=conda-installs /opt/conda /opt/conda
ENV PATH=/opt/conda/bin:$PATH
ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=compute,utility
ENV LD_LIBRARY_PATH=/usr/local/nvidia/lib:/usr/local/nvidia/lib64
ENV PYTORCH_VERSION=${PYTORCH_VERSION}
WORKDIR /workspace
COPY --from=build /opt/conda /opt/conda

FROM torch AS minkowski
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Hong_Kong
RUN apt-get update && \
    apt-get install -y tzdata && \
    ln -fs /usr/share/zoneinfo/$TZ /etc/localtime && \
    echo $TZ > /etc/timezone

# Install additional dependencies for MinkowskiEngine
RUN apt-get update && \
    apt-get install -y \
    git \
    ninja-build \
    cmake \
    build-essential \
    libopenblas-dev \
    xterm \
    xauth \
    openssh-server \
    tmux \
    wget \
    mate-desktop-environment-core && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# # Install MinkowskiEngine
ENV TORCH_CUDA_ARCH_LIST="3.5 5.2 6.0 6.1 7.0+PTX 8.0"
ENV TORCH_NVCC_FLAGS="-Xfatbin -compress-all"
ENV MAX_JOBS=4
RUN git clone --recursive "https://github.com/NVIDIA/MinkowskiEngine"
RUN cd MinkowskiEngine; python setup.py install --force_cuda --blas=openblas

FROM minkowski AS dev
