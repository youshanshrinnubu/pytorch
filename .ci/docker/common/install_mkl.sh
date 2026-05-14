#!/bin/bash
# Script to install Intel MKL (Math Kernel Library) for PyTorch builds
# Supports both Ubuntu/Debian and AlmaLinux/RHEL-based systems

set -ex

# MKL version to install
MKL_VERSION=${MKL_VERSION:-"2024.0"}

# Detect OS type
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS_ID=$ID
else
    echo "Cannot detect OS type"
    exit 1
fi

install_mkl_ubuntu() {
    echo "Installing MKL on Ubuntu/Debian..."

    # Add Intel repository GPG key
    curl -fsSL https://apt.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS.PUB \
        | gpg --dearmor -o /usr/share/keyrings/intel-sw-products.gpg

    # Add Intel oneAPI repository
    echo "deb [signed-by=/usr/share/keyrings/intel-sw-products.gpg] https://apt.repos.intel.com/oneapi all main" \
        > /etc/apt/sources.list.d/intel-oneapi.list

    apt-get update

    # Install MKL development packages
    apt-get install -y --no-install-recommends \
        intel-oneapi-mkl-devel-${MKL_VERSION} \
        || apt-get install -y --no-install-recommends intel-mkl-full

    # Clean up apt cache
    apt-get clean
    rm -rf /var/lib/apt/lists/*
}

install_mkl_almalinux() {
    echo "Installing MKL on AlmaLinux/RHEL..."

    # Add Intel oneAPI repository
    tee /etc/yum.repos.d/intel-oneapi.repo <<EOF
[oneAPI]
name=Intel® oneAPI repository
baseurl=https://yum.repos.intel.com/oneapi
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://yum.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS.PUB
EOF

    # Install MKL development packages
    yum install -y \
        intel-oneapi-mkl-devel-${MKL_VERSION} \
        || yum install -y intel-mkl

    # Clean up yum cache
    yum clean all
    rm -rf /var/cache/yum
}

configure_mkl_env() {
    echo "Configuring MKL environment variables..."

    # Set MKL threading layer to GNU for compatibility with PyTorch
    echo "export MKL_THREADING_LAYER=GNU" >> /etc/environment
    echo "export MKL_INTERFACE_LAYER=LP64" >> /etc/environment

    # Add MKL libraries to ldconfig
    MKL_LIB_PATHS=(
        "/opt/intel/oneapi/mkl/latest/lib/intel64"
        "/opt/intel/mkl/lib/intel64"
        "/usr/lib/x86_64-linux-gnu"
    )

    for lib_path in "${MKL_LIB_PATHS[@]}"; do
        if [ -d "$lib_path" ]; then
            echo "$lib_path" >> /etc/ld.so.conf.d/intel-mkl.conf
        fi
    done

    ldconfig
    echo "MKL environment configuration complete."
}

verify_mkl_installation() {
    echo "Verifying MKL installation..."

    # Check for MKL include files
    MKL_INCLUDE_PATHS=(
        "/opt/intel/oneapi/mkl/latest/include"
        "/opt/intel/mkl/include"
        "/usr/include/mkl"
    )

    for inc_path in "${MKL_INCLUDE_PATHS[@]}"; do
        if [ -f "${inc_path}/mkl.h" ]; then
            echo "MKL headers found at: ${inc_path}"
            return 0
        fi
    done

    echo "WARNING: MKL headers not found. Build may fall back to OpenBLAS."
    return 1
}

# Main installation logic
case "$OS_ID" in
    ubuntu|debian)
        install_mkl_ubuntu
        ;;
    almalinux|rhel|centos|fedora)
        install_mkl_almalinux
        ;;
    *)
        echo "Unsupported OS: $OS_ID. Skipping MKL installation."
        exit 0
        ;;
esac

configure_mkl_env
verify_mkl_installation

echo "MKL installation finished successfully."
