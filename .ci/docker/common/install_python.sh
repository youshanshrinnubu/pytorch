#!/bin/bash

# Script to install Python and common Python dependencies
# used across different Docker base images (Ubuntu, AlmaLinux, etc.)

set -ex

PYTHON_VERSION=${1:-3.9}

echo "Installing Python ${PYTHON_VERSION}..."

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS_NAME=$ID
else
    OS_NAME="unknown"
fi

install_python_ubuntu() {
    export DEBIAN_FRONTEND=noninteractive

    # Add deadsnakes PPA for multiple Python versions
    apt-get update -q
    apt-get install -y --no-install-recommends \
        software-properties-common \
        gpg-agent

    add-apt-repository -y ppa:deadsnakes/ppa
    apt-get update -q

    apt-get install -y --no-install-recommends \
        python${PYTHON_VERSION} \
        python${PYTHON_VERSION}-dev \
        python${PYTHON_VERSION}-distutils \
        python${PYTHON_VERSION}-venv

    # Set as default python3
    update-alternatives --install /usr/bin/python3 python3 /usr/bin/python${PYTHON_VERSION} 1
    update-alternatives --set python3 /usr/bin/python${PYTHON_VERSION}
    ln -sf /usr/bin/python3 /usr/bin/python

    # Install pip
    curl -sS https://bootstrap.pypa.io/get-pip.py | python${PYTHON_VERSION}
    ln -sf /usr/bin/pip3 /usr/bin/pip

    # Clean up
    apt-get clean
    rm -rf /var/lib/apt/lists/*
}

install_python_almalinux() {
    # Enable EPEL and install Python
    dnf install -y epel-release
    dnf install -y \
        python${PYTHON_VERSION//./} \
        python${PYTHON_VERSION//./}-devel \
        python${PYTHON_VERSION//./}-pip

    # Set as default
    alternatives --set python /usr/bin/python${PYTHON_VERSION}
    alternatives --set python3 /usr/bin/python${PYTHON_VERSION}
    ln -sf /usr/bin/pip${PYTHON_VERSION} /usr/bin/pip
    ln -sf /usr/bin/pip${PYTHON_VERSION} /usr/bin/pip3

    dnf clean all
}

# Install based on OS
case "$OS_NAME" in
    ubuntu)
        install_python_ubuntu
        ;;
    almalinux | rhel | centos)
        install_python_almalinux
        ;;
    *)
        echo "Unsupported OS: $OS_NAME"
        exit 1
        ;;
esac

# Upgrade pip and install common build dependencies
pip install --no-cache-dir --upgrade pip setuptools wheel

# Install common Python packages needed for PyTorch development
pip install --no-cache-dir \
    numpy \
    pyyaml \
    typing_extensions \
    requests \
    six \
    future \
    cmake

echo "Python ${PYTHON_VERSION} installation complete."
python --version
pip --version
