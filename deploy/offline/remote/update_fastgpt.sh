#!/usr/bin/env bash
set -euo pipefail

BUNDLE_DIR="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
COMPOSE_FILE="${BUNDLE_DIR}/docker-compose.pg.yml"
FASTGPT_IMAGE_TAR="${2:-${BUNDLE_DIR}/images/fastgpt-only.tar}"

if [[ ! -f "${COMPOSE_FILE}" ]]; then
  echo "[ERROR] 未找到 compose 文件: ${COMPOSE_FILE}"
  exit 1
fi

if [[ ! -f "${FASTGPT_IMAGE_TAR}" ]]; then
  echo "[ERROR] 未找到 fastgpt 镜像包: ${FASTGPT_IMAGE_TAR}"
  echo "提示: 后续增量发布可只传 fastgpt-only.tar"
  exit 1
fi

echo "==> 导入 fastgpt 新镜像"
docker load -i "${FASTGPT_IMAGE_TAR}"

echo "==> 重建 fastgpt 服务"
docker compose -f "${COMPOSE_FILE}" up -d fastgpt

echo "==> 检查 fastgpt 状态"
docker compose -f "${COMPOSE_FILE}" ps fastgpt
docker compose -f "${COMPOSE_FILE}" logs --tail=80 fastgpt
