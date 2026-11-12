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

# ---------------------------------------------------------
# NEW: Neutralize Umami's pre-build database checks.
# This allows the Docker container to build completely offline.
# ---------------------------------------------------------
RUN echo "console.log('Skipping env check');" > scripts/check-env.js && \
    echo "console.log('Skipping db check');" > scripts/check-db.js

# Provide the dummy URL so Prisma can generate the database client offline
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
