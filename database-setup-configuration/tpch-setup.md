---

# TPC-H Database Setup Guide (SF=1 and SF=10) — PostgreSQL

---

## Prerequisites

* PostgreSQL installed and running (see PostgreSQL Setup Guide)
* Disk Space Requirements:

  * **SF-1 (~1GB dataset):** At least **5 GB free disk space**
  * **SF-10 (~10GB dataset):** At least **20 GB free disk space**

---

## Step 1: Download the Data Files
---
## Step 2: Open PostgreSQL

### Linux / macOS
```bash
sudo -i -u postgres
psql
```

---

### Windows

Open:
```
pgAdmin → Query Tool
```

---

## Step 3: Create Database
```sql
CREATE DATABASE tpch_db;
```

Connect to database:
```sql
\c tpch_db
```

---

## Step 4: Create Tables

### Create customer table
```sql
CREATE TABLE customer (
    c_custkey     INTEGER,
    c_name        TEXT,
    c_address     TEXT,
    c_nationkey   INTEGER,
    c_phone       TEXT,
    c_acctbal     NUMERIC,
    c_mktsegment  TEXT,
    c_comment     TEXT
);
```

---

### Create orders table
```sql
CREATE TABLE orders (
    o_orderkey       INTEGER,
    o_custkey        INTEGER,
    o_orderstatus    CHAR(1),
    o_totalprice     NUMERIC,
    o_orderdate      DATE,
    o_orderpriority  TEXT,
    o_clerk          TEXT,
    o_shippriority   INTEGER,
    o_comment        TEXT
);
```

---

### Create lineitem table
```sql
CREATE TABLE lineitem (
    l_orderkey        INTEGER,
    l_partkey         INTEGER,
    l_suppkey         INTEGER,
    l_linenumber      INTEGER,
    l_quantity        NUMERIC,
    l_extendedprice   NUMERIC,
    l_discount        NUMERIC,
    l_tax             NUMERIC,
    l_returnflag      CHAR(1),
    l_linestatus      CHAR(1),
    l_shipdate        DATE,
    l_commitdate      DATE,
    l_receiptdate     DATE,
    l_shipinstruct    TEXT,
    l_shipmode        TEXT,
    l_comment         TEXT
);
```

---

## Step 5: Load Data into PostgreSQL

---

## Step 6: Verify Data Load

Run:
```sql
SELECT COUNT(*) FROM customer;
SELECT COUNT(*) FROM orders;
SELECT COUNT(*) FROM lineitem;
```

Expected approximate counts:

| Table    | SF-1      | SF-10      |
| -------- | --------- | ---------- |
| customer | 150,000   | 1,500,000  |
| orders   | 1,500,000 | 15,000,000 |
| lineitem | 6,000,000 | 60,000,000 |

---

## Step 7: Add Primary Key Constraints and Create Indexes

After loading and verifying the data, add primary key constraints to each table. This will automatically create unique indexes on the primary key columns.
```sql
ALTER TABLE customer ADD PRIMARY KEY (c_custkey);

ALTER TABLE orders ADD PRIMARY KEY (o_orderkey);

ALTER TABLE lineitem ADD PRIMARY KEY (l_orderkey, l_linenumber);
```

The above commands create the following indexes automatically:

| Table    | Index Created On              |
| -------- | ----------------------------- |
| customer | `c_custkey`                   |
| orders   | `o_orderkey`                  |
| lineitem | `(l_orderkey, l_linenumber)`  |

Now, create an additional index on `l_shipdate` which is required for the assignment experiments:
```sql
CREATE INDEX idx_lineitem_shipdate ON lineitem(l_shipdate);
```
```sql
CREATE INDEX idx_orders_orderdate ON orders(o_orderdate);
```

---