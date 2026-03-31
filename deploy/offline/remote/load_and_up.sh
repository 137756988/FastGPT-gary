#!/usr/bin/env bash
set -euo pipefail

BUNDLE_DIR="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
COMPOSE_FILE="${BUNDLE_DIR}/docker-compose.pg.yml"
IMAGE_TAR="${BUNDLE_DIR}/images/all-images.tar"
IMAGE_SHA="${BUNDLE_DIR}/images/all-images.tar.sha256"

if [[ ! -f "${COMPOSE_FILE}" ]]; then
  echo "[ERROR] 未找到 compose 文件: ${COMPOSE_FILE}"
  exit 1
fi

if [[ ! -f "${IMAGE_TAR}" ]]; then
  echo "[ERROR] 未找到镜像包: ${IMAGE_TAR}"
  exit 1
fi

echo "==> 校验镜像包"
if [[ -f "${IMAGE_SHA}" ]]; then
  (
    cd "${BUNDLE_DIR}"
    shasum -a 256 -c "images/all-images.tar.sha256"
  )
else
  echo "[WARN] 未找到 sha256 校验文件，跳过校验"
fi

echo "==> 导入镜像"
docker load -i "${IMAGE_TAR}"

echo "==> 启动服务"
docker compose -f "${COMPOSE_FILE}" up -d

echo "==> 服务状态"
docker compose -f "${COMPOSE_FILE}" ps

echo "==> 完成。建议继续执行:"
echo "  docker compose -f ${COMPOSE_FILE} logs -f --tail=100 fastgpt"
