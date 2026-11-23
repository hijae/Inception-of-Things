#!/bin/bash
#
# Installs the kubectl binary.
#
# This script downloads the latest stable kubectl from the official Kubernetes
# release server, verifies its checksum and installs it into /usr/local/bin.
# It includes an idempotency check to skip installation if the binary already
# exists. k3d writes the kubeconfig of the cluster to ~/.kube/config, so no
# further setup is needed for kubectl to reach the cluster.
#
# Usage:
#   ./install_kubectl.sh

set -euo pipefail
source "$(dirname "$0")/libs/utils.sh"

readonly KUBECTL_BASE_URL="https://dl.k8s.io/release"

log_info "Checking kubectl installation status..."
if command -v kubectl >/dev/null 2>&1; then
  log_info "kubectl is already installed. (Skipping installation)"
else
  readonly KUBECTL_VERSION="$(curl -fsSL "${KUBECTL_BASE_URL}/stable.txt")"
  readonly TMP_DIR="$(mktemp -d)"
  trap 'rm -rf "${TMP_DIR}"' EXIT

  log_info "Downloading kubectl ${KUBECTL_VERSION}..."
  curl -fsSL -o "${TMP_DIR}/kubectl" "${KUBECTL_BASE_URL}/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
  curl -fsSL -o "${TMP_DIR}/kubectl.sha256" "${KUBECTL_BASE_URL}/${KUBECTL_VERSION}/bin/linux/amd64/kubectl.sha256"

  log_info "Verifying checksum..."
  echo "$(cat "${TMP_DIR}/kubectl.sha256")  ${TMP_DIR}/kubectl" | sha256sum --check --status

  log_info "Installing kubectl..."
  sudo install -m 0755 "${TMP_DIR}/kubectl" /usr/local/bin/kubectl
fi

if kubectl version --client >/dev/null 2>&1; then
  log_info "kubectl binary is operational. (Health Check PASS)"
else
  log_error "Failed to execute kubectl binary."
  exit 1
fi
