CREATE TABLE IF NOT EXISTS measurement_live(
  ts           TIMESTAMPTZ,
  site_id      TEXT,
  device_id    TEXT,
  point_name   TEXT,
  value        DOUBLE PRECISION,
  unit         TEXT,
  quality      TEXT
);
