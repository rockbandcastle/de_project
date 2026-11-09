-- ============================================================
-- 002_roles.sql
-- Этап 2.1b: сервисные пользователи БД, идемпотентно
-- Пароли — через psql-переменные (SET + current_setting)
-- ============================================================

-- Сохраняем пароли из psql-переменных в сессионные параметры
SET myvars.app_password      TO :'app_password';
SET myvars.ro_password       TO :'ro_password';
SET myvars.exporter_password TO :'exporter_password';

-- ---------- ГРУППЫ ----------
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'mfc_app') THEN
        CREATE ROLE mfc_app NOLOGIN;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'mfc_readonly') THEN
        CREATE ROLE mfc_readonly NOLOGIN;
    END IF;
END
$$;

-- ---------- ПОЛЬЗОВАТЕЛИ ----------
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'mfc_app_user') THEN
        EXECUTE format('CREATE ROLE mfc_app_user LOGIN PASSWORD %L',
                       current_setting('myvars.app_password'));
    ELSE
        EXECUTE format('ALTER ROLE mfc_app_user WITH PASSWORD %L',
                       current_setting('myvars.app_password'));
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'mfc_readonly_user') THEN
        EXECUTE format('CREATE ROLE mfc_readonly_user LOGIN PASSWORD %L',
                       current_setting('myvars.ro_password'));
    ELSE
        EXECUTE format('ALTER ROLE mfc_readonly_user WITH PASSWORD %L',
                       current_setting('myvars.ro_password'));
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'exporter') THEN
        EXECUTE format('CREATE ROLE exporter LOGIN PASSWORD %L',
                       current_setting('myvars.exporter_password'));
    ELSE
        EXECUTE format('ALTER ROLE exporter WITH PASSWORD %L',
                       current_setting('myvars.exporter_password'));
    END IF;
END
$$;

-- ---------- ЧЛЕНСТВО И ПРАВА ----------
GRANT mfc_app      TO mfc_app_user;
GRANT mfc_readonly TO mfc_readonly_user;
GRANT pg_monitor   TO exporter;
GRANT CONNECT ON DATABASE mfc_oltp TO exporter;

-- ---------- ПРАВА НА СХЕМЫ (если 001 уже прогнан) ----------
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_namespace WHERE nspname = 'catalog') THEN
        EXECUTE 'GRANT USAGE, CREATE ON SCHEMA catalog, sales, accounting, marketing TO mfc_app';
        EXECUTE 'GRANT USAGE ON SCHEMA catalog, sales, accounting, marketing TO mfc_readonly';
        EXECUTE 'GRANT USAGE ON SCHEMA catalog, sales, accounting, marketing TO exporter';
    END IF;
END
$$;