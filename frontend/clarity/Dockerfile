# Stage 1: Dependencies
FROM node:20-alpine AS deps

# Enable pnpm via corepack (Node 20 has corepack built-in)
RUN corepack enable

WORKDIR /app

# Copy package files only (for better caching)
COPY package.json pnpm-lock.yaml ./

# Install dependencies with pnpm
RUN pnpm install --frozen-lockfile

# Stage 2: Builder
FROM node:20-alpine AS builder

RUN corepack enable
WORKDIR /app

# Copy deps
COPY --from=deps /app/node_modules ./node_modules
COPY package.json pnpm-lock.yaml ./
COPY . .

# Build Next.js application
RUN pnpm run build

# Stage 3: Runtime with Nginx + Next.js
FROM node:20-alpine AS runtime

RUN apk add --no-cache nginx

WORKDIR /app

ENV NODE_ENV=production
ENV PORT=3000

# Copy built app and dependencies
COPY --from=builder /app/.next ./.next
COPY --from=builder /app/public ./public
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./

# Copy nginx config
COPY nginx.conf /etc/nginx/nginx.conf

# Startup script: start Next.js then Nginx
RUN echo '#!/bin/sh\n\
node node_modules/.bin/next start --port 3000 &\n\
NEXT_PID=$!\n\
nginx -g "daemon off;"\n' > /start.sh && chmod +x /start.sh

EXPOSE 80 3000

CMD ["/start.sh"]
