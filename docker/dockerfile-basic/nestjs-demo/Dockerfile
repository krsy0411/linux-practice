### Build stage
FROM node:18-alpine AS builder
WORKDIR /app

# install dependencies (use package-lock.json if present)
COPY package*.json ./
# use npm install to work when package-lock.json is not present
RUN npm install --silent

# copy source and build
COPY . .
RUN npm run build

### Runtime stage
FROM node:18-alpine
WORKDIR /app

# copy only production dependencies and built app
COPY package*.json ./
# use npm install --production when package-lock.json may be missing
RUN npm install --only=production --silent
COPY --from=builder /app/dist ./dist

ENV NODE_ENV=production
EXPOSE 3000
CMD ["node", "dist/main"]
