# file: driver-service/Dockerfile

# Stage 1: Build
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm install

COPY . .

# Stage 2: Production
FROM node:18-alpine
WORKDIR /app
COPY --from=builder /app ./

# Port đã thống nhất
EXPOSE 8082

CMD [ "node", "index.js" ]