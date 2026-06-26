FROM node:20-alpine

WORKDIR /app

COPY package*.json ./

RUN npm ci

COPY . .

RUN rm -f tsconfig.build.tsbuildinfo && npm run build

# Remove dev dependencies for production
RUN npm prune --production

EXPOSE 4000

CMD ["npm", "start"]
