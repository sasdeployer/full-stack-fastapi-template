# full-stack-fastapi-template — before this ships

Two lists, split by who can actually close the item.

## Needs code — the coding agent

- [ ] **Blocker:** Supply real secrets as Nexlayer keys, never from the committed .env (`.env`)
      _The repo commits a .env containing SECRET_KEY, FIRST_SUPERUSER_PASSWORD and POSTGRES_PASSWORD entries. Using those values exposes the JWT signing key and admin and database passwords. Per the analysis, the app also refuses to start in production with the default values._
- [ ] **Blocker:** Build the frontend with VITE_API_URL set to the app's public URL (`frontend/Dockerfile`)
      _VITE_API_URL is baked into the static bundle at build time. If it is left unset or set to localhost:8000, every browser API call (login, users, items) fails._
- [ ] Switch Docker Hub base images to the mirror and build with BuildKit (`backend/Dockerfile`)
      _FROM python:3.10 and FROM nginx:1 pull from rate-limited Docker Hub; use mirror.gcr.io/library/python:3.10 and mirror.gcr.io/library/nginx:1 instead. The backend's RUN --mount cache and bind mounts also fail without BuildKit._
- [ ] Build the drafted image(s) once and fix what fails; check `nexlayer.yaml`.

## Needs the human

- [ ] Decide: Which SMTP provider (SMTP_HOST, SMTP_USER, SMTP_PASSWORD, EMAILS_FROM_EMAIL) should send password-recovery emails? Without one, email recovery will not work.
- [ ] Decide: Do you want Sentry error reporting? If so, provide SENTRY_DSN; it is only used when ENVIRONMENT is not local.
- [ ] `SECRET_KEY` — the human adds it in the app's Secrets: <https://zen-antelope-nexlayer-dashboard-preview.cloud.nexlayer.ai/apps/be7d57a0-8a3a-4b9c-a3ca-902327e6ba6b/keys>
- [ ] `FIRST_SUPERUSER_PASSWORD` — the human adds it in the app's Secrets: <https://zen-antelope-nexlayer-dashboard-preview.cloud.nexlayer.ai/apps/be7d57a0-8a3a-4b9c-a3ca-902327e6ba6b/keys>
- [ ] `FIRST_SUPERUSER` — the human adds it in the app's Secrets: <https://zen-antelope-nexlayer-dashboard-preview.cloud.nexlayer.ai/apps/be7d57a0-8a3a-4b9c-a3ca-902327e6ba6b/keys>

Never through the chat or this repo. `nexlayer.yaml` references each one as
`${NAME}`; Nexlayer fills it at deploy.

## Check after the deploy — the coding agent

- [ ] GET / on the app URL returns 200 with the SPA's index.html
- [ ] GET <app URL>/api/v1/openapi.json returns 200 JSON. This confirms /api routes reach the backend with the /api/v1 prefix intact.
- [ ] Backend logs show scripts/prestart.sh completing (alembic upgrade head) before fastapi starts serving on 8000
- [ ] Log in through the UI with the FIRST_SUPERUSER account and confirm the browser's calls to <app URL>/api/v1 succeed with no CORS errors
- [ ] Restart the db service, then log in again and confirm previously created items still exist (the volume persisted)

---

Machine-readable: `.nexlayer/findings.json`.
