# FastGPT Local Debug Progress

Date: 2026-03-17 (Asia/Shanghai)
Workspace: `/Users/zhouangguo/Desktop/兼职/知识库/FastGPT-gary`

## Summary

- FastGPT local dev dependencies were started from `deploy/dev`.
- `pnpm dev` was brought up successfully after resolving local port conflicts.
- Web app is reachable locally.
- Two main technical issues were identified:
  - `Rspack + zod` runtime compatibility issue on `/config/tool`.
  - AIProxy endpoint protocol mismatch causing channel creation failure.
- Git remote is already correct:
  - `origin -> https://github.com/137756988/FastGPT-gary`
- Current branch:
  - `main`
- Current repository has a single git worktree only:
  - `/Users/zhouangguo/Desktop/兼职/知识库/FastGPT-gary`

## Local Environment Findings

### Port conflict that blocked early startup

Root cause:

- Local services were already occupying FastGPT dev ports.
- Conflicting local processes identified earlier:
  - local PostgreSQL on `5432`
  - local Redis on `6379`
  - local PHP-related process on `9000`

Resolution already taken:

- Stopped local Homebrew services:
  - `postgresql@14`
  - `redis`
  - `php@7.4`

Result:

- `5432`, `6379`, and `9000` were freed and FastGPT local startup could proceed.

## Issue 1: Rspack + zod Runtime Error (Deferred)

Error:

- `Runtime TypeError: can't access property "object", zod__rspack_import_1.z is undefined`
- Seen on page:
  - `/config/tool`

Code location:

- `packages/global/core/plugin/type.ts`
- browser chunk:
  - `.next/dev/static/chunks/pages/config/tool.js`

Findings:

- `packages/global/core/plugin/type.ts` uses named import:
  - `import { z } from 'zod'`
- In the dev browser chunk, this path is emitted as:
  - `zod__rspack_import_1.z.object(...)`
- In the same project, many other files use default import:
  - `import z from 'zod'`
  - emitted as `zod__rspack_import_x["default"].object(...)`
- From the inspected chunks, the failing browser path is specifically the named-import form.

Decision:

- User asked to keep this issue recorded and defer the fix for now.

Possible later workaround to verify:

- Run dev with webpack instead of rspack and compare behavior.

## Issue 2: Channel Create Fails with EPROTO (Active)

UI error:

- `write EPROTO ... SSL routines ... packet length too long ...`

Root cause:

- `projects/app/.env.local` was configured with:
  - `AIPROXY_API_ENDPOINT=https://localhost:3010`
- Local AIProxy on port `3010` is currently serving plain HTTP.
- The app proxy code reads `AIPROXY_API_ENDPOINT` and forwards requests to that target.
- Sending HTTPS to an HTTP service causes TLS/EPROTO handshake failure.

Verification performed:

- `curl -sv https://localhost:3010/api/status` -> failed with TLS/protocol error
- `curl -sv http://localhost:3010/api/status` -> returned HTTP `200`

Conclusion:

- This is not simply "local deployment lacks HTTPS certificates".
- The actual problem is protocol mismatch:
  - use `http://...` when the local service is plain HTTP
  - use `https://...` only when TLS termination is actually present
- Deployment location alone is not the cause.

Recommended user-side config change:

- In `projects/app/.env.local`, change:
  - `AIPROXY_API_ENDPOINT=http://localhost:3010`
- Then restart `pnpm dev`

## MiniMax Notes Collected

Source:

- Read from local AIProxy `type_metas`

Defaults:

- provider: `minimax`
- default base URL: `https://api.minimax.chat/v1`
- key format: `api_key|group_id`

Additional note:

- If using an Anthropic-compatible MiniMax endpoint such as `/anthropic`, the provider/protocol type should match that endpoint choice rather than using the `minimax` type blindly.

## Current Git State

Repository:

- root: `/Users/zhouangguo/Desktop/兼职/知识库/FastGPT-gary`
- branch: `main`
- remote: `origin -> https://github.com/137756988/FastGPT-gary`

Important Codex/Desktop note:

- A previous Codex thread was attached to the parent folder:
  - `/Users/zhouangguo/Desktop/兼职/知识库`
- For correct Git commit/push behavior in Codex desktop, the thread/workspace should be opened on:
  - `/Users/zhouangguo/Desktop/兼职/知识库/FastGPT-gary`

Observed git status at the time of this summary:

- There are staged and modified changes under:
  - `.agents/skills/...`
  - `AGENTS.md`
- This indicates current worktree is dirty and not limited to `LOCAL_DEBUG_PROGRESS.md`.
- Before commit/push in a new thread, inspect `git status` again and decide whether to commit all changes together or only a subset.

## How To Continue In A New Codex Thread

Recommended setup:

- Start a new Codex desktop thread.
- Open workspace directly at:
  - `/Users/zhouangguo/Desktop/兼职/知识库/FastGPT-gary`
- First read this file:
  - `LOCAL_DEBUG_PROGRESS.md`

Recommended first checks in the new thread:

- `pwd`
- `git status --short --branch`
- verify `projects/app/.env.local` value for `AIPROXY_API_ENDPOINT`
- continue from the deferred/failing items above
