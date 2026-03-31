#!/usr/bin/env bash
set -euo pipefail

WORK_DIR="${1:-$(pwd)}"
BACKUP_DIR="${2:-${WORK_DIR}/backup-$(date +%Y%m%d-%H%M%S)}"
COMPOSE_FILE="${WORK_DIR}/docker-compose.pg.yml"

if [[ ! -f "${COMPOSE_FILE}" ]]; then
  echo "[ERROR] 请在包含 docker-compose.pg.yml 的目录执行，或传入正确 WORK_DIR"
  exit 1
fi

mkdir -p "${BACKUP_DIR}"

echo "==> 备份 MongoDB"
docker exec mongo mongodump \
  -u myusername \
  -p mypassword \
  --authenticationDatabase admin \
  --archive > "${BACKUP_DIR}/mongo.archive"

echo "==> 备份 PG Vector"
docker exec pg pg_dump -U username -d postgres -Fc > "${BACKUP_DIR}/pg.dump"

echo "==> 备份 MinIO 持久化目录"
if [[ -d "${WORK_DIR}/fastgpt-minio" ]]; then
  tar -C "${WORK_DIR}" -czf "${BACKUP_DIR}/fastgpt-minio-data.tgz" fastgpt-minio
else
  echo "[WARN] 未发现目录 ${WORK_DIR}/fastgpt-minio，跳过 MinIO 文件备份"
fi

echo "==> 备份配置"
cp "${COMPOSE_FILE}" "${BACKUP_DIR}/docker-compose.pg.yml"
if [[ -f "${WORK_DIR}/config.json" ]]; then
  cp "${WORK_DIR}/config.json" "${BACKUP_DIR}/config.json"
fi

echo "==> 完成: ${BACKUP_DIR}"
