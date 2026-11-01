-- Guacamole connections: source of truth.
-- Idempotent: connections are matched by name (root group) and their parameters
-- are replaced, so edits made in the UI to these connections get overwritten.
-- Apply with: ./setup-guacamole-connections.sh

BEGIN;

CREATE TEMP TABLE seed (connection_name text, protocol text, parameters jsonb) ON COMMIT DROP;

INSERT INTO seed VALUES
  -- Workstation (Omarchy/Hyprland), wayvnc started from ~/.config/hypr/autostart.lua
  ('carbon', 'vnc', '{
    "hostname": "192.168.1.2",
    "port": "5900",
    "color-depth": "24"
  }');

INSERT INTO guacamole_connection (connection_name, protocol)
SELECT s.connection_name, s.protocol
FROM seed s
WHERE NOT EXISTS (
  SELECT 1 FROM guacamole_connection c
  WHERE c.connection_name = s.connection_name AND c.parent_id IS NULL
);

UPDATE guacamole_connection c
SET protocol = s.protocol
FROM seed s
WHERE c.connection_name = s.connection_name AND c.parent_id IS NULL;

DELETE FROM guacamole_connection_parameter p
USING guacamole_connection c, seed s
WHERE p.connection_id = c.connection_id
  AND c.connection_name = s.connection_name AND c.parent_id IS NULL;

INSERT INTO guacamole_connection_parameter (connection_id, parameter_name, parameter_value)
SELECT c.connection_id, kv.key, kv.value
FROM seed s
JOIN guacamole_connection c ON c.connection_name = s.connection_name AND c.parent_id IS NULL
CROSS JOIN LATERAL jsonb_each_text(s.parameters) kv;

-- Grant READ to the Guacamole user (psql -v guac_user=...)
INSERT INTO guacamole_connection_permission (entity_id, connection_id, permission)
SELECT e.entity_id, c.connection_id, 'READ'
FROM seed s
JOIN guacamole_connection c ON c.connection_name = s.connection_name AND c.parent_id IS NULL
JOIN guacamole_entity e ON e.name = :'guac_user' AND e.type = 'USER'
ON CONFLICT DO NOTHING;

COMMIT;
