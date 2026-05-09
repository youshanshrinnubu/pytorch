#!/bin/bash
# Script to install CUDA and related libraries in Docker containers
# Supports multiple CUDA versions for PyTorch CI builds

set -ex

# Function to install CUDA on Ubuntu-based systems
install_cuda_ubuntu() {
    local cuda_version="$1"
    local ubuntu_version="$2"

    echo "Installing CUDA ${cuda_version} on Ubuntu ${ubuntu_version}"

    # Map CUDA version to keyring package
    local cuda_major
    local cuda_minor
    cuda_major=$(echo "${cuda_version}" | cut -d. -f1)
    cuda_minor=$(echo "${cuda_version}" | cut -d. -f2)

    local distro="ubuntu${ubuntu_version//./}"
    local arch
    arch=$(uname -m)

    # Download and install the CUDA keyring
    local keyring_url="https://developer.download.nvidia.com/compute/cuda/repos/${distro}/${arch}/cuda-keyring_1.1-1_all.deb"
    wget -q "${keyring_url}" -O /tmp/cuda-keyring.deb
    dpkg -i /tmp/cuda-keyring.deb
    rm -f /tmp/cuda-keyring.deb

    apt-get update -q

    # Install CUDA toolkit (without driver)
    local cuda_pkg="cuda-toolkit-${cuda_major}-${cuda_minor}"
    apt-get install -y --no-install-recommends \
        "${cuda_pkg}" \
        "libcudnn8" \
        "libcudnn8-dev" \
        "libcublas-${cuda_major}-${cuda_minor}" \
        "libcublas-dev-${cuda_major}-${cuda_minor}"

    apt-get clean
    rm -rf /var/lib/apt/lists/*
}

# Function to install CUDA on AlmaLinux/RHEL-based systems
install_cuda_almalinux() {
    local cuda_version="$1"
    local rhel_version="$2"

    echo "Installing CUDA ${cuda_version} on AlmaLinux/RHEL ${rhel_version}"

    local cuda_major
    local cuda_minor
    cuda_major=$(echo "${cuda_version}" | cut -d. -f1)
    cuda_minor=$(echo "${cuda_version}" | cut -d. -f2)

    local arch
    arch=$(uname -m)
    local distro="rhel${rhel_version}"

    # Install CUDA repository
    local repo_url="https://developer.download.nvidia.com/compute/cuda/repos/${distro}/${arch}/cuda-${distro}.repo"
    dnf config-manager --add-repo "${repo_url}"

    # Install CUDA toolkit
    local cuda_pkg="cuda-toolkit-${cuda_major}-${cuda_minor}"
    dnf install -y \
        "${cuda_pkg}" \
        "libcudnn8" \
        "libcudnn8-devel"

    dnf clean all
}

# Set CUDA environment variables
setup_cuda_env() {
    local cuda_version="$1"
    local cuda_major
    cuda_major=$(echo "${cuda_version}" | cut -d. -f1)
    local cuda_minor
    cuda_minor=$(echo "${cuda_version}" | cut -d. -f2)

    local cuda_home="/usr/local/cuda-${cuda_major}.${cuda_minor}"

    # Write environment variables to profile
    cat >> /etc/environment <<EOF
CUDA_HOME=${cuda_home}
CUDA_PATH=${cuda_home}
PATH=${cuda_home}/bin:\$PATH
LD_LIBRARY_PATH=${cuda_home}/lib64:\$LD_LIBRARY_PATH
EOF

    # Create symlink for convenience
    ln -sfn "${cuda_home}" /usr/local/cuda

    echo "CUDA environment configured: CUDA_HOME=${cuda_home}"
}

# Main entrypoint
main() {
    if [ $# -lt 1 ]; then
        echo "Usage: $0 <cuda_version> [os_type] [os_version]"
        echo "  cuda_version: e.g. 11.8, 12.1, 12.4"
        echo "  os_type: ubuntu (default) or almalinux"
        echo "  os_version: e.g. 20.04 for Ubuntu, 8 for AlmaLinux"
        exit 1
    fi

    local cuda_version="$1"
    local os_type="${2:-ubuntu}"
    local os_version="${3:-22.04}"

    case "${os_type}" in
        ubuntu)
            install_cuda_ubuntu "${cuda_version}" "${os_version}"
            ;;
        almalinux|rhel)
            install_cuda_almalinux "${cuda_version}" "${os_version}"
            ;;
        *)
            echo "Unsupported OS type: ${os_type}"
            exit 1
            ;;
    esac

    setup_cuda_env "${cuda_version}"
    echo "CUDA ${cuda_version} installation complete."
}

main "$@"
