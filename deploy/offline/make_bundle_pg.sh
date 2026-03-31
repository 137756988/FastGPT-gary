#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TAG="$(date +%Y%m%d-%H%M)"
CUSTOM_IMAGE=""
OUTPUT_DIR=""

usage() {
  cat <<'EOF'
用法:
  bash deploy/offline/make_bundle_pg.sh [-t TAG] [-i CUSTOM_IMAGE] [-o OUTPUT_DIR]

参数:
  -t TAG           发布标签，默认当前时间，例如 20260325-1530
  -i CUSTOM_IMAGE  自定义 fastgpt 镜像名，默认 fastgpt-custom:<TAG>
  -o OUTPUT_DIR    输出目录，默认 <repo>/dist/fastgpt-offline-<TAG>

说明:
  1) 本脚本会用当前代码构建 fastgpt 自定义镜像。
  2) 拉取基础依赖镜像并打包成离线 tar。
  3) 生成可直接传云主机的离线部署目录。
EOF
}

while getopts ":t:i:o:h" opt; do
  case "${opt}" in
    t) TAG="${OPTARG}" ;;
    i) CUSTOM_IMAGE="${OPTARG}" ;;
    o) OUTPUT_DIR="${OPTARG}" ;;
    h)
      usage
      exit 0
      ;;
    *)
      usage
      exit 1
      ;;
  esac
done

CUSTOM_IMAGE="${CUSTOM_IMAGE:-fastgpt-custom:${TAG}}"
OUTPUT_DIR="${OUTPUT_DIR:-${ROOT_DIR}/dist/fastgpt-offline-${TAG}}"

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "缺少命令: $1"
    exit 1
  fi
}

require_cmd docker
require_cmd awk
require_cmd sed
require_cmd tar

BASE_IMAGE_LIST_FILE="${ROOT_DIR}/deploy/offline/images.pg.base.txt"
COMPOSE_SRC="${ROOT_DIR}/deploy/docker/global/docker-compose.pg.yml"
COMPOSE_DST="${OUTPUT_DIR}/docker-compose.pg.yml"
CONFIG_SRC="${ROOT_DIR}/projects/app/data/config.json"
CONFIG_DST="${OUTPUT_DIR}/config.json"
SCRIPTS_SRC_DIR="${ROOT_DIR}/deploy/offline/remote"
SCRIPTS_DST_DIR="${OUTPUT_DIR}/scripts"
IMAGES_DIR="${OUTPUT_DIR}/images"
ALL_IMAGES_TAR="${IMAGES_DIR}/all-images.tar"
ALL_IMAGES_SHA="${IMAGES_DIR}/all-images.tar.sha256"
BUNDLE_TGZ="${OUTPUT_DIR}.tgz"

mkdir -p "${OUTPUT_DIR}" "${SCRIPTS_DST_DIR}" "${IMAGES_DIR}"

echo "==> [1/6] 构建自定义 fastgpt 镜像: ${CUSTOM_IMAGE}"
docker build -f "${ROOT_DIR}/projects/app/Dockerfile" -t "${CUSTOM_IMAGE}" "${ROOT_DIR}"

echo "==> [2/6] 生成 compose/config/scripts"
sed "s#image: ghcr.io/labring/fastgpt:[^ ]*#image: ${CUSTOM_IMAGE}#" "${COMPOSE_SRC}" > "${COMPOSE_DST}"
cp "${CONFIG_SRC}" "${CONFIG_DST}"
cp "${SCRIPTS_SRC_DIR}"/*.sh "${SCRIPTS_DST_DIR}/"
cp "${ROOT_DIR}/deploy/offline/README.zh-CN.md" "${OUTPUT_DIR}/README.zh-CN.md"
cp "${BASE_IMAGE_LIST_FILE}" "${OUTPUT_DIR}/images.pg.base.txt"

echo "==> [3/6] 拉取基础镜像"
mapfile -t BASE_IMAGES < <(awk 'NF && $1 !~ /^#/' "${BASE_IMAGE_LIST_FILE}")
for image in "${BASE_IMAGES[@]}"; do
  echo "pull: ${image}"
  docker pull "${image}"
done

echo "==> [4/6] 保存离线镜像包"
docker save -o "${ALL_IMAGES_TAR}" "${CUSTOM_IMAGE}" "${BASE_IMAGES[@]}"

echo "==> [5/6] 生成校验和"
(
  cd "${OUTPUT_DIR}"
  shasum -a 256 "images/all-images.tar" > "${ALL_IMAGES_SHA##${OUTPUT_DIR}/}"
)

echo "==> [6/6] 打包分发文件"
tar -C "$(dirname "${OUTPUT_DIR}")" -czf "${BUNDLE_TGZ}" "$(basename "${OUTPUT_DIR}")"

echo
echo "离线包已生成:"
echo "  目录: ${OUTPUT_DIR}"
echo "  压缩包: ${BUNDLE_TGZ}"
echo
echo "下一步:"
echo "  1) 将 ${BUNDLE_TGZ} 通过跳板机/VPN 传到云主机"
echo "  2) 在云主机解压后执行 scripts/check_host.sh"
echo "  3) 再执行 scripts/load_and_up.sh"
