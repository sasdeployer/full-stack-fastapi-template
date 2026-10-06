# Nexlayer — how `full-stack-fastapi-template` ships

You were asked to work on or deploy this app. The state below is already
resolved — do not re-derive it from the code. The procedure is not here;
ask Nexlayer for it (see "How to deploy").

## The app

| | |
| --- | --- |
| Name | `full-stack-fastapi-template` |
| Repo | `https://github.com/sasdeployer/full-stack-fastapi-template` on `master` |
| Planned | 2026-10-06T21:39:02.743Z |
| Registered with Nexlayer | yes |

`.nexlayer/plan.lock` pins the commit this plan was written against. If HEAD
has moved and you changed how the app starts, runs, or what it needs,
re-check before deploying.

## The production plan

Written by the Nexlayer agent from this repo. Every decision cites the files it
rests on; if the code has changed since, re-check those files first.

The app has three services: a React/Vite frontend served as static files by nginx, a FastAPI backend that serves everything under /api/v1, and a Postgres 18 database the backend reaches at db.pod:5432. The frontend and backend share one public URL: the frontend takes '/' and the backend takes '/api'. The browser therefore calls the backend on the same origin, so the frontend build must bake in that public URL as VITE_API_URL. The most important thing for production is setting SECRET_KEY explicitly and keeping the database on a volume. Without SECRET_KEY, each of the 4 backend workers generates its own random key and logins break. Without the volume, users and items vanish on restart.

- **services: Run three services: frontend (nginx, port 80), backend (FastAPI, port 8000) and db (Postgres). Drop adminer, traefik/proxy and mailcatcher. Do not run the one-shot 'prestart' service as its own service; its script runs in the backend's start command instead.** — compose.yml defines db, adminer, prestart, backend and frontend. Traefik is only a reverse proxy, which Nexlayer replaces with its own routing. Adminer is a DB admin UI and mailcatcher is a dev mail catcher. prestart runs 'bash scripts/prestart.sh' once and exits, so the backend command becomes 'bash scripts/prestart.sh && exec fastapi run --workers 4 app/main.py'. (`compose.yml`, `compose.override.yml`, `compose.traefik.yml`, `backend/scripts/prestart.sh`, `backend/Dockerfile`)
- **database: Postgres 18 (mirror.gcr.io/library/postgres:18) in its own db service with a 5 GB volume mounted at /var/lib/postgresql. Database 'app', user 'postgres', password from the POSTGRES_PASSWORD key.** — compose.yml pins postgres:18 and stores data on the app-db-data volume. The backend builds its connection URI from the separate POSTGRES_SERVER/PORT/USER/PASSWORD/DB variables, so those are set individually and POSTGRES_SERVER is db.pod. (`compose.yml`, `backend/app/core/config.py`)
- **networking: Route frontend at path '/' and backend at path '/api' on the same app URL. Set FRONTEND_HOST to <% URL %> so CORS allows that origin.** — main.py mounts every route under API_V1_STR='/api/v1' and adds FRONTEND_HOST to the CORS origins. nginx.conf serves the SPA with an index.html fallback on port 80. (`backend/app/main.py`, `backend/app/core/config.py`, `frontend/nginx.conf`)
- **keys: Use five keys by name: SECRET_KEY, FIRST_SUPERUSER, FIRST_SUPERUSER_PASSWORD, POSTGRES_PASSWORD, and the db's matching POSTGRES_PASSWORD. Nexlayer fills them at deploy. Nothing is copied from the committed .env.** — In config.py SECRET_KEY defaults to secrets.token_urlsafe(32) per process, and the backend runs 4 workers. An unset key means each worker signs JWTs differently and every restart logs everyone out. The first-superuser credentials are what the prestart step uses to create the admin. (`backend/app/core/config.py`, `backend/Dockerfile`, `.env`)
- **build: Build two images from the repo root context: backend from backend/Dockerfile and frontend from frontend/Dockerfile. Pass VITE_API_URL as a build argument set to the app's public URL.** — Both Dockerfiles copy root files (uv.lock, pyproject.toml, package.json, bun.lock), so the context must be '.'. frontend/Dockerfile declares ARG VITE_API_URL before 'bun run build', which bakes it into the static bundle. (`backend/Dockerfile`, `frontend/Dockerfile`, `pyproject.toml`, `package.json`)
- **scaling: Run one instance of each service. The backend keeps its 4 in-process workers.** — The Dockerfile already runs 'fastapi run --workers 4'. The database is a single-writer Postgres. The migration step in the start command should not race across multiple instances. (`backend/Dockerfile`, `compose.yml`)

### Fix before production

- **Blocker** — Bake the real public app URL into VITE_API_URL when building the frontend: VITE_API_URL is fixed into the static bundle at build time, and the local sample value is http://localhost:8000. A frontend built without the public URL sends every browser API call to localhost, so login and all data pages fail. (`frontend/Dockerfile`)
- Use mirror.gcr.io/library images for the official base images: The repo's base images are pulled from Docker Hub, which is rate-limited: 'FROM python:3.10' in backend/Dockerfile and 'FROM nginx:1' in frontend/Dockerfile. The fix is mirror.gcr.io/library/python:3.10 and mirror.gcr.io/library/nginx:1. oven/bun:1 is namespaced and can stay. (`backend/Dockerfile`)
- Keep the committed .env files out of production images and config: The root .env holds default credentials (the 'changethis' placeholders), and frontend/.env carries local settings. These must not leak into an image or be reused as production values; all keys come from Nexlayer. The backend Dockerfile does not copy .env, but frontend/Dockerfile copies the whole ./frontend folder. (`.env`)

### Verify after the deploy

1. GET <app URL>/ returns 200 with the React index.html, and a deep link such as <app URL>/login also returns 200 (SPA fallback works)
2. GET <app URL>/api/v1/openapi.json returns 200 JSON whose title is 'Full Stack FastAPI Project'
3. Backend logs show the prestart script ran (alembic migrations applied, first superuser created) before 'fastapi run' started listening on port 8000
4. In the browser, log in with the FIRST_SUPERUSER credentials. The devtools network tab should show API calls going to <app URL>/api/v1/... (not localhost) and succeeding
5. Restart the db service, then log in again and confirm items created earlier are still listed (the volume persists data)

### Ask the human

- Which SMTP provider should send password-recovery and new-account emails? The SMTP_HOST, SMTP_USER, SMTP_PASSWORD and EMAILS_FROM_EMAIL keys are not set here, so email features will not work until you choose one.
- Will the app use a custom domain? VITE_API_URL is baked into the frontend build, so the frontend must be rebuilt whenever the public URL changes.
- Do you want Sentry error tracking? If so, provide SENTRY_DSN; it is only used when ENVIRONMENT is not 'local'.

## Drafts in this pull request

This repo had no deploy config, so this plan adds drafts where files were
missing (never over an existing file):

- `nexlayer.yaml` — what runs, written by the Nexlayer agent (see "The production plan"). It passes the Nexlayer validator.

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

<http://localhost:3001/apps/8cefeeda-35b9-401e-a9c3-1fedf838f02a/keys>

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
