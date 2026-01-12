## Typical usage
```bash
cd docker
docker compose -f docker-compose.edge.yml up -d
# Apply schema once:
docker compose -f docker-compose.edge.yml --profile init run --rm db-init
```
