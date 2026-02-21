# ──────────────────────────────────────────────────────────────────────────────
# Stage 1 – builder
#   Installs ALL dependencies (including devDependencies) and runs any build
#   steps (e.g. TypeScript compilation, asset bundling).
# ──────────────────────────────────────────────────────────────────────────────
FROM node:18-alpine AS builder

# Set working directory
WORKDIR /app

# Copy dependency manifests first to leverage Docker layer caching
COPY package*.json ./

# Install all dependencies (dev + prod)
RUN npm ci --ignore-scripts

# Copy the rest of the source code
COPY . .

# Run tests to catch issues before building the image
RUN npm test

# Prune devDependencies so the production layer stays lean
RUN npm prune --production

# ──────────────────────────────────────────────────────────────────────────────
# Stage 2 – production
#   Uses a minimal base image and copies only the artefacts required at runtime.
# ──────────────────────────────────────────────────────────────────────────────
FROM node:18-alpine AS production

# Add non-root user for security hardening
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

WORKDIR /app

# Copy only the pruned node_modules and application code from the builder stage
COPY --from=builder --chown=appuser:appgroup /app/node_modules ./node_modules
COPY --from=builder --chown=appuser:appgroup /app/package.json ./package.json
COPY --from=builder --chown=appuser:appgroup /app/index.js    ./index.js
COPY --from=builder --chown=appuser:appgroup /app/public      ./public

# Switch to non-root user
USER appuser

# Expose the application port
EXPOSE 3000

# Health-check; wget is provided by BusyBox in the Alpine base image
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget -qO- http://localhost:3000/health || exit 1

# Start the application
CMD ["node", "index.js"]
