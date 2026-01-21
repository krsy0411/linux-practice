FROM node:18-alpine

WORKDIR /app

# install deps
COPY package.json package-lock.json* ./
RUN npm ci --silent || npm install --silent

# copy source
COPY . .

# build
RUN npm run build

EXPOSE 3000

CMD ["node", "dist/main.js"]
