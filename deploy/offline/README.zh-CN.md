# FastGPT 离线部署 SOP（跳板机/VPN 场景）

本目录用于“本地有源码改动，目标云主机无公网”的部署方式。

## 1. 部署思路
- 在本地开发机构建 `fastgpt` 自定义镜像。
- 拉取其余依赖镜像并打成离线包。
- 通过 VPN + 跳板机把离线包传到目标机。
- 在目标机导入镜像并 `docker compose up -d` 启动。

## 2. 目标机前置条件
- 操作系统建议：`Ubuntu 24.04 LTS`（你当前环境最兼容）。
- 已安装并可用：
  - Docker Engine
  - Docker Compose 插件（`docker compose`）
- 若目标机完全离线，需提前准备 Docker 安装包（同系统版本、同架构）。

## 3. 本地打包（首次上线）
在仓库根目录执行：

```bash
bash deploy/offline/make_bundle_pg.sh
```

执行后会生成：
- `dist/fastgpt-offline-<tag>/`（离线目录）
- `dist/fastgpt-offline-<tag>.tgz`（可传输压缩包）

离线目录包含：
- `docker-compose.pg.yml`（已替换为本地构建的 fastgpt 镜像）
- `config.json`
- `images/all-images.tar`（全量镜像包）
- `scripts/*.sh`（目标机运维脚本）

## 4. 通过跳板机传输
示例（按你实际账号/IP 修改）：

```bash
scp -o ProxyJump=<jump_user>@<jump_host> dist/fastgpt-offline-<tag>.tgz <target_user>@<target_host>:/opt/fastgpt/
```

## 5. 目标机启动
在目标机执行：

```bash
cd /opt/fastgpt
tar -xzf fastgpt-offline-<tag>.tgz
cd fastgpt-offline-<tag>
bash scripts/check_host.sh
bash scripts/load_and_up.sh
```

验证：
- `docker compose -f docker-compose.pg.yml ps`
- `docker compose -f docker-compose.pg.yml logs --tail=100 fastgpt`

## 6. 后续更新（推荐增量发布）
你的代码变更后：
1. 本地执行增量导出脚本（自动构建 + 导出）：

```bash
bash deploy/offline/export_fastgpt_incremental.sh
```

2. 将生成的 `dist/fastgpt-only-<tag>.tar` 传到目标机离线目录 `images/fastgpt-only.tar`。
3. 执行：

```bash
bash scripts/update_fastgpt.sh
```

## 7. 数据备份与知识库迁移
- 目标机可随时执行：

```bash
bash scripts/backup_data.sh
```

- 该脚本会备份：
  - Mongo（业务主数据）
  - PG Vector（向量数据）
  - MinIO 持久化目录（文件原件）
- 不建议直接拷贝数据库底层文件做迁移，优先使用逻辑备份/恢复。

## 8. 关键注意事项
- `config.json` 是容器挂载文件，和镜像解耦；改配置可单独发。
- `DEFAULT_ROOT_PSW/TOKEN_KEY/...` 等关键环境变量务必上线前改掉默认值。
- 如果只给内网使用，`FE_DOMAIN` 建议填内网可访问域名或固定 IP。
