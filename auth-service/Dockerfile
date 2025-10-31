FROM node:18-alpine
WORKDIR /app
COPY package.json .
# Use npm install when package-lock.json is missing; npm ci requires a lockfile
# Install production dependencies only to keep image small
RUN npm install --omit=dev --no-audit --no-fund
COPY index.js .
EXPOSE 3000
CMD ["node", "index.js"]
