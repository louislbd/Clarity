# Stage 1: Dependencies
FROM node:20-alpine AS deps

RUN corepack enable

WORKDIR /app

COPY package.json pnpm-lock.yaml ./

RUN pnpm install --frozen-lockfile

# Stage 2: Build
FROM node:20-alpine AS builder

RUN corepack enable
WORKDIR /app

COPY --from=deps /app/node_modules ./node_modules
COPY package.json pnpm-lock.yaml ./
COPY . .

RUN pnpm run build

# Stage 3: Runtime
FROM node:20-alpine AS runtime

RUN apk add --no-cache nginx

WORKDIR /app

ENV NODE_ENV=production
ENV PORT=3000

RUN mkdir -p /var/log/nginx /var/lib/nginx/logs /tmp/nginx/client_body && \
    chown -R nginx:nginx /var/log/nginx /var/lib/nginx /tmp/nginx && \
    chmod -R 755 /var/log/nginx /var/lib/nginx /tmp/nginx

COPY --from=builder /app/.next ./.next
COPY --from=builder /app/public ./public
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./

COPY nginx.conf /etc/nginx/nginx.conf

EXPOSE 80 3000

CMD ["sh", "-c", "node_modules/.bin/next start & nginx -g 'daemon off;'"]
