# Nexlayer — full-stack-fastapi-template

<!-- nexlayer:meta version=1 analyzed=2026-06-17T14:06:14Z repo=https://github.com/sasdeployer/full-stack-fastapi-template branch=master -->

> **For AI agents (Claude Code, Cursor, Gemini CLI, Copilot):**
> This file is the **project context** for this Nexlayer deployment — tech stack, env vars, secrets, live URL.
> For full platform detail (nexlayer.yaml schema, Dockerfile rules, CI/CD, task recipes) read **`nexlayer.skills`** in this repo.
>
> **Critical rules (full detail in `nexlayer.skills`):**
> - Inter-pod refs: `${podName:port}` only — never `localhost` or bare hostnames
> - Docker Hub images: prefix with `mirror.gcr.io/library/` — bare tags fail on the cluster
> - Secrets: set in the Nexlayer dashboard — never commit to `nexlayer.yaml` or Dockerfile
>
> **This file:** `agent-managed` sections update automatically. `user-editable` sections (Local Development Setup, Nexlayer Deployment Plan, Build Notes) are yours — preserved across re-analysis.

## Project Summary
<!-- nexlayer:section agent-managed=project_summary -->
A full-stack application template featuring a FastAPI backend with SQLModel and a React frontend built with Vite, TypeScript, and Tailwind CSS.
<!-- nexlayer:end -->

## Technology Stack
<!-- nexlayer:section agent-managed=tech_stack -->
| Name | Kind | Version | Detected From |
|------|------|---------|---------------|
| FastAPI | framework | latest | README.md |
| React | framework | latest | README.md |
| PostgreSQL | database | latest | README.md |
| SQLModel | tool | latest | README.md |
| Vite | build | latest | README.md |
| Bun | tool | latest | package.json, bun.lock |
| Traefik | infra | latest | README.md, compose.traefik.yml |
| Mailcatcher | tool | latest | README.md |
<!-- nexlayer:end -->

## Repository Structure
<!-- nexlayer:section agent-managed=structure_map -->
- backend/ — FastAPI application and SQLModel logic
- frontend/ — React TypeScript application with Vite
- scripts/ — Deployment and utility scripts
- compose.yml — Orchestration for local development
<!-- nexlayer:end -->

## External Services Required
<!-- nexlayer:section agent-managed=external_deps -->
Services that must be configured separately (not deployed by Nexlayer):

- PostgreSQL (Database)
- Mailcatcher (Email testing)
<!-- nexlayer:end -->

## Local Development Setup
<!-- nexlayer:section user-editable=local_setup -->
### Prerequisites

- Bun
- Python 3.11+
- uv
- Docker

### Environment variables

Copy `.env.example` to `.env.local` and fill in:

```
POSTGRES_SERVER=localhost
POSTGRES_USER=postgres
POSTGRES_PASSWORD=password
POSTGRES_DB=app
```

### Steps

1. `bun install` — Install frontend dependencies
2. `uv sync` — Install backend dependencies using uv
3. `bun run dev` — Start frontend development server
4. `uv run fastapi dev backend/app/main.py` — Start FastAPI backend server

<!-- nexlayer:end -->

## Nexlayer Setup
<!-- nexlayer:section agent-managed=nexlayer_setup -->
### Pod Environment Variables

| Pod | Variable | Value | Kind |
|-----|----------|-------|------|
| `backend` | `ROOT_URL` | `"<% URL %>"` | plain |
| `db` | `POSTGRES_USER` | `"postgres"` | plain |
| `db` | `POSTGRES_PASSWORD` | _(set via Nexlayer dashboard)_ | secret |
| `db` | `POSTGRES_DB` | `"app"` | plain |
| `frontend` | `VITE_API_URL` | `"<% URL %>"` | plain |

### Secrets Required

Set these in the Nexlayer dashboard before deploying:

- `POSTGRES_PASSWORD` (`db` pod)

### nexlayer.yaml

```yaml
application:
  name: cool-vale-full-stack-fastapi-template
  pods:
    - name: backend
      image: "# filled by pipeline"
      servicePorts:
        - 8000
      vars:
        ROOT_URL: "<% URL %>"
    - name: db
      image: mirror.gcr.io/library/postgres:16-alpine
      servicePorts:
        - 5432
      vars:
        POSTGRES_USER: "postgres"
        POSTGRES_PASSWORD: "password"
        POSTGRES_DB: "app"
    - name: frontend
      image: mirror.gcr.io/library/node:22-alpine
      servicePorts:
        - 5173
      vars:
        VITE_API_URL: "<% URL %>"
    - name: mailcatcher
      image: mirror.gcr.io/library/mailcatcher:latest
      servicePorts:
        - 1080
```

<!-- nexlayer:end -->

## Nexlayer Deployment Plan
<!-- nexlayer:section user-editable=deployment_plan -->
### Pod Topology

| Pod | Image | Port | Role |
|-----|-------|------|------|
| db | mirror.gcr.io/library/postgres:16-alpine | 5432 | database |
| backend | mirror.gcr.io/library/python:3.11-slim | 8000 | web |
| frontend | mirror.gcr.io/library/node:22-alpine | 5173 | web |
| mailcatcher | mirror.gcr.io/library/mailcatcher:latest | 1080 | worker |
| traefik | mirror.gcr.io/library/traefik:latest | 80 | web |

### Inter-pod environment variables

- `backend` pod: `DATABASE_URL=postgresql://postgres:password@${db:5432}/app`
- `frontend` pod: `VITE_API_URL=http://${backend:8000}`

### Deployment notes

- Inter-pod communication for the backend uses ${db:5432} to connect to the PostgreSQL pod.
- Frontend connects to the API via ${backend:8000}.
- Official Docker Hub images are mirrored via mirror.gcr.io to comply with Nexlayer platform rules.

<!-- nexlayer:end -->

## Build Notes
<!-- nexlayer:section user-editable=build_notes -->
<!-- Add notes for future builds here — preserved across re-analysis -->
<!-- nexlayer:end -->

## Nexlayer Configuration
<!-- nexlayer:section agent-managed=nexlayer_config -->
**Last deployed:** 2026-06-17T14:46:19Z  
**Live URL:** https://cool-vale-full-stack-fastapi-template.nexlayer.ai  
**Runtime:** node · **Port:** 8000  
**Deploy branch:** master  

```yaml
application:
  name: cool-vale-full-stack-fastapi-template
  pods:
    - name: backend
      image: "# filled by pipeline"
      servicePorts:
        - 8000
      vars:
        ROOT_URL: "<% URL %>"
    - name: db
      image: mirror.gcr.io/library/postgres:16-alpine
      servicePorts:
        - 5432
      vars:
        POSTGRES_USER: "postgres"
        POSTGRES_PASSWORD: "password"
        POSTGRES_DB: "app"
    - name: frontend
      image: mirror.gcr.io/library/node:22-alpine
      servicePorts:
        - 5173
      vars:
        VITE_API_URL: "<% URL %>"
    - name: mailcatcher
      image: mirror.gcr.io/library/mailcatcher:latest
      servicePorts:
        - 1080
```
<!-- nexlayer:end -->

## Build History
<!-- nexlayer:section agent-managed=build_history -->
| Date | Status | Notes |
|------|--------|-------|
| 2026-06-17T14:06:14Z | analyzed | initial repo analysis |
| 2026-06-17T14:46:19Z | success | deployed https://cool-vale-full-stack-fastapi-template.nexlayer.ai |
<!-- nexlayer:end -->
