#!/bin/bash
# Script to install base dependencies common to all Docker images
# This is sourced by both ubuntu/build.sh and almalinux/build.sh

set -ex

# Determine the OS and package manager
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS_NAME=$ID
else
    echo "Cannot determine OS type"
    exit 1
fi

install_ubuntu_packages() {
    apt-get update
    apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        ccache \
        cmake \
        curl \
        git \
        libjpeg-dev \
        libpng-dev \
        sudo \
        wget \
        unzip \
        vim \
        ninja-build \
        pkg-config \
        libssl-dev \
        python3-dev \
        python3-pip \
        python3-setuptools \
        python3-wheel
    rm -rf /var/lib/apt/lists/*
}

install_almalinux_packages() {
    dnf update -y
    dnf install -y \
        bzip2 \
        ca-certificates \
        cmake \
        curl \
        gcc \
        gcc-c++ \
        git \
        libjpeg-devel \
        libpng-devel \
        make \
        openssl-devel \
        python3-devel \
        python3-pip \
        sudo \
        unzip \
        wget \
        vim \
        ninja-build \
        pkgconfig
    dnf clean all
}

# Install packages based on OS
case "$OS_NAME" in
    ubuntu)
        echo "Installing packages for Ubuntu..."
        install_ubuntu_packages
        ;;
    almalinux|rhel|centos)
        echo "Installing packages for AlmaLinux/RHEL..."
        install_almalinux_packages
        ;;
    *)
        echo "Unsupported OS: $OS_NAME"
        exit 1
        ;;
esac

# Setup ccache
if command -v ccache &> /dev/null; then
    echo "Configuring ccache..."
    ccache --max-size 25Gi
    ccache --set-config=compression=true
fi

# Upgrade pip
python3 -m pip install --upgrade pip

# Install common Python build dependencies
python3 -m pip install --no-cache-dir \
    numpy \
    pyyaml \
    typing_extensions \
    requests \
    six

echo "Base installation complete."
