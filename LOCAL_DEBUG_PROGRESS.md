# FastGPT Local Debug Progress

Date: 2026-03-13 (Asia/Shanghai)
Workspace: `/Users/zhouangguo/Desktop/兼职/知识库/FastGPT-gary`

## Current Status

- FastGPT dev dependencies were started with Docker (`deploy/dev`).
- `pnpm dev` can start, and web is reachable.
- Two independent issues were identified:
  - `Rspack + zod` runtime compatibility issue on `/config/tool`.
  - AIProxy endpoint protocol mismatch (`https` vs actual `http`) during channel create.

## Issue 1: Rspack + zod Runtime Error (Deferred)

Error:

- `Runtime TypeError: can't access property "object", zod__rspack_import_1.z is undefined`
- Source points to:
  - `packages/global/core/plugin/type.ts`
  - browser chunk: `.next/dev/static/chunks/pages/config/tool.js`

Findings:

- `packages/global/core/plugin/type.ts` uses named import:
  - `import { z } from 'zod'`
- In dev browser chunk, this path is emitted as:
  - `zod__rspack_import_1.z.object(...)`
- In the same app, many other files use default import:
  - `import z from 'zod'`
  - emitted as `zod__rspack_import_x["default"].object(...)`
- This issue is intentionally deferred by user for later handling.

## Issue 2: Channel Create Fails with EPROTO (Active)

UI error:

- `write EPROTO ... SSL routines ... packet length too long ...`

Root cause:

- `projects/app/.env.local` currently sets:
  - `AIPROXY_API_ENDPOINT=https://localhost:3010`
- Local AIProxy service on port `3010` is HTTP in current docker dev setup.
- Calling HTTPS on an HTTP endpoint causes TLS handshake failures and EPROTO.

Verification performed:

- `curl -sv https://localhost:3010/api/status` -> TLS/protocol error
- `curl -sv http://localhost:3010/api/status` -> HTTP 200 success

Conclusion:

- This is not strictly "local deployment must miss certificates".
- It is a protocol mismatch problem:
  - If your endpoint is plain HTTP, use `http://...`.
  - If your endpoint is true HTTPS (with TLS termination), use `https://...`.
- Deployment location (local vs server) is not the direct cause by itself.

## User Action (Planned by User)

User will manually update config.

Recommended change:

- Update `projects/app/.env.local`:
  - `AIPROXY_API_ENDPOINT=http://localhost:3010`
- Restart `pnpm dev` after change.

## MiniMax Notes Collected

- AIProxy `type_metas` reports MiniMax provider defaults:
  - provider: `minimax`
  - default base URL: `https://api.minimax.chat/v1`
  - key format: `api_key|group_id`

