# Data Platform

End-to-end платформа данных в миниатюре: источники → OLTP → OLAP → трансформации → витрины → BI + ML/LLM-слой.
Всё в Docker, всё воспроизводимо, всё в одном репозитории.

## Цель

Артефакт для портфолио + практика по всему data-стеку:
PostgreSQL, ClickHouse, MinIO/S3, MongoDB, Spark/PySpark, dbt, Airflow,
Debezium + Kafka, Trino, Great Expectations, Superset, Power BI,
scikit-learn, CatBoost, MLflow, FastAPI, LangChain + Qdrant,
Docker, k3s, GitHub Actions / GitLab CI, Prometheus + Grafana.

## Статус

**Этап 0 — Подготовка.** Репозиторий инициализирован, структура папок создана.

План по этапам — см. `docs/PLAN.md`.

## Быстрый старт

> Запуск появится после Этапа 1 (Docker Compose + базы).

```bash
git clone git@github.com:rockbandcastle/de_project.git
cd de_project
cp .env.example .env      # заполнить пароли
# docker compose up -d    # после Этапа 1


Структура репозитория
docker/        # Docker Compose, Dockerfile'ы, конфиги сервисов
dags/          # Airflow DAG'и
scripts/       # Python-генераторы, загрузчики, bash-скрипты
spark_jobs/    # PySpark-джобы
dbt/           # dbt-проект (raw → staging → mart)
ml/            # ML: sklearn/CatBoost, MLflow, FastAPI
llm/           # LLM: LangChain, RAG, Qdrant
sql/           # DDL, миграции, запросы
data/          # сырые/сгенерированные данные (в .gitignore)
docs/          # схемы, скриншоты, план
.github/       # CI (GitHub Actions)
