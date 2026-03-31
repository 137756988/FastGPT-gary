#!/usr/bin/env bash
set -euo pipefail

check_cmd() {
  local cmd="$1"
  if ! command -v "${cmd}" >/dev/null 2>&1; then
    echo "[ERROR] 缺少命令: ${cmd}"
    return 1
  fi
  echo "[OK] ${cmd}: $(command -v "${cmd}")"
}

echo "==> 检查目标机基础环境"
check_cmd docker

if docker compose version >/dev/null 2>&1; then
  echo "[OK] docker compose: $(docker compose version | head -n 1)"
else
  echo "[ERROR] docker compose 不可用，请安装 compose 插件"
  exit 1
fi

echo "==> 检查 docker 服务状态"
if docker info >/dev/null 2>&1; then
  echo "[OK] docker daemon 正常"
else
  echo "[ERROR] docker daemon 不可用，请先启动 docker"
  exit 1
fi

echo "==> 环境检查通过"
