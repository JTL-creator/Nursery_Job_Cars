FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production && npm cache clean --force

FROM node:20-alpine
RUN addgroup -g 1001 -S nodejs && adduser -S nodeapp -u 1001 -G nodejs
WORKDIR /app
COPY --from=builder /app/node_modules ./node_modules
COPY --chown=nodeapp:nodejs . .
# Garante que a pasta de uploads exista e seja gravavel pelo usuario nao-root.
RUN mkdir -p /app/uploads/ativos && chown -R nodeapp:nodejs /app/uploads
ENV NODE_ENV=production
ENV PORT=5000
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:5000/api/v1/health || exit 1
USER nodeapp
EXPOSE 5000
CMD ["node", "src/server.js"]