FROM oven/bun:1-alpine AS builder
WORKDIR /app
COPY . .
RUN bun install --frozen-lockfile
RUN cd frontend && NODE_OPTIONS="--max-old-space-size=4096" bun run build

FROM oven/bun:1-alpine
WORKDIR /app
COPY --from=builder /app ./
WORKDIR /app/frontend
ENV NODE_ENV=production
EXPOSE 8000

