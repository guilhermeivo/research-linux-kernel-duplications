#!/bin/bash
set -e

if [[ -z "$1" ]]; then
  echo "Error: The first argument (\$1) is missing or empty." >&2
  echo "Usage: $0 /folder/path/kernel-linux"
  exit 1
fi

LINUX_KERNEL_DIR=$1

build_and_run() {
  local DISTRO=$1
  local TAG=$2
  local IMAGE_NAME=$3

  echo "Building $IMAGE_NAME ($DISTRO:$TAG)..."

  docker build \
    --build-arg DISTRO=$DISTRO \
    --build-arg TAG=$TAG \
    --build-arg CACHEBUST=$(date +%s) \
    -t $IMAGE_NAME . 2>&1 | tee "logs/build-$DISTRO.log"

  echo "Running $IMAGE_NAME with kernel volume mounted..."
  docker run --rm \
    -v "$LINUX_KERNEL_DIR":/kernel \
    -w /kernel \
    $IMAGE_NAME \
    echo "Container ready" 2>&1 | tee "logs/run-$DISTRO.log"
}

mkdir -p logs

build_and_run ubuntu 22.04 arkanjo-test-ubuntu &
build_and_run debian 12 arkanjo-test-debian &
build_and_run fedora 38 arkanjo-test-fedora &
build_and_run archlinux latest arkanjo-test-archlinux &

wait

echo "All builds finished!"