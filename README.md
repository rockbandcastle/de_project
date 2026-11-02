# MFC Analytics — Data Platform

End-to-end платформа данных в миниатюре: источники -> OLTP -> OLAP -> трансформации -> витрины -> BI + ML/LLM-слой.
Всё в Docker, всё воспроизводимо, всё в одном репозитории.

## Цель

Артефакт для портфолио + практика по всему data-стеку:
PostgreSQL, ClickHouse, MinIO/S3, MongoDB, Spark/PySpark, dbt, Airflow, Debezium + Kafka, Trino, Great Expectations, Superset, Power BI, scikit-learn, CatBoost, MLflow, FastAPI, LangChain + Qdrant, Docker, k3s, GitHub Actions / GitLab CI, Prometheus + Grafana.

## Статус

**Этап 1 — Docker Compose + базы + мониторинг.** ✅

Запущены и работают:
- PostgreSQL 16 (OLTP)
- ClickHouse 24.3 (OLAP) — со встроенным Prometheus endpoint
- MinIO (S3) — с публичным доступом к метрикам
- MongoDB 7 (источник)
- Prometheus 2.53 (сбор метрик, retention 15 дней)
- Grafana 11.1 (на Postgres, датасорс Prometheus через provisioning)
- postgres_exporter (метрики Postgres)

Дашборды (provisioning, в git):
- `PostgreSQL Overview` — UP, connections, transactions, rows, db size
- `ClickHouse Overview` — UP, queries, memory, rows read/written, disk I/O
- `MinIO Overview` — UP, cluster nodes/drives, traffic, capacity, node resources

## Архитектура (текущая)

Postgres ──SQL──► postgres_exporter ──┐
ClickHouse ──/metrics──────────────────┼──► Prometheus ──► Grafana
MinIO ──/minio/v2/metrics/cluster─────┘

## Быстрый старт
git clone git@github.com:rockbandcastle/de_project.git
cd de_project
cp .env.example .env
docker compose up -d

После старта (30–60 секунд):
- Grafana: http://localhost:3000 (admin / пароль из .env)
- Prometheus: http://localhost:9090
- MinIO Console: http://localhost:9011
- ClickHouse HTTP: http://localhost:8123
- Postgres: localhost:5432

## Скриншоты
docs/screenshots/

## Структура репозитория
docker/        # Docker Compose, Dockerfile'ы, конфиги сервисов
  grafana/     # provisioning (datasources, dashboards)
  clickhouse/  # config.xml с prometheus endpoint
  prometheus/  # prometheus.yml
dags/          # Airflow DAG'и
scripts/       # Python-генераторы, загрузчики, bash-скрипты
spark_jobs/    # PySpark-джобы
dbt/           # dbt-проект (raw -> staging -> mart)
ml/            # ML: sklearn/CatBoost, MLflow, FastAPI
llm/           # LLM: LangChain, RAG, Qdrant
sql/           # DDL, миграции, запросы
data/          # сырые/сгенерированные данные (в .gitignore)
docs/          # схемы, скриншоты, план
.github/       # CI (GitHub Actions)

## Лицензия
MIT