# Semantic seach

This repository contains a proof of concept for semantics seach using sparse embeddings (BM25). Embedding are stored in a [qdrant](https://qdrant.tech/) vector database and accesses through a [FastAPI](https://fastapi.tiangolo.com/).

The solution is running in [Azure Container Instances] and can be deployed using Bicep.

ACI does not use SSL, so HTTPS is provided through the use of Caddy running in its own
container.

Caddyfile should have specific format use "caddy fmt"
and be placed in "proxy-caddyfile" folder

## Docker image for FastAPI

Build and push the Docker image to Docker Hub. I am running on OSX so I build with

```Docker
docker buildx build --platform linux/amd64 -t <docker-hub-user>/embedding-api:latest .
docker image push <docker-hub-user>/embedding-api:latest
```

replace <docker-hub-user> with your Docker Hub user name.
