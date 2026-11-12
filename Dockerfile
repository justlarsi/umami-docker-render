# Use the official Node image as the base
FROM node:20-alpine AS builder

# Install the exact pnpm version Umami expects
RUN npm install -g pnpm@12.3.4

# Set the working directory
WORKDIR /app

# Clone the specific Umami release (v3.5.0)
RUN apk add --no-cache git && \
    git clone --branch v3.5.0 https://github.com/umami-software/umami.git .

# Install dependencies using pnpm, ignoring engine checks just to be safe
RUN pnpm install --config.engine-strict=false

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
