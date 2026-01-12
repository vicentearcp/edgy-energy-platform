CREATE TABLE IF NOT EXISTS sites (
  site_id       TEXT PRIMARY KEY,
  name          TEXT,
  timezone      TEXT NOT NULL DEFAULT 'UTC',
  country       TEXT,
  meta          JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
