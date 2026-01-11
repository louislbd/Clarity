# BUILDER
FROM node:20-alpine AS builder
WORKDIR /app
COPY package.json pnpm-lock.yaml ./
RUN npm install -g pnpm && pnpm install
COPY . .
RUN pnpm run build

# RUNNER
FROM nginx:alpine

RUN mkdir -p /var/lib/nginx/logs && \
    chown -R 101:101 /var/lib/nginx/logs && \
    chown -R 101:101 /var/cache/nginx && \
    chown -R 101:101 /var/log/nginx && \
    touch /var/run/nginx.pid && \
    chown 101:101 /var/run/nginx.pid

WORKDIR /usr/share/nginx/html

COPY --from=builder /app/.next ./.next
COPY --from=builder /app/public ./public
COPY --from=builder /app/package.json ./
COPY --from=builder /app/node_modules ./node_modules

COPY nginx.conf /etc/nginx/conf.d/default.conf

RUN chown -R 101:101 /usr/share/nginx/html && \
    chown -R 101:101 /etc/nginx/conf.d

EXPOSE 80 443

CMD ["nginx", "-g", "daemon off;"]
