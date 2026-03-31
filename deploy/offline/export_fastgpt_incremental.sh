#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TAG="${1:-$(date +%Y%m%d-%H%M)}"
IMAGE_NAME="${2:-fastgpt-custom:${TAG}}"
OUT_FILE="${3:-${ROOT_DIR}/dist/fastgpt-only-${TAG}.tar}"

mkdir -p "$(dirname "${OUT_FILE}")"

echo "==> 构建 fastgpt 镜像: ${IMAGE_NAME}"
docker build -f "${ROOT_DIR}/projects/app/Dockerfile" -t "${IMAGE_NAME}" "${ROOT_DIR}"

echo "==> 导出增量镜像包: ${OUT_FILE}"
docker save -o "${OUT_FILE}" "${IMAGE_NAME}"

echo "完成。将该 tar 传到目标机后，可执行 scripts/update_fastgpt.sh"
