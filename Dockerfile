FROM node:18-alpine AS deps
RUN apk add --no-cache libc6-compat
WORKDIR /next-auth

COPY package.json package-lock.json ./
RUN  npm install --production

FROM node:18-alpine AS builder
WORKDIR /next-auth
COPY --from=deps /next-auth/node_modules ./node_modules
COPY . .

ENV NEXT_TELEMETRY_DISABLED 1

RUN npm run build

FROM node:18-alpine AS runner
WORKDIR /next-auth

ENV NODE_ENV production
ENV NEXT_TELEMETRY_DISABLED 1

RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

COPY --from=builder --chown=nextjs:nodejs /next-auth/.next ./.next
COPY --from=builder /next-auth/node_modules ./node_modules
COPY --from=builder /next-auth/package.json ./package.json

USER nextjs

EXPOSE 3000

ENV PORT 3000

CMD ["npm", "start"]