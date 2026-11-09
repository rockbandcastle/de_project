-- ============================================================
-- 004_grafana_db.sql
-- Этап 2.1d: роль и база для Grafana (воспроизводимо)
-- Пароль — через psql-переменную grafana_password (из .env)
-- ============================================================

-- Сохраняем пароль из psql-переменной в сессионный параметр
SET myvars.grafana_password TO :'grafana_password';

-- Роль grafana (LOGIN, без суперправ — только владелец своей базы)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'grafana') THEN
        EXECUTE format('CREATE ROLE grafana LOGIN PASSWORD %L',
                       current_setting('myvars.grafana_password'));
    ELSE
        EXECUTE format('ALTER ROLE grafana WITH PASSWORD %L',
                       current_setting('myvars.grafana_password'));
    END IF;
END
$$;

-- База grafana (CREATE DATABASE нельзя внутри DO/транзакции — через \gexec)
SELECT format('CREATE DATABASE grafana OWNER grafana')
WHERE NOT EXISTS (SELECT 1 FROM pg_database WHERE datname = 'grafana')
\gexec

-- На всякий случай: если база уже была, но с другим owner — поправим
-- (безопасно: ALTER DATABASE ... OWNER TO идемпотентен по сути)
SELECT format('ALTER DATABASE grafana OWNER TO grafana')
WHERE EXISTS (SELECT 1 FROM pg_database WHERE datname = 'grafana')
\gexec

-- Права: grafana владеет своей базой, но на public-схему в ней
-- в PG15+ PUBLIC лишён CREATE — выдадим владельцу явно
\connect grafana
GRANT ALL ON SCHEMA public TO grafana;
