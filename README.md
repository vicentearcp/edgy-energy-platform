# Edgy Energy Platform

This repository contains the full setup for an **edge + cloud energy data platform** based on:

- Node-RED (data ingestion, normalization, control)
- PostgreSQL (telemetry, forecasts, digital twin)
- Raspberry Pi (edge runtime)
- MQTT (Victron GX / Venus OS integration)

The system is designed to be:
- Vendor-agnostic
- Canonical-data driven
- Easy to extend by non-software engineers

## Architecture Overview
Victron GX / MQTT

↓

Node-RED (Edge)

↓

PostgreSQL (Edge DB)

↓

(Optional sync to Cloud DB)

↓

Optimization / Analytics


Key concepts:
- All timestamps in **UTC**
- 15-minute resolution (default)
- Canonical point names across all sources

## Requirements

### Hardware
- Raspberry Pi 4 (recommended)
- SD card ≥ 16GB

### Software
- Raspberry Pi OS (64-bit)
- Docker
- Docker Compose
- Git

## Clone the Repository

```bash
git clone https://github.com/<your-username>/edgy-energy-platform.git
cd edgy-energy-platform
```

## Environment Variables
Copy the example file:
```bash
cp docker/.env.example docker/.env
```

Edit docker/.env:
  ```env
POSTGRES_DB=edgy
POSTGRES_USER=edgy
POSTGRES_PASSWORD=edgy123
TIMEZONE=UTC
```

## Start the Edge Stack (Raspberry Pi)
```bash
cd docker
docker compose -f docker-compose.edge.yml up -d
```

This starts:
- Node-RED → http://<raspi-ip>:1880
- PostgreSQL → port 5432

## Access Node-RED

From your browser:
```cpp
http://<raspberry-pi-ip>:1880
```

Or locally on the Pi:
```arduino
http://localhost:1880
```

## Initialize the Database
Enter the Postgres container:
```bash
docker exec -it edgy-postgres psql -U edgy -d edgy
```

Run schema scripts in order:
```sql
\i database/schema/01_sites.sql
\i database/schema/02_device_specs.sql
\i database/schema/03_telemetry.sql
\i database/schema/04_forecasts.sql
\i database/schema/05_profiles.sql
\i database/schema/06_point_mappings.sql
\i database/schema/07_asset_relations.sql
```

Seed canonical profiles:
```sql
\i database/seeds/profiles_seed.sql
```

## Load Node-RED Flows
1. Open Node-RED UI
2. Menu → Import
3. Import files from *node-red/flows/*
4. Deploy

## Data Model Rules
- **telemetry** → measured values only
- **forecasts** → predicted values
- **device_specs** → static + semi-static config
- **profiles** → canonical definitions
- **point_mappings** → vendor → canonical mapping
Full details: *docs/data-model.md*

## Supported Integrations
- Victron GX (MQTT)
- Mock data generators
- Future: Modbus, BACnet, REST

## Development Workflow
- Add new devices → *device_specs*
- Add new points → *profiles*
- Add new mappings → *point_mappings*
- Extend Node-RED via function library

## Contributing
1. Create a branch
2. Commit changes
3. Open a PR
