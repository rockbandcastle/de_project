# PROGRESS — MFC Analytics

> Журнал состояния проекта. Обновляется после каждого закрытого шага.
> Если чат «уплыл» — сверяемся с этим файлом. Если начат новый чат — копируем этот файл + блок «Контекст проекта» из начала диалога.

---

## Текущее состояние

- **Этап:** 2 — Моделирование данных маркетплейса
- **Шаг:** 2.1 — ЗАКРЫТ (схемы, роли, public-справочники, grafana db)
- **Следующий шаг:** 2.2 — домен `catalog` (миграция `005_catalog.sql`)
- **Репозиторий:** git@github.com:rockbandcastle/de_project.git (ветка `main`)
- **Последний коммит:** `feat(db): init schemas, service roles, public refs, grafana db (step 2.1)`

---

## Что сделано (Этап 2, Шаг 2.1)

- [x] Почищен `.env` от дублей (один комплект ключей: `mfc_user`/`mfc_oltp`, `mfc_olap`, `mfc_source`)
- [x] `db/migrations/001_init_schemas_and_refs.sql` — 4 бизнес-схемы (`catalog`, `sales`, `accounting`, `marketing`), группы-роли `mfc_app`/`mfc_readonly`, расширения `pgcrypto`/`btree_gin`, 4 справочника в `public` (`regions`, `cities`, `payment_methods`, `delivery_methods`)
- [x] `db/migrations/002_roles.sql` — пользователи `mfc_app_user`, `mfc_readonly_user`, `exporter` (с `pg_monitor`); пароли через psql-переменные из `.env`
- [x] `db/migrations/003_grants_public.sql` — фикс: гранты на `public` для `mfc_app`/`mfc_readonly`/`exporter` (в `001` забыли)
- [x] `db/migrations/004_grafana_db.sql` — роль и база `grafana` (воспроизводимо, идемпотентно)
- [x] Пересоздан Postgres с правильными именами (`mfc_user`/`mfc_oltp`), миграции накатаны в `mfc_oltp`
- [x] Перезапущены `postgres_exporter` (`pg_up=1`) и Grafana (datasource Prometheus + 3 дашборда)
- [x] `.env.example` приведён в порядок, `.gitignore` дополнен `!.env.example`
- [x] Коммит и пуш (Шаг 2.1 закрыт)

---

## Открытые вопросы / заметки

- `S3_ENDPOINT=http://minio:9000` в `.env` — внутренний порт MinIO в compose-сети; наружу `9010`. Проверить при работе с S3/Parquet (Шаг 2.2+ или позже).
- `AIRFLOW__DATABASE__SQL_ALCHEMY_CONN` содержит `${...}` — это **интерполяция docker compose**, не bash. При `source .env` остаётся литералом (так и нужно).
- `mfc_app`/`mfc_readonly` — группы `NOLOGIN`; реальные логины — `mfc_app_user`/`mfc_readonly_user`.
- `exporter` — LOGIN, роль `pg_monitor`, `CONNECT` на `mfc_oltp`.
- Grafana хранит данные в Postgres (база `grafana`, юзер `grafana`), отдельно от бизнес-данных.

---

## Правила работы (напоминание)

1. **Один шаг = одно сообщение.** Один шаг → проверка → следующий шаг.
2. **Якорь перед шагом:** одна строка «где мы / что делаем / что должно получиться».
3. **Стоп-точка перед уходом в дебри:** «фиксируем: мы на X, сделано Y, следующее Z».
4. **Best practice, «полный фарш»**, отдельные юзеры БД, пароли в `.env`, provisioning, права через роли.
5. **К каждой команде — краткая расшифровка** (что делает; для незнакомых — по флагам).
6. **Каждый этап — коммит** (`feat`/`fix`/`chore`/`docs`).
7. **Данные = volume, конфиги = bind mount.** `down` без `-v` безопасен, `-v` удаляет данные.
8. **Терминал — Ubuntu (WSL)**, не PowerShell.
9. **Если непонятно — спрашиваем до полного понимания.** Не «киваем», а разбираем.

---

## План Этапа 2 (детально)

- [x] 2.1 — служебное + `public`-справочники
- [ ] 2.2 — домен `catalog`: `categories`, `brands`, `sellers`, `warehouses`, `products`, `product_variants`, `product_prices_history`
- [ ] 2.3 — домен `sales`: `customers`, `customer_addresses`, `orders`, `order_items`, `order_status_history`, `shipments`, `returns`
- [ ] 2.4 — домен `accounting`: `chart_of_accounts`, `transactions`, `ledger_entries`, `refunds`, `payouts`, `fees`
- [ ] 2.5 — домен `marketing`: `promotions`, `promotion_products`, `product_views`, `cart_events`, `search_queries`
- [ ] 2.6 — индексы, FK, CHECK-констрейнты, комментарии, сиды справочников (регионы/города/категории/план счетов)
- [ ] 2.7 — Python-генератор синтетических данных
- [ ] 2.8 — загрузка данных

---

## Решения по DDL (зафиксировано на Шаге 2.1)

1. **PK:** `BIGINT GENERATED ALWAYS AS IDENTITY` + отдельные `UUID` колонки для внешних ID (`orders`, `customers`, `sellers`, `products`, `transactions`).
2. **Деньги:** `NUMERIC(12,2)`.
3. **Валюта:** RUB, колонка `currency CHAR(3) DEFAULT 'RUB'` в `orders`.
4. **Дерево категорий:** `parent_id` + материализованный `path TEXT` (без ltree).
5. **Событийные таблицы** (`product_views`, `cart_events`, `search_queries`) — включаем в Этап 2, генерируем умеренно.
6. **`order_status_history` + поле `status` в `orders`** — оба.
7. **Схемы в Postgres:** разбиваем по доменам — `catalog`, `sales`, `accounting`, `marketing` (+ `public` для справочников).

---

## Полезные команды (шпаргалка)

```bash
# подгрузить .env в текущую сессию
set -a; source ./.env; set +a

# применить миграцию
docker exec -i mfc_postgres psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -v ON_ERROR_STOP=1 < db/migrations/NNN_*.sql

# с паролями через psql-переменные (как в 002/004)
docker exec -i mfc_postgres psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -v ON_ERROR_STOP=1 \
  -v app_password="$PG_APP_PASSWORD" -v ro_password="$PG_READONLY_PASSWORD" \
  -v exporter_password="$POSTGRES_EXPORTER_PASSWORD" -v grafana_password="$GRAFANA_DB_PASSWORD" \
  < db/migrations/NNN_*.sql

# проверить схемы/таблицы/роли
docker exec -i mfc_postgres psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "\dn"
docker exec -i mfc_postgres psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "\dt public.*"
docker exec -i mfc_postgres psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "\du"

# healthcheck exporter / grafana
curl -s http://localhost:9187/metrics | grep -E '^pg_up '
curl -s -u admin:"$GRAFANA_ADMIN_PASSWORD" http://localhost:3000/api/datasources | head -c 500

Последнее обновление: Шаг 2.1 закрыт, коммит 5b39b75
