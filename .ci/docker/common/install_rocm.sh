#!/bin/bash
# Script to install ROCm (Radeon Open Compute) for AMD GPU support
# This script is used during Docker image builds for ROCm-enabled PyTorch

set -ex

# ROCm version to install
ROCM_VERSION=${1:-"5.7"}

# Derive the full version string components
ROCM_MAJOR=$(echo "${ROCM_VERSION}" | cut -d. -f1)
ROCM_MINOR=$(echo "${ROCM_VERSION}" | cut -d. -f2)

echo "Installing ROCm ${ROCM_VERSION} (${ROCM_MAJOR}.${ROCM_MINOR})"

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS_ID=${ID}
    OS_VERSION=${VERSION_ID}
else
    echo "Cannot detect OS. Exiting."
    exit 1
fi

install_rocm_ubuntu() {
    local ubuntu_version=$(echo "${OS_VERSION}" | tr -d '.')

    # Install prerequisites
    apt-get update -y
    apt-get install -y --no-install-recommends \
        curl \
        gnupg2 \
        wget \
        ca-certificates

    # Add ROCm repository
    local rocm_repo_url="https://repo.radeon.com/rocm/apt/${ROCM_VERSION}"
    local codename=$(lsb_release -cs 2>/dev/null || echo "jammy")

    wget -qO - https://repo.radeon.com/rocm/rocm.gpg.key | \
        gpg --dearmor > /etc/apt/trusted.gpg.d/rocm.gpg

    echo "deb [arch=amd64] ${rocm_repo_url} ${codename} main" > \
        /etc/apt/sources.list.d/rocm.list

    # Also add amdgpu repo for kernel drivers
    echo "deb [arch=amd64] https://repo.radeon.com/amdgpu/latest/ubuntu ${codename} main" > \
        /etc/apt/sources.list.d/amdgpu.list

    apt-get update -y

    # Install ROCm packages
    apt-get install -y --no-install-recommends \
        rocm-dev \
        rocm-libs \
        rocm-hip-sdk \
        hipblas \
        hipcub-dev \
        hipfft \
        hipsparse \
        miopen-hip \
        rccl \
        rocblas \
        rocfft \
        rocprim-dev \
        rocrand \
        rocsolver \
        rocsparse \
        rocthrust-dev

    # Clean up
    apt-get clean
    rm -rf /var/lib/apt/lists/*
}

install_rocm_almalinux() {
    # Install prerequisites
    dnf install -y \
        curl \
        wget \
        gnupg2

    # Add ROCm repository
    local os_major=$(echo "${OS_VERSION}" | cut -d. -f1)
    local repo_url="https://repo.radeon.com/rocm/rhel${os_major}/${ROCM_VERSION}/main"

    cat > /etc/yum.repos.d/rocm.repo << EOF
[ROCm-${ROCM_VERSION}]
name=ROCm${ROCM_VERSION}
baseurl=${repo_url}
enabled=1
priority=50
gpgcheck=1
gpgkey=https://repo.radeon.com/rocm/rocm.gpg.key
EOF

    dnf clean all

    # Install ROCm packages
    dnf install -y \
        rocm-dev \
        rocm-libs \
        hipblas \
        hipfft \
        hipsparse \
        miopen-hip \
        rccl \
        rocblas \
        rocfft \
        rocrand \
        rocsolver \
        rocsparse

    dnf clean all
}

# Set up ROCm environment variables
setup_rocm_env() {
    local rocm_path="/opt/rocm-${ROCM_VERSION}"
    if [ ! -d "${rocm_path}" ]; then
        rocm_path="/opt/rocm"
    fi

    cat >> /etc/environment << EOF
ROCM_PATH=${rocm_path}
HIP_PATH=${rocm_path}
PATH=${rocm_path}/bin:${rocm_path}/hip/bin:\$PATH
LD_LIBRARY_PATH=${rocm_path}/lib:${rocm_path}/lib64:\$LD_LIBRARY_PATH
EOF

    echo "ROCm environment configured at ${rocm_path}"
}

# Main installation logic
case "${OS_ID}" in
    ubuntu)
        install_rocm_ubuntu
        ;;
    almalinux|rhel|centos)
        install_rocm_almalinux
        ;;
    *)
        echo "Unsupported OS: ${OS_ID}"
        exit 1
        ;;
esac

setup_rocm_env

echo "ROCm ${ROCM_VERSION} installation complete."
