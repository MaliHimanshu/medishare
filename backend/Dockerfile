FROM node:20-alpine

# Install OpenSSL for Prisma
RUN apk add --no-cache openssl

# Set working directory
WORKDIR /app

# Copy package files and prisma schema
COPY package*.json ./
COPY prisma ./prisma/

# Install dependencies (runs postinstall prisma generate)
RUN npm ci --omit=dev

# Copy rest of the source code
COPY . .

# Expose port
EXPOSE 5000

# Start the server (sync schema with production DB)
CMD ["sh", "-c", "npx prisma db push --skip-generate --accept-data-loss && node server.js"]
