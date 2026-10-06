# full-stack-fastapi-template — production context

Written by the Nexlayer agent so any coding agent that opens this repo
starts with the same picture. Read this before proposing infrastructure
changes.

- **Repo** `https://github.com/sasdeployer/full-stack-fastapi-template` on `master`
- **Analyzed** 2026-10-06T21:39:02.743Z

## Stack

| Component | Version | How we know |
| --- | --- | --- |
| Python | 3.10+ | read from `pyproject.toml`, `README.md` |
| FastAPI |  | read from `README.md` |
| SQLModel |  | read from `README.md` |
| Pydantic |  | read from `README.md` |
| PostgreSQL |  | read from `README.md` |
| uv |  | read from `pyproject.toml`, `uv.lock` |
| Pytest |  | read from `README.md` |
| TypeScript |  | read from `README.md` |
| React |  | read from `README.md` |
| Vite |  | read from `README.md` |
| Tailwind CSS |  | read from `README.md` |
| shadcn/ui |  | read from `README.md` |
| Playwright |  | read from `README.md` |
| Bun |  | read from `package.json`, `bun.lock` |
| Docker Compose |  | read from `compose.yml`, `compose.override.yml`, `README.md` |
| Traefik |  | read from `compose.traefik.yml`, `README.md` |
| Mailcatcher |  | read from `README.md` |

## How Nexlayer will run it

| Service | Reachable | Image | How we know |
| --- | --- | --- | --- |
| `frontend` | public | `registry.nexlayer.io/YOUR_USER_ID/full-stack-fastapi-template-frontend:planned` | read from `.nexlayer/drafts/nexlayer.yaml` |
| `backend` | public | `registry.nexlayer.io/YOUR_USER_ID/full-stack-fastapi-template-backend:planned` | read from `.nexlayer/drafts/nexlayer.yaml` |
| `db` | internal only | `mirror.gcr.io/library/postgres:18` | read from `.nexlayer/drafts/nexlayer.yaml` |

Reachability is inferred from service names and roles, not stated by the
analysis. Check it before relying on it — exposing something that should
be internal is not recoverable by editing this file afterwards.

Networking, HTTPS, and service discovery are handled.

## Secrets

This app uses 3 keys: 3 required to run, 0 optional.

Keys reach the app by name. In `nexlayer.yaml`, write `${NAME}` where the
value goes (e.g. `OPENAI_API_KEY: "${OPENAI_API_KEY}"`) — never the value.
When you deploy through the Nexlayer MCP, Nexlayer fills each name from this
app's Secrets. Values never go in this repo, the chat, or your context.

- `SECRET_KEY` — **still needed from the human**
- `FIRST_SUPERUSER_PASSWORD` — **still needed from the human**
- `FIRST_SUPERUSER` — **still needed from the human**

If you are a coding agent: do not ask the human to paste a missing key into
the chat, and do not write one into this repo.

## Notes from the analysis

- Backend reaches Postgres at db.pod:5432 via POSTGRES_SERVER=db.pod and POSTGRES_PORT=5432. The template builds its connection URI from these discrete variables, not from a DATABASE_URL.
- The backend image is built from backend/Dockerfile (uv sync, then fastapi run on port 8000). The base image above only shows the mirror.gcr.io form.
- Before the API starts, run the template's prestart steps once: alembic upgrade head, then python app/initial_data.py to create FIRST_SUPERUSER. Run them in the backend container's start command, not as a separate daemon pod.
- The frontend is a static Vite build served by nginx, built from frontend/Dockerfile. VITE_API_URL is baked in at build time and is called from the user's browser, so it must be the backend's public URL, not a .pod address.
- The backend must allow the frontend's public origin through BACKEND_CORS_ORIGINS.
- Traefik, Adminer and Mailcatcher from the compose files are not needed. Nexlayer handles routing, and a real SMTP provider replaces Mailcatcher.
- In a non-local ENVIRONMENT the settings validation rejects the value 'changethis' for SECRET_KEY, POSTGRES_PASSWORD and FIRST_SUPERUSER_PASSWORD, so set real values.

## Talking to Nexlayer

Nexlayer is reachable over MCP. Call `nexlayer_get_deployment_workflow`
before deploying — it is the current procedure, and it changes more often
than this file does.
