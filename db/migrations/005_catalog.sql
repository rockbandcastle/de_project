-- ============================================================
-- 005_catalog.sql
-- Этап 2.2: домен catalog — дерево категорий, бренды, продавцы,
--            склады, товары, варианты, история цен
-- Порядок: categories → brands → sellers → warehouses →
--          products → product_variants → product_prices_history
-- ============================================================

-- ---------- categories: дерево категорий ----------
CREATE TABLE IF NOT EXISTS catalog.categories (
    category_id   BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    parent_id     BIGINT REFERENCES catalog.categories(category_id) ON DELETE RESTRICT,
    name          VARCHAR(200) NOT NULL,
    slug          VARCHAR(200) NOT NULL UNIQUE,
    level         SMALLINT NOT NULL CHECK (level >= 1),
    path          TEXT NOT NULL,                -- материализованный путь: /1/5/12/
    is_active     BOOLEAN NOT NULL DEFAULT TRUE,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT categories_name_parent_uniq UNIQUE (parent_id, name)
);

CREATE INDEX IF NOT EXISTS idx_categories_parent ON catalog.categories(parent_id);
CREATE INDEX IF NOT EXISTS idx_categories_path   ON catalog.categories(path text_pattern_ops);
CREATE INDEX IF NOT EXISTS idx_categories_level  ON catalog.categories(level);

COMMENT ON TABLE  catalog.categories            IS 'Дерево категорий товаров (self-ref, материализованный path)';
COMMENT ON COLUMN catalog.categories.parent_id  IS 'Родительская категория; NULL для корневых';
COMMENT ON COLUMN catalog.categories.slug       IS 'URL-идентификатор, уникальный';
COMMENT ON COLUMN catalog.categories.level      IS 'Уровень вложенности: 1 = корень';
COMMENT ON COLUMN catalog.categories.path       IS 'Материализованный путь вида /1/5/12/ для поиска поддерева LIKE';

-- ---------- brands: бренды ----------
CREATE TABLE IF NOT EXISTS catalog.brands (
    brand_id    BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name        VARCHAR(150) NOT NULL UNIQUE,
    slug        VARCHAR(150) NOT NULL UNIQUE,
    country     VARCHAR(60),
    is_active   BOOLEAN NOT NULL DEFAULT TRUE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE  catalog.brands           IS 'Бренды товаров (Apple, Samsung, ...)';
COMMENT ON COLUMN catalog.brands.country   IS 'Страна происхождения бренда (свободный текст)';
COMMENT ON COLUMN catalog.brands.slug      IS 'URL-идентификатор, уникальный';

-- ---------- sellers: продавцы (мерчанты) ----------
CREATE TABLE IF NOT EXISTS catalog.sellers (
    seller_id     BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    seller_uuid   UUID NOT NULL DEFAULT gen_random_uuid() UNIQUE,
    name          VARCHAR(200) NOT NULL,
    inn           CHAR(12) NOT NULL UNIQUE,
    region_id     BIGINT NOT NULL REFERENCES public.regions(region_id),
    city_id       BIGINT REFERENCES public.cities(city_id),
    status        VARCHAR(20) NOT NULL DEFAULT 'active'
                  CHECK (status IN ('active','suspended','closed')),
    rating        NUMERIC(3,2) CHECK (rating >= 0 AND rating <= 5),
    registered_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT sellers_inn_len CHECK (char_length(inn) IN (10, 12))
);

CREATE INDEX IF NOT EXISTS idx_sellers_region ON catalog.sellers(region_id);
CREATE INDEX IF NOT EXISTS idx_sellers_city   ON catalog.sellers(city_id);
CREATE INDEX IF NOT EXISTS idx_sellers_status ON catalog.sellers(status);
CREATE INDEX IF NOT EXISTS idx_sellers_registered_at ON catalog.sellers(registered_at);

COMMENT ON TABLE  catalog.sellers               IS 'Продавцы (мерчанты) маркетплейса';
COMMENT ON COLUMN catalog.sellers.seller_uuid   IS 'Внешний стабильный идентификатор (для CDC/API)';
COMMENT ON COLUMN catalog.sellers.inn           IS 'ИНН: 10 цифр (юрлицо) или 12 (ИП)';
COMMENT ON COLUMN catalog.sellers.status        IS 'active / suspended / closed';
COMMENT ON COLUMN catalog.sellers.rating        IS 'Рейтинг продавца 0.00–5.00';
COMMENT ON COLUMN catalog.sellers.registered_at IS 'Дата регистрации (когортный анализ)';
