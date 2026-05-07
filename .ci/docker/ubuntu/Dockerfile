# Ubuntu-based Docker image for PyTorch CI builds
# Supports multiple Ubuntu versions via build args

ARG UBUNTU_VERSION=20.04
FROM ubuntu:${UBUNTU_VERSION}

ARG UBUNTU_VERSION=20.04
ARG CUDA_VERSION=""
ARG CUDNN_VERSION=""
ARG PYTHON_VERSION=3.8
ARG CMAKE_VERSION=3.22.1
ARG GCC_VERSION=9

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=America/Los_Angeles

# Install base system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    gnupg2 \
    software-properties-common \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Install build tools and development libraries
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    cmake \
    gcc-${GCC_VERSION} \
    g++-${GCC_VERSION} \
    git \
    libssl-dev \
    libffi-dev \
    libopenblas-dev \
    libblas-dev \
    liblapack-dev \
    libgflags-dev \
    libgtest-dev \
    libprotobuf-dev \
    protobuf-compiler \
    ninja-build \
    pkg-config \
    unzip \
    vim \
    zip \
    zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

# Set GCC alternatives
RUN update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-${GCC_VERSION} 100 \
    && update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-${GCC_VERSION} 100

# Install Python
RUN add-apt-repository ppa:deadsnakes/ppa -y && \
    apt-get update && apt-get install -y --no-install-recommends \
    python${PYTHON_VERSION} \
    python${PYTHON_VERSION}-dev \
    python${PYTHON_VERSION}-distutils \
    && rm -rf /var/lib/apt/lists/*

# Set Python as default
RUN update-alternatives --install /usr/bin/python python /usr/bin/python${PYTHON_VERSION} 100 && \
    update-alternatives --install /usr/bin/python3 python3 /usr/bin/python${PYTHON_VERSION} 100

# Install pip
RUN curl -sS https://bootstrap.pypa.io/get-pip.py | python${PYTHON_VERSION}

# Upgrade pip and install common Python build dependencies
RUN pip install --upgrade pip setuptools wheel && \
    pip install \
    numpy \
    pyyaml \
    typing_extensions \
    requests \
    six \
    future \
    hypothesis \
    pytest \
    pytest-xdist

# Install newer CMake if needed
RUN CMAKE_ARCH=$(uname -m) && \
    wget -q "https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-linux-${CMAKE_ARCH}.sh" \
        -O /tmp/cmake-install.sh && \
    chmod +x /tmp/cmake-install.sh && \
    /tmp/cmake-install.sh --skip-license --prefix=/usr/local && \
    rm /tmp/cmake-install.sh

# Set up working directory
WORKDIR /workspace

# Copy and run common setup script if it exists
COPY ./common /workspace/common

# Environment variables for builds
ENV PATH=/usr/local/bin:${PATH}
ENV CC=/usr/bin/gcc
ENV CXX=/usr/bin/g++

# Default command
CMD ["/bin/bash"]
