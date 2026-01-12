CREATE TABLE IF NOT EXISTS telemetry (
  ts           TIMESTAMPTZ NOT NULL,
  site_id      TEXT        NOT NULL,
  device_id    TEXT        NOT NULL,
  point_name   TEXT        NOT NULL,   -- canonical name
  value        DOUBLE PRECISION,
  unit         TEXT,
  quality      TEXT        NOT NULL DEFAULT 'good',
  meta         JSONB       NOT NULL DEFAULT '{}'::jsonb,

  PRIMARY KEY (ts, site_id, device_id, point_name),

  CONSTRAINT telemetry_quality_chk
    CHECK (quality IN ('good','bad','uncertain','missing'))
);

CREATE INDEX IF NOT EXISTS idx_telemetry_site_point_ts
  ON telemetry (site_id, point_name, ts DESC);

CREATE INDEX IF NOT EXISTS idx_telemetry_device_ts
  ON telemetry (site_id, device_id, ts DESC);
