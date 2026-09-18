-- create the database
CREATE DATABASE tpch_db;

-- create the lineitem table
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

COPY lineitem
FROM '/tmp/lineitem_sf10.csv'
WITH (FORMAT csv, HEADER);

SELECT *
FROM lineitem
WHERE l_quantity <= 10;

-- Scenario A:

CREATE TABLE lineitem_a (LIKE lineitem INCLUDING ALL);

CREATE INDEX idx_lineitem_a_quantity
ON lineitem_a (l_quantity);

EXPLAIN ANALYZE
INSERT INTO lineitem_a
SELECT * FROM lineitem;

-- Scenario B:

CREATE TABLE lineitem_b (LIKE lineitem INCLUDING ALL);


EXPLAIN ANALYZE
INSERT INTO lineitem_b
SELECT * FROM lineitem;


CREATE INDEX idx_lineitem_b_quantity
ON lineitem_b (l_quantity);






