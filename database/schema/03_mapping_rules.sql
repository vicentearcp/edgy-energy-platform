-- Mapping raw protocol points to canonical points
CREATE TABLE IF NOT EXISTS mapping_rules (
  protocol       TEXT NOT NULL,             -- mqtt, modbus, bacnet, etc
  raw_topic      TEXT,                      -- human name if available
  canonical_name TEXT NOT NULL,             -- to canonical_points.canonical_name
  scale          DOUBLE PRECISION,
  unit_override  TEXT,
);
