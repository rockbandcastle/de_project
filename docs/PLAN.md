Обновлённый план (v2)
Этап 0. Подготовка (1–2 дня) — ✅ пройден

Без изменений. Ты уже сделал:

    GitHub-репозиторий.

    Структура папок.

    .gitignore.

    README.md.

Добавь в README сразу: описание проекта, стек, архитектурную схему (можно нарисовать позже, но место зарезервируй).
Этап 1. Docker Compose + базы + мониторинг (4–5 дней)

Сервисы:

    PostgreSQL (OLTP)

    ClickHouse (OLAP)

    MinIO (S3-совместимое хранилище) — это и есть S3

    MongoDB (источник)

    Prometheus + Grafana (мониторинг)

Практики:

    Multi-stage build для Python-образа.

    Healthcheck для каждого сервиса.

    .env для паролей и портов.

    MinIO: lifecycle policy, versioning, pre-signed URL.

    S3-структура: создать бакеты raw, staging, marts (Medallion).

    Parquet: настроить, чтобы Python-скрипты писали Parquet в raw (не CSV).

    Prometheus: настроить экспорт метрик из PostgreSQL (postgres_exporter), ClickHouse (clickhouse-exporter), MinIO (minio-exporter).

    Grafana: создать первые дашборды — CPU, RAM, connections, query latency.

Дополнено из вопросов:

    S3 (MinIO) — не просто «есть», а центральное хранилище для raw-слоя.

    Parquet — формат хранения в raw.

    Prometheus + Grafana — не просто «есть», а интегрированы с базами.

Этап 2. Python-скрипты + DQ (5–6 дней)

Загрузчики:

    Генератор данных → CSV + запись в S3 (Parquet).

    Загрузчики в PostgreSQL, ClickHouse, MongoDB.

    UPSERT, watermark, backfill, idempotency — обязательно.

    ON CONFLICT ... WHERE ... IS DISTINCT FROM в PostgreSQL — идемпотентность без лишних UPDATE.

    ReplacingMergeTree в ClickHouse — идемпотентность без UPSERT.

DQ:

    Great Expectations — Expectation Suite, Data Docs, Checkpoints.

    Проверки: not_null, unique, accepted_values, relationships, row_count, freshness.

ClickHouse:

    Партиционирование (MergeTree, ReplacingMergeTree).

    Materialized View — для real-time агрегаций.

    Dictionary — для справочников.

Дополнено из вопросов:

    Идемпотентность — не просто «есть», а через IS DISTINCT FROM и ReplacingMergeTree.

    Raw-слой в S3 — сначала сохранять сырые данные в Parquet, потом парсить.

Этап 3. Airflow + Bash (4–5 дней)

Airflow:

    Webserver + Scheduler + Worker (CeleryExecutor или LocalExecutor).

    DAG: генерация → загрузка → DQ → запись в S3 → очистка (staging).

    TaskGroup — группировка задач.

    BranchPythonOperator — условные переходы.

    XCom — передача данных между задачами.

    SLAs — алерты при превышении времени.

    Retries — автоматические повторы.

    Backfill — перезапуск за прошлые периоды.

Bash:

    Скрипты запуска, миграций, бэкапов.

Дополнено из вопросов:

    Airflow вместо Windows Scheduler — DAG, retries, мониторинг.

    Мониторинг Airflow — метрики в Prometheus, дашборд в Grafana.

    Алерты — в Telegram/Slack при падении задачи.

Этап 4. Spark / PySpark + Iceberg (7–8 дней)

Spark:

    Master + Worker в Docker.

    Чтение из PostgreSQL + ClickHouse + MongoDB (JDBC).

    Запись витрин в Iceberg поверх MinIO (Parquet).

Оптимизации:

    Broadcast join — для справочников (department, service).

    Data skew — salting, AQE, shuffle.partitions.

    Партиционирование — по дате.

    Predicate pushdown — фильтры до джойна.

    spark.sql.adaptive.enabled = true — AQE.

Практики:

    UDF (User-Defined Functions).

    Spark UI — скриншоты до/после оптимизации.

    Checkpointing — для отказоустойчивости.

    Window functions — ROW_NUMBER, RANK, LAG, LEAD.

Iceberg:

    Time travel — читать данные на определённый момент.

    Schema evolution — добавлять/удалять колонки без перезаписи.

    Partition evolution — менять партиционирование без перезаписи.

    ACID — атомарные коммиты.

Дополнено из вопросов:

    Broadcast join — автоматически через autoBroadcastJoinThreshold (10 MB).

    Data skew — salting, AQE, shuffle.partitions.

    Raw-слой — Spark читает из S3 (Parquet), а не из OLTP.

    Iceberg — не просто «есть», а ACID, time travel, schema evolution.

Этап 4.5. Trino (2–3 дня)

Trino:

    В Docker.

    Подключение к PostgreSQL, ClickHouse, Iceberg.

Практики:

    Cross-catalog join — джойн между PostgreSQL и ClickHouse.

    Создание view — поверх нескольких каталогов.

    EXPLAIN — читать план Trino.

    Опционально: Superset через Trino.

Дополнено из вопросов:

    Trino — федеративные запросы, MPP-архитектура.

    EXPLAIN — читать план (аналогично PostgreSQL).

Этап 5. dbt + SCD Type 2 + Medallion (5–6 дней)

dbt:

    В Docker (или локально).

    Слои: raw → staging → marts (Medallion).

Модели:

    Очистка (TRIM, типы, дедупликация).

    Агрегации.

    Витрины.

SCD Type 2:

    Snapshot для department (историзация адресов).

    unique_key, strategy='timestamp', updated_at.

    invalidate_hard_deletes=True.

Тесты dbt:

    unique, not_null, accepted_values, relationships.

    Кастомные тесты — через dbt-utils, dbt-expectations.

Документация:

    Lineage — граф зависимостей.

    dbt docs serve.

Практики:

    Incremental модели — для больших таблиц.

    Snapshots — SCD2.

    Макросы — переиспользуемые функции.

    Exposures — связь с BI.

    Seeds — CSV-справочники.

    Tags — группировка моделей.

Дополнено из вопросов:

    SCD Type 2 — не просто «есть», а snapshot с strategy='timestamp'.

    IS DISTINCT FROM — для сравнения атрибутов.

    Medallion — raw → staging → marts.

Этап 6. Superset (3–4 дня)

Superset:

    В Docker.

    Подключение к ClickHouse (или Trino).

Дашборды:

    Обращения по дням.

    Топ услуг.

    Загрузка отделов.

Практики:

    SQL Lab — ad-hoc запросы.

    Row-level security — разграничение доступа.

    Alerts & Reports — автоматическая отправка.

Дополнено из вопросов:

    Superset через Trino — федеративные запросы.

    Мониторинг — метрики в Prometheus.

Этап 7. Power BI (2–3 дня)

Power BI:

    Подключение к ClickHouse (ODBC).

DAX:

    Меры vs вычисляемые столбцы.

    Time intelligence — TOTALYTD, SAMEPERIODLASTYEAR, DATEADD.

    RLS — Row-Level Security.

Практики:

    Скриншоты в docs/.

Дополнено из вопросов:

    DAX — не просто «меры», а time intelligence + RLS.

Этап 8. ML + MLflow + FastAPI (7–8 дней)

scikit-learn:

    KMeans (кластеризация).

    Регрессия (RandomForest).

    Pipeline — preprocessing + model.

    Cross-validation — cross_val_score.

    GridSearchCV — подбор гиперпараметров.

CatBoost:

    Классификация / регрессия.

    Feature importance.

    SHAP — интерпретация.

MLflow:

    Трекинг — логирование параметров, метрик, артефактов.

    Model Registry — версионирование моделей.

    Autolog — автоматическое логирование.

    Artifacts — сохранение моделей.

FastAPI:

    Обёртка модели в REST API.

    Pydantic — валидация.

    Swagger UI — автодокументация.

    Background tasks — асинхронные задачи.

Результаты — обратно в ClickHouse.

Дополнено из вопросов:

    MLflow — не просто «трекинг», а Model Registry + autolog.

    CatBoost — с feature importance + SHAP.

Этап 9. LLM + RAG + LangChain + Qdrant (7–8 дней)

Qdrant:

    В Docker — векторная БД.

    Эмбеддинги обращений → Qdrant.

    Payload-фильтры — фильтрация по метаданным.

    Named vectors — несколько векторов на документ.

    Snapshot — бэкап.

LangChain:

    Prompt templates — шаблоны промптов.

    Chains — цепочки вызовов.

    Memory — память диалога.

    Agents + tools — агенты с инструментами.

RAG:

    Поиск по обращениям.

    LLM для генерации тестовых данных и анализа ошибок.

Дополнено из вопросов:

    RAG — не просто «поиск», а retrieval + generation.

    LangChain — chains, memory, agents.

Этап 10. CI/CD (3–4 дня)

GitHub Actions:

    Линтеры — ruff, flake8.

    Тесты — pytest.

    Сборка Docker-образа — docker build.

    Тесты dbt — dbt test.

GitLab CI:

    Параллельно (или как основной).

Практики:

    Matrix builds — тесты на разных версиях Python.

    Cache — кэширование зависимостей.

    Artifacts — сохранение результатов.

    Manual approval — для деплоя в prod.

Дополнено из вопросов:

    Тесты dbt в CI — обязательны.

    Секреты — через GitHub Secrets / GitLab CI Variables (не в .env).

Этап 11. Kafka + Debezium + Spark Streaming (7–8 дней)

Kafka:

        Zookeeper в Docker.

    Топики, партиции, offset.

    Consumer groups — параллельное чтение.

    Retention policy — хранение сообщений.

Debezium:

    CDC из PostgreSQL → Kafka.

    Snapshot + incremental — первый запуск + streaming.

    SMT (Single Message Transform) — трансформация событий.

    Мониторинг коннектора — метрики.

Продюсер + консьюмер:

    Продюсер — генерация новых обращений.

    Консьюмер — запись в ClickHouse.

Spark Structured Streaming:

    Чтение из Kafka → Iceberg.

    Checkpointing — отказоустойчивость.

    Watermark — обработка late data.

    Output modes — append, update, complete.

Дополнено из вопросов:

    CDC — WAL → logical replication → Debezium → Kafka.

    Exactly-once — idempotent producer, transactions, read_committed.

    At-least-once + идемпотентный sink — реальный подход.

    Key = appeal_number — гарантия порядка внутри партиции.

Этап 12. Kubernetes / k3s (5–7 дней)

k3s / Minikube:

    В отдельной виртуалке.

    Манифесты для одного сервиса.

Практики:

    ConfigMap + Secret — конфигурация и секреты.

    Liveness / Readiness probes — healthcheck.

    HPA — автоскейлинг.

    Логи — kubectl logs.

    Масштабирование — kubectl scale.

Дополнено из вопросов:

    Секреты — не в .env, а в Kubernetes Secrets.

    Мониторинг — Prometheus + Grafana в k8s.

Этап 13. Финализация (4–5 дней)

README:

    Описание проекта.

    Архитектурная схема (Medallion).

    Стек.

    Инструкция запуска.

    Скриншоты дашбордов (Superset, Power BI, Grafana).

    Список фич.

    Чему научился.

Видео-демо (опционально).

Обновление резюме + ссылка на GitHub.

Дополнено из вопросов:

    Lineage — скриншот из dbt docs.

    Spark UI — скриншоты до/после оптимизации.

    EXPLAIN — скриншоты планов (PostgreSQL, Trino).

    Grafana — скриншоты дашбордов мониторинга.

Что добавлено (сводка)
Что	Где	Зачем
S3 (MinIO) как raw-слой	Этап 1, 2, 4	Хранение сырых данных, перепарсинг без повторного скачивания
Parquet	Этап 1, 2, 4	Колоночный формат для raw
IS DISTINCT FROM	Этап 2	Идемпотентность без лишних UPDATE
ReplacingMergeTree	Этап 2	Идемпотентность в ClickHouse
Materialized View	Этап 2	Real-time агрегации в ClickHouse
Dictionary	Этап 2	Справочники в ClickHouse
Prometheus + Grafana	Этап 1, 3	Мониторинг, алерты
Airflow метрики	Этап 3	Мониторинг DAG
Алерты в Telegram/Slack	Этап 3	Уведомления о падениях
Broadcast join	Этап 4	Оптимизация Spark
Data skew (salting, AQE)	Этап 4	Оптимизация Spark
autoBroadcastJoinThreshold	Этап 4	Автоматический broadcast
Iceberg (ACID, time travel, schema evolution)	Этап 4	Надёжное хранение
Trino EXPLAIN	Этап 4.5	Чтение планов
SCD2 snapshot	Этап 5	Историзация
dbt incremental, snapshots, macros, exposures, seeds, tags	Этап 5	Полный набор практик dbt
DAX time intelligence, RLS	Этап 7	Power BI
MLflow Model Registry, autolog	Этап 8	Трекинг ML
CatBoost feature importance, SHAP	Этап 8	Интерпретация ML
Qdrant payload-фильтры, named vectors, snapshot	Этап 9	Векторная БД
LangChain chains, memory, agents	Этап 9	Оркестрация LLM
CI секреты	Этап 10	Безопасность
CDC (WAL, logical replication)	Этап 11	Понимание Debezium
Exactly-once	Этап 11	Гарантии доставки
Kafka consumer groups, partitions, retention	Этап 11	Полный набор Kafka
k8s ConfigMap, Secret, probes, HPA	Этап 12	Kubernetes
Grafana скриншоты, Spark UI, EXPLAIN	Этап 13	Артефакты для README
