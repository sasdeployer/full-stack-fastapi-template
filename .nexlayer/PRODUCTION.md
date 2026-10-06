# Nexlayer — how `full-stack-fastapi-template` ships

You were asked to work on or deploy this app. The state below is already
resolved — do not re-derive it from the code. The procedure is not here;
ask Nexlayer for it (see "How to deploy").

## The app

| | |
| --- | --- |
| Name | `full-stack-fastapi-template` |
| Repo | `https://github.com/sasdeployer/full-stack-fastapi-template` on `master` |
| Planned | 2026-10-06T09:17:08.762Z |
| Registered with Nexlayer | yes |

`.nexlayer/plan.lock` pins the commit this plan was written against. If HEAD
has moved and you changed how the app starts, runs, or what it needs,
re-check before deploying.

## The production plan

Written by the Nexlayer agent from this repo. Every decision cites the files it
rests on; if the code has changed since, re-check those files first.

Three services run: a React/Vite single-page app served by nginx, a FastAPI backend on port 8000, and Postgres 18. The browser loads the frontend at / and calls the backend at /api on the same app URL. The backend reaches Postgres at db.pod:5432 and runs database migrations plus initial-user setup before it starts. What matters most for production: the Postgres data must sit on a volume, and the frontend must be built with VITE_API_URL set to the app's public URL, because that value is baked in at build time.

- **services: Keep three services: frontend, backend and db. Drop adminer (a database admin UI), the Traefik proxy/traefik services and Mailcatcher. Run the one-shot prestart step (bash scripts/prestart.sh) inside the backend's start command, just before fastapi run.** — Nexlayer routes traffic itself, so Traefik is not needed. Adminer and Mailcatcher are dev and admin helpers. prestart is a one-shot job that compose runs before backend, not a long-running service. (`compose.yml`, `compose.override.yml`, `compose.traefik.yml`, `backend/scripts/prestart.sh`)
- **database: Postgres 18 (mirror.gcr.io/library/postgres:18) in its own service, with a 5 GB volume mounted at /var/lib/postgresql/data and PGDATA=/var/lib/postgresql/data/pgdata.** — compose.yml pins postgres:18 and stores data in a named volume with that PGDATA path. Without a volume, every user and item is lost on restart. (`compose.yml`)
- **networking: The frontend is served at / and the backend at /api on the same app URL. FRONTEND_HOST and BACKEND_CORS_ORIGINS are set to the app URL. The backend reaches the database at POSTGRES_SERVER=db.pod, port 5432.** — Every backend route, including openapi.json, is mounted under API_V1_STR=/api/v1. The CORS allow-list is BACKEND_CORS_ORIGINS plus FRONTEND_HOST. nginx serves the SPA with an index.html fallback on port 80. (`backend/app/main.py`, `backend/app/core/config.py`, `frontend/nginx.conf`)
- **keys: SECRET_KEY, FIRST_SUPERUSER, FIRST_SUPERUSER_PASSWORD and POSTGRES_PASSWORD are Nexlayer keys. POSTGRES_PASSWORD uses the same ${POSTGRES_PASSWORD} in the backend and the db service. ENVIRONMENT is set to production.** — Settings reads these from the environment and builds the Postgres DSN from POSTGRES_USER/POSTGRES_PASSWORD/POSTGRES_SERVER. The committed .env must not supply them in production. (`backend/app/core/config.py`, `.env`)
- **build: Build both images from the repo root ('.'): backend with backend/Dockerfile (uv sync from uv.lock) and frontend with frontend/Dockerfile (Bun build, then nginx). Pass the build arg VITE_API_URL to the frontend build.** — Both Dockerfiles copy root files (uv.lock, pyproject.toml, package.json, bun.lock) alongside their subfolder. The frontend declares ARG VITE_API_URL before bun run build. (`backend/Dockerfile`, `frontend/Dockerfile`, `pyproject.toml`, `package.json`)
- **scaling: Run one backend instance with the 4 uvicorn workers that the Dockerfile CMD already uses.** — Migrations run in the start command, so a single instance avoids parallel alembic upgrades racing each other. Four workers already give concurrency. (`backend/Dockerfile`, `backend/alembic.ini`)

### Fix before production

- **Blocker** — Supply real secrets as Nexlayer keys, never from the committed .env: The repo commits a .env containing SECRET_KEY, FIRST_SUPERUSER_PASSWORD and POSTGRES_PASSWORD entries. Using those values exposes the JWT signing key and admin and database passwords. Per the analysis, the app also refuses to start in production with the default values. (`.env`)
- **Blocker** — Build the frontend with VITE_API_URL set to the app's public URL: VITE_API_URL is baked into the static bundle at build time. If it is left unset or set to localhost:8000, every browser API call (login, users, items) fails. (`frontend/Dockerfile`)
- Switch Docker Hub base images to the mirror and build with BuildKit: FROM python:3.10 and FROM nginx:1 pull from rate-limited Docker Hub; use mirror.gcr.io/library/python:3.10 and mirror.gcr.io/library/nginx:1 instead. The backend's RUN --mount cache and bind mounts also fail without BuildKit. (`backend/Dockerfile`)

### Verify after the deploy

1. GET / on the app URL returns 200 with the SPA's index.html
2. GET <app URL>/api/v1/openapi.json returns 200 JSON. This confirms /api routes reach the backend with the /api/v1 prefix intact.
3. Backend logs show scripts/prestart.sh completing (alembic upgrade head) before fastapi starts serving on 8000
4. Log in through the UI with the FIRST_SUPERUSER account and confirm the browser's calls to <app URL>/api/v1 succeed with no CORS errors
5. Restart the db service, then log in again and confirm previously created items still exist (the volume persisted)

### Ask the human

- Which SMTP provider (SMTP_HOST, SMTP_USER, SMTP_PASSWORD, EMAILS_FROM_EMAIL) should send password-recovery emails? Without one, email recovery will not work.
- Do you want Sentry error reporting? If so, provide SENTRY_DSN; it is only used when ENVIRONMENT is not local.

## Drafts in this pull request

This repo had no deploy config, so this plan adds drafts where files were
missing (never over an existing file):

- `nexlayer.yaml` — what runs, written by the Nexlayer agent (see "The production plan"). Not yet checked by the Nexlayer validator — run `nexlayer_validate_yaml` first.

Build them once, fix what fails, then deploy with `.nexlayer/pipeline.yaml`.
After the first successful deploy, these files are the source of truth.

## Can this deploy right now?

**Not yet — 3 missing keys (the human's).** Full list in `.nexlayer/todo.md`.

## How to deploy

Call `nexlayer_get_deployment_workflow` first. It returns the current
procedure — building and pushing the image included — and it is kept up to
date in a way this file is not. Do not infer the steps from here, and do
not skip it because the app looks simple.

If Nexlayer tools are not available to you, the human runs
`npx @nexlayer/mcp-install` once.

## Secrets

Keys reach the app by name. In `nexlayer.yaml`, write `${NAME}` where the
value goes (e.g. `OPENAI_API_KEY: "${OPENAI_API_KEY}"`) — never the value.
When you deploy through the Nexlayer MCP, Nexlayer fills each name from this
app's Secrets. Values never go in this repo, the chat, or your context.

| Key | Status |
| --- | --- |
| `SECRET_KEY` | **missing** |
| `FIRST_SUPERUSER_PASSWORD` | **missing** |
| `FIRST_SUPERUSER` | **missing** |

Keys marked supplied are handled. Do not ask for them again.

For a missing key: **do not ask the human to paste it into the chat, and do**
**not write it into this repo.** Both put a live credential somewhere it
cannot be taken back from. Send them to the app's Secrets instead, wait
until they say it is added, then deploy:

<https://zen-antelope-nexlayer-dashboard-preview.cloud.nexlayer.ai/apps/be7d57a0-8a3a-4b9c-a3ca-902327e6ba6b/keys>

## What was inferred rather than read

Nothing. Every claim in this plan was read from the repo.

## What "it worked" means

The `verify` list in `.nexlayer/pipeline.yaml` is what to check. Check it — do not
assume a deploy worked.

## Stop and ask the human

- A required key is missing (send the link above — never take the value).
- Something would become publicly reachable that is internal in this plan.
- Anything that deletes data or tears down a running deployment.

Everything else is yours to do. When something breaks, start at
`.nexlayer/TROUBLESHOOTING.md`.
