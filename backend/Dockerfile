FROM node:20-alpine

# Install OpenSSL for Prisma
RUN apk add --no-cache openssl

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install all dependencies (including dev for prisma)
RUN npm ci --omit=dev

# Copy prisma schema first for generate
COPY prisma ./prisma/

# Generate Prisma client
RUN npx prisma generate

# Copy rest of the source code
COPY . .

# Expose port
EXPOSE 5000

# Start the server
CMD ["node", "server.js"]
