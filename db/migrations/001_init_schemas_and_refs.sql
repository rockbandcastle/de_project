-- ============================================================
-- 001_init_schemas_and_refs.sql
-- Этап 2.1: схемы, служебные роли, public-справочники
-- ============================================================

-- ---------- СХЕМЫ ----------
CREATE SCHEMA IF NOT EXISTS catalog;      -- товары, продавцы, бренды, склады
CREATE SCHEMA IF NOT EXISTS sales;        -- клиенты, заказы, доставки, возвраты
CREATE SCHEMA IF NOT EXISTS accounting;   -- транзакции, проводки, выплаты, комиссии
CREATE SCHEMA IF NOT EXISTS marketing;    -- акции, просмотры, корзина, поиск

COMMENT ON SCHEMA catalog    IS 'Домен: каталог товаров, продавцы, бренды, склады';
COMMENT ON SCHEMA sales      IS 'Домен: клиенты, заказы, доставки, возвраты';
COMMENT ON SCHEMA accounting IS 'Домен: двойная запись, транзакции, выплаты, комиссии';
COMMENT ON SCHEMA marketing  IS 'Домен: акции, поведенческие события, поиск';

-- ---------- РОЛИ / ПОЛЬЗОВАТЕЛИ ----------
-- Принцип: один сервис — один пользователь, минимум прав.
-- Пароли НЕ здесь (в .env), здесь только роли и право на их использование.
-- Создание пользователей с паролями — отдельным скриптом (см. ниже).

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'mfc_app') THEN
        CREATE ROLE mfc_app NOLOGIN;           -- группа: права на бизнес-схемы
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'mfc_readonly') THEN
        CREATE ROLE mfc_readonly NOLOGIN;      -- группа: только чтение (BI, dbt, Trino)
    END IF;
END
$$;

-- Группе mfc_app — полные права на бизнес-схемы
GRANT USAGE, CREATE ON SCHEMA catalog, sales, accounting, marketing TO mfc_app;
GRANT ALL PRIVILEGES ON ALL TABLES    IN SCHEMA catalog, sales, accounting, marketing TO mfc_app;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA catalog, sales, accounting, marketing TO mfc_app;
-- На будущие объекты в этих схемах — тоже
ALTER DEFAULT PRIVILEGES IN SCHEMA catalog, sales, accounting, marketing
    GRANT ALL ON TABLES    TO mfc_app;
ALTER DEFAULT PRIVILEGES IN SCHEMA catalog, sales, accounting, marketing
    GRANT ALL ON SEQUENCES TO mfc_app;

-- Группе mfc_readonly — только чтение
GRANT USAGE ON SCHEMA catalog, sales, accounting, marketing TO mfc_readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA catalog, sales, accounting, marketing TO mfc_readonly;
ALTER DEFAULT PRIVILEGES IN SCHEMA catalog, sales, accounting, marketing
    GRANT SELECT ON TABLES TO mfc_readonly;

-- ---------- EXTENSIONS ----------
CREATE EXTENSION IF NOT EXISTS pgcrypto;   -- gen_random_uuid()
CREATE EXTENSION IF NOT EXISTS btree_gin;  -- GIN по скалярным (пригодится)

-- ---------- PUBLIC: Справочники ----------

-- Регионы РФ
CREATE TABLE IF NOT EXISTS public.regions (
    region_id       BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code            VARCHAR(5)  NOT NULL UNIQUE,   -- код региона (2 цифры)
    name            VARCHAR(100) NOT NULL UNIQUE,
    federal_district VARCHAR(50) NOT NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.regions IS 'Справочник регионов РФ';

-- Города
CREATE TABLE IF NOT EXISTS public.cities (
    city_id         BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    region_id       BIGINT NOT NULL REFERENCES public.regions(region_id),
    name            VARCHAR(100) NOT NULL,
    population      INTEGER,
    is_millionnik   BOOLEAN NOT NULL DEFAULT FALSE,  -- >1 млн жителей
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (region_id, name)
);
CREATE INDEX IF NOT EXISTS idx_cities_region ON public.cities(region_id);
COMMENT ON TABLE public.cities IS 'Справочник городов РФ';

-- Способы оплаты
CREATE TABLE IF NOT EXISTS public.payment_methods (
    payment_method_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code            VARCHAR(30) NOT NULL UNIQUE,   -- card, sbp, cash, wallet, bnpl
    name            VARCHAR(100) NOT NULL,
    is_online       BOOLEAN NOT NULL DEFAULT TRUE
);
COMMENT ON TABLE public.payment_methods IS 'Способы оплаты (карта, СБП, наличные, кошелёк, BNPL)';

-- Способы доставки
CREATE TABLE IF NOT EXISTS public.delivery_methods (
    delivery_method_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code            VARCHAR(30) NOT NULL UNIQUE,   -- courier, pickup, post, express
    name            VARCHAR(100) NOT NULL,
    avg_days        SMALLINT NOT NULL DEFAULT 3
);
COMMENT ON TABLE public.delivery_methods IS 'Способы доставки (курьер, ПВЗ, почта, экспресс)';
