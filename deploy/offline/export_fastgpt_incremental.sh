#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TAG="${1:-$(date +%Y%m%d-%H%M)}"
IMAGE_NAME="${2:-fastgpt-custom:${TAG}}"
OUT_FILE="${3:-${ROOT_DIR}/dist/fastgpt-only-${TAG}.tar}"
NODE_IMAGE="${4:-node:20.14.0-alpine}"
PNPM_VERSION="${5:-9.12.2}"
PROXY_ARG="${6:-1}"

mkdir -p "$(dirname "${OUT_FILE}")"

echo "==> 构建 fastgpt 镜像: ${IMAGE_NAME}"
echo "    使用基础镜像: ${NODE_IMAGE}"
echo "    使用 pnpm 版本: ${PNPM_VERSION}"
echo "    使用 proxy 参数: ${PROXY_ARG}"
docker build \
  --build-arg "NODE_IMAGE=${NODE_IMAGE}" \
  --build-arg "PNPM_VERSION=${PNPM_VERSION}" \
  --build-arg "proxy=${PROXY_ARG}" \
  -f "${ROOT_DIR}/projects/app/Dockerfile" \
  -t "${IMAGE_NAME}" \
  "${ROOT_DIR}"

echo "==> 导出增量镜像包: ${OUT_FILE}"
docker save -o "${OUT_FILE}" "${IMAGE_NAME}"

echo "完成。将该 tar 传到目标机后，可执行 scripts/update_fastgpt.sh"
