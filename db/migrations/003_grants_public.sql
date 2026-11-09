-- ============================================================
-- 003_grants_public.sql
-- Этап 2.1c: гранты на public-справочники для сервисных ролей
-- (в 001 забыли public: раздавали права только на бизнес-схемы)
-- ============================================================

-- mfc_readonly: только чтение справочников
GRANT USAGE ON SCHEMA public TO mfc_readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO mfc_readonly;
ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT SELECT ON TABLES TO mfc_readonly;

-- mfc_app: полные права (включая запись) на справочники
GRANT USAGE ON SCHEMA public TO mfc_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO mfc_app;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO mfc_app;
ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO mfc_app;
ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT USAGE, SELECT ON SEQUENCES TO mfc_app;

-- exporter: чтение справочников (для мониторинга — на будущее)
GRANT USAGE ON SCHEMA public TO exporter;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO exporter;
ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT SELECT ON TABLES TO exporter;
