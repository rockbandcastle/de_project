# КОНТЕКСТ: Data Platform «MFC Analytics»

## Цель проекта

Собрать end-to-end платформу данных в миниатюре: источники → OLTP → OLAP → трансформации → витрины → BI + ML/LLM-слой. Всё в Docker, всё в GitHub, всё воспроизводимо. Артефакт для портфолио + практика по всему стеку из резюме.

## Стек (полный)

**Источники:** CSV, REST API, PostgreSQL, MongoDB, MS SQL (эмуляция).
**Хранилища:** PostgreSQL (OLTP), ClickHouse (OLAP), MinIO/S3 (raw + Parquet + Iceberg), Qdrant (векторная).
**Обработка:** Python (Pandas, Selenium, Requests), Spark/PySpark, Spark Structured Streaming, dbt.
**Оркестрация:** Apache Airflow.
**CDC:** Debezium + Kafka + Zookeeper.
**Федерация:** Trino.
**DQ:** Great Expectations, dbt tests.
**BI:** Apache Superset, Power BI (DAX), Grafana.
**ML:** scikit-learn, CatBoost, MLflow, FastAPI.
**LLM:** LangChain, Qdrant, OpenAI API / локальная модель.
**Инфра:** Docker, Docker Compose, Kubernetes (k3s).
**CI/CD:** GitHub Actions, GitLab CI, Bash.
**Мониторинг:** Prometheus + Grafana.

## Архитектура (целевая)

```
[Источник: CSV/API/MongoDB/Postgres]
         │
         ▼
[Python-скрипт: генератор + загрузчик]
         │
         ├──────────────► [PostgreSQL] (OLTP)
         │
         ├──────────────► [ClickHouse] (OLAP)
         │
         └──────────────► [MinIO/S3] (raw, Parquet)
                                │
                                ▼
                    [Apache Spark / PySpark]
                    (join Postgres + ClickHouse + MongoDB,
                     агрегации, очистка, Iceberg)
                                │
                                ▼
                    [ClickHouse: витрины / mart]
                                │
                    ┌───────────┴───────────┐
                    ▼                       ▼
            [Apache Superset]        [Power BI]
            (дашборды)               (дашборды + DAX)

Оркестрация:    [Apache Airflow]
Трансформации:  [dbt] (raw → staging → mart, SCD2)
CDC:            [Debezium] → [Kafka] → [Spark Streaming]
Федерация:      [Trino] (Postgres + ClickHouse + Iceberg)
DQ:             [Great Expectations]
ML:             [scikit-learn, CatBoost] → [MLflow] → [FastAPI]
LLM:            [LangChain] + [Qdrant] + [OpenAI API]
Мониторинг:     [Prometheus] + [Grafana]
Инфра:          [Docker Compose] → [k3s]
CI/CD:          [GitHub Actions] + [GitLab CI]
```

---

## План по этапам

### Этап 0. Подготовка (1–2 дня)
- Создать GitHub-репозиторий.
- Структура папок: `docker/`, `dags/`, `scripts/`, `spark_jobs/`, `dbt/`, `ml/`, `llm/`, `data/`, `docs/`.
- `.gitignore` (data, .env, __pycache__, логи).
- Стартовый `README.md`.

### Этап 1. Docker Compose + базы + мониторинг (4–5 дней)
Сервисы в `docker-compose.yml`:
- **PostgreSQL** (OLTP)
- **ClickHouse** (OLAP)
- **MinIO** (S3, Parquet)
- **MongoDB** (источник)
- **Prometheus + Grafana** (мониторинг)

Практики:
- Multi-stage build для своего Python-образа.
- Healthcheck для каждого сервиса.
- `.env` для паролей и портов.
- MinIO: lifecycle policy, versioning, pre-signed URL.

### Этап 2. Python-скрипты + DQ (5–6 дней)
- Генератор данных → CSV.
- Загрузчики в Postgres, ClickHouse, MongoDB.
- UPSERT, watermark, backfill, idempotency.
- **Great Expectations** — DQ-проверки (Expectation Suite, Data Docs, Checkpoints).
- Партиционирование в ClickHouse (MergeTree, ReplacingMergeTree, Materialized View, Dictionary).

### Этап 3. Airflow + Bash (4–5 дней)
- Airflow (webserver + scheduler) в Docker.
- DAG: генерация → загрузка → DQ.
- Bash-скрипты для запуска, миграций, бэкапов.
- Практики: TaskGroup, BranchPythonOperator, XCom, SLAs.

### Этап 4. Spark / PySpark + Iceberg (7–8 дней)
- Spark master + worker в Docker.
- Чтение из Postgres + ClickHouse + MongoDB (JDBC).
- Запись витрин в **Iceberg** поверх MinIO (Parquet).
- Оптимизации: broadcast join, data skew, партиционирование, predicate pushdown.
- Практики: UDF, Spark UI (скриншоты до/после), checkpointing, window functions.
- Iceberg: time travel, schema evolution, partition evolution.
- Запуск через Airflow.

### Этап 4.5. Trino (2–3 дня)
- Trino в Docker.
- Подключение к Postgres, ClickHouse, Iceberg.
- Практики: cross-catalog join, создание view, EXPLAIN.
- Опционально: Superset через Trino.

### Этап 5. dbt + SCD Type 2 + Medallion (5–6 дней)
- dbt в Docker (или локально).
- Слои: **raw → staging → mart** (Medallion).
- Модели: очистка, агрегации, витрины.
- **SCD Type 2** — историзация атрибутов.
- Тесты dbt.
- Документация + lineage.
- Практики: incremental модели, snapshots, макросы, exposures, seeds, tags.

### Этап 6. Superset (3–4 дня)
- Superset в Docker.
- Подключение к ClickHouse (или Trino).
- Дашборды: обращения по дням, топ услуг, загрузка отделов.
- Практики: SQL Lab, row-level security, alerts & reports.

### Этап 7. Power BI (2–3 дня)
- Подключение к ClickHouse (ODBC).
- DAX-меры.
- Практики: меры vs вычисляемые столбцы, time intelligence (`TOTALYTD`, `SAMEPERIODLASTYEAR`), RLS.
- Скриншоты в `docs/`.

### Этап 8. ML + MLflow + FastAPI (7–8 дней)
- **scikit-learn**: KMeans (кластеризация), регрессия (RandomForest).
- **CatBoost**: классификация/регрессия, feature importance, SHAP.
- **MLflow**: трекинг, Model Registry, autolog, artifacts.
- **FastAPI**: обёртка модели в REST API (Pydantic, Swagger UI, background tasks).
- Практики sklearn: Pipeline, cross-validation, GridSearchCV.
- Результаты — обратно в ClickHouse.

### Этап 9. LLM + RAG + LangChain + Qdrant (7–8 дней)
- **Qdrant** в Docker — векторная БД.
- Эмбеддинги обращений → Qdrant.
- **LangChain** — оркестрация LLM-цепочек.
- RAG-поиск по обращениям.
- LLM для генерации тестовых данных и анализа ошибок.
- Практики: prompt templates, chains, memory, agents + tools.
- Qdrant: payload-фильтры, named vectors, snapshot.

### Этап 10. CI/CD (3–4 дня)
- **GitHub Actions**: линтеры (ruff/flake8), тесты (pytest), сборка Docker-образа.
- **GitLab CI**: параллельно (или как основной).
- Тесты dbt в CI.
- Практики: matrix builds, cache, artifacts, manual approval.

### Этап 11. Kafka + Debezium + Spark Streaming (7–8 дней)
- **Kafka + Zookeeper** в Docker.
- **Debezium** — CDC из Postgres → Kafka.
- Продюсер (генерация новых обращений) + консьюмер (запись в ClickHouse).
- **Spark Structured Streaming** — чтение из Kafka → Iceberg.
- Практики Kafka: consumer groups, partitions, retention policy.
- Практики Debezium: snapshot + incremental, SMT, мониторинг коннектора.
- Практики Spark Streaming: checkpointing, watermark, output modes.

### Этап 12. Kubernetes / k3s (5–7 дней)
- k3s / Minikube в отдельной виртуалке.
- Манифесты для одного сервиса.
- Практики: ConfigMap + Secret, liveness/readiness probes, HPA.
- Деплой, логи, масштабирование.

### Этап 13. Финализация (4–5 дней)
- Большой README: описание, архитектурная схема, стек, инструкция запуска, скриншоты, список фич, чему научился.
- Видео-демо (опционально).
- Обновление резюме + ссылка на GitHub.

---

## Временная шкала

| Этап | Длительность | Накопительно |
|------|--------------|--------------|
| 0. Подготовка | 1–2 дня | 2 дня |
| 1. Docker + базы + мониторинг | 4–5 дней | 7 дней |
| 2. Python + DQ | 5–6 дней | 13 дней |
| 3. Airflow + Bash | 4–5 дней | 18 дней |
| 4. Spark + Iceberg | 7–8 дней | 26 дней |
| 4.5. Trino | 2–3 дня | 29 дней |
| 5. dbt + SCD2 + Medallion | 5–6 дней | 35 дней |
| 6. Superset | 3–4 дня | 39 дней |
| 7. Power BI | 2–3 дня | 42 дня |
| 8. ML + MLflow + FastAPI | 7–8 дней | 50 дней |
| 9. LLM + RAG + LangChain + Qdrant | 7–8 дней | 58 дней |
| 10. CI/CD | 3–4 дня | 62 дня |
| 11. Kafka + Debezium + Spark Streaming | 7–8 дней | 70 дней |
| 12. k3s | 5–7 дней | 77 дней |
| 13. Финализация | 4–5 дней | **~2.5–3 месяца** |

По 1–2 часа в день — 2.5–3 месяца. По 3–4 часа — 1.5–2 месяца.

---

## Приоритеты при нехватке времени

**Обязательно:** 0 → 1 → 2 → 3 → 4 → 5 → 6 → 8 → 9 → 10 → 11.
**Можно отложить:** 4.5 (Trino), 7 (Power BI), 12 (k3s).

**Обязательные практики внутри этапов:**
- dbt: инкрементальные модели, snapshots.
- Airflow: TaskGroup, BranchPythonOperator.
- Iceberg: time travel.
- Kafka: consumer groups.
- Debezium: snapshot + incremental.
- Spark Streaming: checkpointing.
- MLflow: Model Registry.

---

## Правила работы с планом

1. **Порядок этапов не случайный.** Каждый следующий опирается на предыдущий.
2. **Каждый этап — рабочий.** Не переходишь к следующему, пока текущий не работает.
3. **Коммит после каждого этапа.** История — артефакт.
4. **README обновляешь по ходу.**
5. **Не идеально — а работает.** Лучше запустить, чем полировать.
6. **Если застрял** — гуглишь, спрашиваешь, откатываешься. Это нормально.

---

## Формат нового чата

Каждый новый чат — это один этап. В начале чата пишешь:

```
Этап N: [название]
Контекст: см. вложение.
Задача: [что нужно сделать]
```

И прикладываешь этот документ. Дальше идём по шагам: структура, файлы, запуск, проверка.
