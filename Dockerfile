# Use the official Node image as the base
FROM node:20-alpine AS builder

# Install the exact pnpm version Umami expects
RUN npm install -g pnpm@12.3.4

# Set the working directory
WORKDIR /app

# Clone the specific Umami release (v3.5.0)
RUN apk add --no-cache git && \
    git clone --branch v3.5.0 https://github.com/umami-software/umami.git .

# Install dependencies using pnpm
RUN pnpm install --config.engine-strict=false

# Neutralize Umami's pre-build database checks
RUN echo "console.log('Skipping env check');" > scripts/check-env.js && \
    echo "console.log('Skipping db check');" > scripts/check-db.js

# ---------------------------------------------------------
# NEW: Memory & CPU Constraints for Render's Free Tier
# Stop Next.js from spawning 47 workers and crashing the RAM
# ---------------------------------------------------------
ENV NEXT_PRIVATE_MAX_CPUS=2
ENV NODE_OPTIONS="--max_old_space_size=2048"
ENV NEXT_TELEMETRY_DISABLED=1

# Provide the dummy URL for Prisma
ENV DATABASE_URL="postgresql://dummy:dummy@localhost:5432/dummy"

# Build the application
RUN pnpm build

# Stage 2: Production image
FROM node:20-alpine AS runner

WORKDIR /app

# Install pnpm in the runner stage as well
RUN npm install -g pnpm@12.3.4

# Copy built assets from the builder stage
COPY --from=builder /app ./

# Expose the port Umami uses
EXPOSE 3000

# Start the application
CMD ["pnpm", "start"]
