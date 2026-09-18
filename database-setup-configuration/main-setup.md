# Environment Setup

This guide describes the PostgreSQL environment required to reproduce the experiments in this project.

The project uses PostgreSQL together with TPC-H benchmark data. The optimizer-analysis experiments additionally require the `pg_hint_plan` extension.

The setup is organized in four stages:

1. PostgreSQL installation
2. TPC-H database setup
3. `pg_hint_plan` configuration
4. Environment verification

---

## 1. PostgreSQL Installation

The experiments require:

* PostgreSQL **14 or later**
* A working PostgreSQL server
* A client such as `psql`

PostgreSQL can be downloaded from the official website:

[PostgreSQL Downloads](https://www.postgresql.org/download/)

After installation, verify that the PostgreSQL server is running.

Connect to the default `postgres` database:

```bash
psql -d postgres
```

Then execute a simple query:

```sql
SELECT version();
```

A successful response confirms that PostgreSQL is installed and accessible.

You can also verify the current database connection using:

```sql
SELECT current_database();
```

Exit `psql` with:

```text
\q
```

---

## 2. TPC-H Benchmark Data

This project uses data derived from the **TPC-H decision-support benchmark**.

The experiments use the following tables:

### Indexing Analysis
```text
lineitem
```

### Query Optimizer Analysis
```text
customer
orders
lineitem
```

The required TPC-H data should be generated or obtained accordingly.

### Reference Guides

Some guides are attached here, in the same directory.

---

## 3. Create the Database

Create a dedicated PostgreSQL database for the experiments.

For example:

```sql
CREATE DATABASE tpch_db;
```

Connect to it:

```bash
psql -d tpch_db
```

All experiments in this repository should preferably be performed inside this dedicated database so that indexes, configuration changes, and experimental tables do not interfere with other PostgreSQL databases.

---

## 4. Load the TPC-H Tables

Load the required TPC-H tables according to the TPC-H setup guide.

For the indexing experiments, the minimum required table is:

```text
lineitem
```

For the optimizer experiments, the following tables are required:

```text
customer
orders
lineitem
```

After loading the data, verify that the tables exist:

```sql
\dt
```

For example, verify the `lineitem` table with:

```sql
SELECT COUNT(*) FROM lineitem;
```

For the optimizer experiments, also verify:

```sql
SELECT COUNT(*) FROM customer;

SELECT COUNT(*) FROM orders;

SELECT COUNT(*) FROM lineitem;
```

The exact row counts depend on the TPC-H scale factor used when generating the dataset.

---

## 5. Create Required Indexes

Some optimizer experiments require indexes on the TPC-H tables.

The required indexes should be created according to the provided TPC-H setup guide:

```text
tpch_setup.md
```

Keep the index definitions consistent across experiments so that results remain comparable.

For experiments that explicitly study indexing behavior, indexes may be created, removed, or recreated as part of the experiment itself.

Do not assume that an index should always be present: some experiments intentionally compare execution with and without indexes.

---

## 6. Configure `pg_hint_plan`

The optimizer-analysis experiments use PostgreSQL's `pg_hint_plan` extension.

`pg_hint_plan` allows a query to specify hints that influence the execution plan selected by PostgreSQL. It is used in this project to force alternative physical plans so that their actual execution times can be compared with the optimizer's default choice.

The setup guide is:

```text
postgres_pghint.md
```

Follow that guide to install and configure the extension for your PostgreSQL installation.

After configuration, verify that the extension is available.

Inside `psql`, run:

```sql
SELECT * 
FROM pg_available_extensions
WHERE name = 'pg_hint_plan';
```

If the extension is available, it can be enabled in the experimental database with:

```sql
CREATE EXTENSION pg_hint_plan;
```

Verify that it has been installed:

```sql
SELECT extname, extversion
FROM pg_extension
WHERE extname = 'pg_hint_plan';
```

> The exact installation and server configuration steps for `pg_hint_plan` can vary depending on the PostgreSQL version and operating system. Follow the course-provided `postgres_pghint.md` guide for the system-specific installation procedure.

## Note

Specific Implementation for a certain experiment can be found in it's report.

## Queries Used in the Optimizer Analysis

### Query 1 — Based on TPC-H Query 1

```sql
SELECT
    SUM(l_quantity),
    SUM(l_extendedprice),
    SUM(l_extendedprice * (1 - l_discount)),
    SUM(l_extendedprice * (1 - l_discount) * (1 + l_tax)),
    AVG(l_quantity),
    AVG(l_extendedprice),
    AVG(l_discount),
    COUNT(*)
FROM lineitem
WHERE l_shipdate <= [DATE];
```

---

### Query 2 — Based on TPC-H Query 4

```sql
SELECT
    o_orderpriority,
    COUNT(*) AS order_count
FROM orders
WHERE
    o_orderdate >= DATE '1992-01-01'
    AND o_orderdate < DATE '[DATE]'
    AND EXISTS (
        SELECT 1
        FROM lineitem
        WHERE
            l_orderkey = o_orderkey
            AND l_commitdate < l_receiptdate
    )
GROUP BY o_orderpriority;
```

---

### Query 3 — Based on TPC-H Query 3

```sql
SELECT
    l.l_orderkey,
    l.l_extendedprice * (1 - l.l_discount) AS revenue,
    o.o_orderdate,
    o.o_shippriority
FROM customer c
JOIN orders o
    ON c.c_custkey = o.o_custkey
JOIN lineitem l
    ON l.l_orderkey = o.o_orderkey
WHERE
    c.c_mktsegment = 'BUILDING'
    AND o.o_orderdate < DATE '[DATE]'
    AND l.l_shipdate > DATE '[DATE]';
```


