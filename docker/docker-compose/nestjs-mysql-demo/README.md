# NestJS + MySQL Demo

This demo runs a minimal NestJS application that connects to a MySQL container. The app serves a static `index.html` at `/` and will insert a demo user into the database on startup.

Quick start (requires Docker):

```bash
cd docker/docker-compose/nestjs-mysql-demo
docker compose up --build -d
```

Open http://localhost:3000

To stop:

```bash
docker compose down
```
