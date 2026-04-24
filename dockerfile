# Stage 1: Build
FROM node:22-alpine AS builder
WORKDIR /app
# Install system dependencies required for sharp and other native modules
RUN apk add --no-cache libc6-compat
# Copy package files first for better layer caching
COPY package.json package-lock.json ./
# Install dependencies
RUN npm ci
# Copy source code
COPY . ./
# Build the application
RUN npm run build
# Stage 2: Production
FROM node:22-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production
# Create non-root user for security
RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs
RUN apk add --no-cache curl
# Copy standalone output from builder
COPY --from=builder /app/public ./public
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static
RUN mkdir -p public/media && chown -R nextjs:nodejs public/media
# Switch to non-root user
USER nextjs
# Expose port
EXPOSE 3000
# Set environment variables
ENV PORT=3000
ENV HOSTNAME=0.0.0.0
ENV NEXT_TELEMETRY_DISABLED=1
# Start the application
HEALTHCHECK --interval=5s --timeout=5s --retries=3 CMD curl -f http://localhost:3000/ || exit 1
CMD ["node", "server.js"] 