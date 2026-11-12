# Use the official Node image as the base
FROM node:20-alpine AS builder

# Install pnpm globally using the specific version required by Umami
RUN npm install -g pnpm@9.12.2

# Set the working directory
WORKDIR /app

# Clone the specific Umami release (v3.5.0) to avoid bleeding-edge monorepo issues
RUN apk add --no-cache git && \
    git clone --branch v3.5.0 https://github.com/umami-software/umami.git .

# Install dependencies using pnpm
RUN pnpm install

# Build the application
RUN pnpm build

# Stage 2: Production image
FROM node:20-alpine AS runner

WORKDIR /app

# Install pnpm in the runner stage as well
RUN npm install -g pnpm@9.12.2

# Copy built assets from the builder stage
COPY --from=builder /app ./

# Expose the port Umami uses
EXPOSE 3000

# Start the application
CMD ["pnpm", "start"]
