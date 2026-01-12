-- Your merged table: devices + device_config
CREATE TABLE IF NOT EXISTS device_specs (
  site_id       TEXT        NOT NULL,
  device_id     TEXT        NOT NULL,

  protocol      TEXT        NOT NULL,   -- mqtt, vrm, modbus, bacnet, etc
  address       TEXT,                   -- broker host, installation id, ip:port, etc

  vendor        TEXT,
  model         TEXT,
  fw_version    TEXT,

  profile_hint  TEXT,                   -- e.g. edgy.asset.battery.v1
  last_seen     TIMESTAMPTZ,
  status        TEXT        NOT NULL DEFAULT 'unknown', -- online/offline/unknown

  meta          JSONB       NOT NULL DEFAULT '{}'::jsonb,
  config        JSONB       NOT NULL DEFAULT '{}'::jsonb, -- static settings (limits, capacity, etc)

  PRIMARY KEY (site_id, device_id)
);

CREATE INDEX IF NOT EXISTS idx_device_specs_last_seen
  ON device_specs (site_id, last_seen DESC);

ALTER TABLE device_specs
  DROP CONSTRAINT IF EXISTS device_specs_status_chk;

ALTER TABLE device_specs
  ADD CONSTRAINT device_specs_status_chk
  CHECK (status IN ('online','offline','unknown'));
