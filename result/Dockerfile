# STAGE 1
FROM node:lts-alpine AS builder

WORKDIR /app
COPY package*.json .

RUN npm install
COPY . .

RUN npm prune --omit=dev

# STAGE 2
FROM node:lts-alpine AS runner
ENV NODE_ENV=production
WORKDIR /app

RUN apk add --no-cache curl tini

COPY --from=builder /app/package*.json .
COPY --from=builder /app/server.js .
COPY --from=builder /app/views ./views
COPY --from=builder /app/node_modules ./node_modules

USER node
ENV PORT=80
EXPOSE 80
ENTRYPOINT ["/sbin/tini", "--"]
CMD ["node", "server.js"]
