#!/bin/bash
# Script to build Ubuntu Docker images for PyTorch CI
# Usage: ./build.sh [options]
#   -i, --image    Image name (default: pytorch-ubuntu)
#   -t, --tag      Image tag (default: latest)
#   -p, --push     Push image to registry after build

set -eou pipefail

CURRENT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROOT_DIR=$(cd "$CURRENT_DIR/../../.." && pwd)

# Default values
IMAGE_NAME="pytorch-ubuntu"
IMAGE_TAG="latest"
PUSH_IMAGE=false
REGISTRY=""

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    -i|--image)
      IMAGE_NAME="$2"
      shift 2
      ;;
    -t|--tag)
      IMAGE_TAG="$2"
      shift 2
      ;;
    -p|--push)
      PUSH_IMAGE=true
      shift
      ;;
    -r|--registry)
      REGISTRY="$2/"
      shift 2
      ;;
    *)
      echo "Unknown argument: $1"
      exit 1
      ;;
  esac
done

FULL_IMAGE_NAME="${REGISTRY}${IMAGE_NAME}:${IMAGE_TAG}"

echo "=================================================="
echo "Building Ubuntu Docker image for PyTorch CI"
echo "Image: ${FULL_IMAGE_NAME}"
echo "=================================================="

# Verify Dockerfile exists
if [[ ! -f "${CURRENT_DIR}/Dockerfile" ]]; then
  echo "ERROR: Dockerfile not found at ${CURRENT_DIR}/Dockerfile"
  exit 1
fi

# Determine build architecture
ARCH=$(uname -m)
echo "Detected architecture: ${ARCH}"

# Build the Docker image
echo "Building Docker image..."
docker build \
  --progress=plain \
  --build-arg "BUILD_ENVIRONMENT=${IMAGE_NAME}" \
  --build-arg "ARCH=${ARCH}" \
  -t "${FULL_IMAGE_NAME}" \
  -f "${CURRENT_DIR}/Dockerfile" \
  "${ROOT_DIR}"

BUILD_EXIT_CODE=$?
if [[ $BUILD_EXIT_CODE -ne 0 ]]; then
  echo "ERROR: Docker build failed with exit code ${BUILD_EXIT_CODE}"
  exit $BUILD_EXIT_CODE
fi

echo "Successfully built image: ${FULL_IMAGE_NAME}"

# Optionally push the image
if [[ "$PUSH_IMAGE" == true ]]; then
  if [[ -z "$REGISTRY" ]]; then
    echo "WARNING: No registry specified. Skipping push."
  else
    echo "Pushing image to registry: ${REGISTRY}"
    docker push "${FULL_IMAGE_NAME}"
    PUSH_EXIT_CODE=$?
    if [[ $PUSH_EXIT_CODE -ne 0 ]]; then
      echo "ERROR: Docker push failed with exit code ${PUSH_EXIT_CODE}"
      exit $PUSH_EXIT_CODE
    fi
    echo "Successfully pushed image: ${FULL_IMAGE_NAME}"
  fi
fi

echo "Done."
