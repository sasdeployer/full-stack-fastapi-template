# full-stack-fastapi-template — before this ships

Two lists, split by who can actually close the item.

## Needs code — the coding agent

- [ ] **Blocker:** Bake the real public app URL into VITE_API_URL when building the frontend (`frontend/Dockerfile`)
      _VITE_API_URL is fixed into the static bundle at build time, and the local sample value is http://localhost:8000. A frontend built without the public URL sends every browser API call to localhost, so login and all data pages fail._
- [ ] Use mirror.gcr.io/library images for the official base images (`backend/Dockerfile`)
      _The repo's base images are pulled from Docker Hub, which is rate-limited: 'FROM python:3.10' in backend/Dockerfile and 'FROM nginx:1' in frontend/Dockerfile. The fix is mirror.gcr.io/library/python:3.10 and mirror.gcr.io/library/nginx:1. oven/bun:1 is namespaced and can stay._
- [ ] Keep the committed .env files out of production images and config (`.env`)
      _The root .env holds default credentials (the 'changethis' placeholders), and frontend/.env carries local settings. These must not leak into an image or be reused as production values; all keys come from Nexlayer. The backend Dockerfile does not copy .env, but frontend/Dockerfile copies the whole ./frontend folder._
- [ ] Build the drafted image(s) once and fix what fails; check `nexlayer.yaml`.

## Needs the human

- [ ] Decide: Which SMTP provider should send password-recovery and new-account emails? The SMTP_HOST, SMTP_USER, SMTP_PASSWORD and EMAILS_FROM_EMAIL keys are not set here, so email features will not work until you choose one.
- [ ] Decide: Will the app use a custom domain? VITE_API_URL is baked into the frontend build, so the frontend must be rebuilt whenever the public URL changes.
- [ ] Decide: Do you want Sentry error tracking? If so, provide SENTRY_DSN; it is only used when ENVIRONMENT is not 'local'.
- [ ] `SECRET_KEY` — the human adds it in the app's Secrets: <http://localhost:3001/apps/8cefeeda-35b9-401e-a9c3-1fedf838f02a/keys>
- [ ] `FIRST_SUPERUSER_PASSWORD` — the human adds it in the app's Secrets: <http://localhost:3001/apps/8cefeeda-35b9-401e-a9c3-1fedf838f02a/keys>
- [ ] `FIRST_SUPERUSER` — the human adds it in the app's Secrets: <http://localhost:3001/apps/8cefeeda-35b9-401e-a9c3-1fedf838f02a/keys>

Never through the chat or this repo. `nexlayer.yaml` references each one as
`${NAME}`; Nexlayer fills it at deploy.

## Check after the deploy — the coding agent

- [ ] GET <app URL>/ returns 200 with the React index.html, and a deep link such as <app URL>/login also returns 200 (SPA fallback works)
- [ ] GET <app URL>/api/v1/openapi.json returns 200 JSON whose title is 'Full Stack FastAPI Project'
- [ ] Backend logs show the prestart script ran (alembic migrations applied, first superuser created) before 'fastapi run' started listening on port 8000
- [ ] In the browser, log in with the FIRST_SUPERUSER credentials. The devtools network tab should show API calls going to <app URL>/api/v1/... (not localhost) and succeeding
- [ ] Restart the db service, then log in again and confirm items created earlier are still listed (the volume persists data)

---

Machine-readable: `.nexlayer/findings.json`.
