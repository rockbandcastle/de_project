-- ============================================================
-- 006_catalog_warehouses.sql
-- Этап 2.2.4: склады (FBO — маркетплейса, FBS — продавца)
-- ============================================================

CREATE TABLE IF NOT EXISTS catalog.warehouses (
    warehouse_id   BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    warehouse_uuid UUID NOT NULL DEFAULT gen_random_uuid() UNIQUE,
    seller_id      BIGINT REFERENCES catalog.sellers(seller_id),
    city_id        BIGINT NOT NULL REFERENCES public.cities(city_id),
    name           VARCHAR(150) NOT NULL,
    type           VARCHAR(10)  NOT NULL CHECK (type IN ('FBO','FBS')),
    is_active      BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at     TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_at     TIMESTAMPTZ  NOT NULL DEFAULT now(),
    -- FBO => seller_id IS NULL; FBS => seller_id IS NOT NULL
    CONSTRAINT warehouses_type_seller_chk CHECK (
        (type = 'FBO' AND seller_id IS NULL) OR
        (type = 'FBS' AND seller_id IS NOT NULL)
    )
);

CREATE INDEX IF NOT EXISTS idx_warehouses_seller ON catalog.warehouses(seller_id);
CREATE INDEX IF NOT EXISTS idx_warehouses_city   ON catalog.warehouses(city_id);
CREATE INDEX IF NOT EXISTS idx_warehouses_type   ON catalog.warehouses(type);
CREATE INDEX IF NOT EXISTS idx_warehouses_active ON catalog.warehouses(is_active);

COMMENT ON TABLE  catalog.warehouses                IS 'Склады: FBO (маркетплейса) и FBS (продавца)';
COMMENT ON COLUMN catalog.warehouses.seller_id      IS 'NULL для FBO (склад маркетплейса), NOT NULL для FBS';
COMMENT ON COLUMN catalog.warehouses.type           IS 'FBO — Fulfillment by Operator, FBS — Fulfillment by Seller';
COMMENT ON COLUMN catalog.warehouses.is_active      IS 'Склад может быть закрыт, история остаётся';
COMMENT ON COLUMN catalog.warehouses.warehouse_uuid IS 'Внешний стабильный идентификатор (для CDC/API)';
