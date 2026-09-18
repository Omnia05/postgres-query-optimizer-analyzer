-- Switch Performance Analysis: queries.sql
--Each query was run twice for warm cache fairness

-- QUERY 1
-- Switch 1: 1992-01-07 -> 1992-01-08
-- RT(Pi, qi): Natural execution at qi=1992-01-07
EXPLAIN (ANALYZE, FORMAT JSON) SELECT
    SUM(l_quantity), SUM(l_extendedprice),
    SUM(l_extendedprice * (1 - l_discount)),
    SUM(l_extendedprice * (1 - l_discount) * (1 + l_tax)),
    AVG(l_quantity), AVG(l_extendedprice),
    AVG(l_discount), COUNT(*)
FROM lineitem
WHERE l_shipdate <= '1992-01-07';

-- RT(Pj, qj): Natural execution at qj=1992-01-08 
EXPLAIN (ANALYZE, FORMAT JSON) SELECT
    SUM(l_quantity), SUM(l_extendedprice),
    SUM(l_extendedprice * (1 - l_discount)),
    SUM(l_extendedprice * (1 - l_discount) * (1 + l_tax)),
    AVG(l_quantity), AVG(l_extendedprice),
    AVG(l_discount), COUNT(*)
FROM lineitem
WHERE l_shipdate <= '1992-01-08';

-- RT(Pi, qj): Force Pi at qj=1992-01-08 
-- Hints: Leading(lineitem), BitmapScan(lineitem)
EXPLAIN (ANALYZE, FORMAT JSON) /*+
Leading(lineitem)
BitmapScan(lineitem)
*/ SELECT
    SUM(l_quantity), SUM(l_extendedprice),
    SUM(l_extendedprice * (1 - l_discount)),
    SUM(l_extendedprice * (1 - l_discount) * (1 + l_tax)),
    AVG(l_quantity), AVG(l_extendedprice),
    AVG(l_discount), COUNT(*)
FROM lineitem
WHERE l_shipdate <= '1992-01-08';

-- RT(Pj, qi): Force Pj at qi=1992-01-07 
-- Hints: Leading(lineitem), IndexScan(lineitem idx_lineitem_shipdate)
EXPLAIN (ANALYZE, FORMAT JSON) /*+
Leading(lineitem)
IndexScan(lineitem idx_lineitem_shipdate)
*/ SELECT
    SUM(l_quantity), SUM(l_extendedprice),
    SUM(l_extendedprice * (1 - l_discount)),
    SUM(l_extendedprice * (1 - l_discount) * (1 + l_tax)),
    AVG(l_quantity), AVG(l_extendedprice),
    AVG(l_discount), COUNT(*)
FROM lineitem
WHERE l_shipdate <= '1992-01-07';

-- Switch 2: 1992-01-27 -> 1992-01-28

-- RT(Pi, qi): Natural execution at qi=1992-01-27
EXPLAIN (ANALYZE, FORMAT JSON) SELECT
    SUM(l_quantity), SUM(l_extendedprice),
    SUM(l_extendedprice * (1 - l_discount)),
    SUM(l_extendedprice * (1 - l_discount) * (1 + l_tax)),
    AVG(l_quantity), AVG(l_extendedprice),
    AVG(l_discount), COUNT(*)
FROM lineitem
WHERE l_shipdate <= '1992-01-27';

-- RT(Pj, qj): Natural execution at qj=1992-01-28
EXPLAIN (ANALYZE, FORMAT JSON) SELECT
    SUM(l_quantity), SUM(l_extendedprice),
    SUM(l_extendedprice * (1 - l_discount)),
    SUM(l_extendedprice * (1 - l_discount) * (1 + l_tax)),
    AVG(l_quantity), AVG(l_extendedprice),
    AVG(l_discount), COUNT(*)
FROM lineitem
WHERE l_shipdate <= '1992-01-28';

-- RT(Pi, qj): Force Pi at qj=1992-01-28
-- Hints: Leading(lineitem), IndexScan(lineitem idx_lineitem_shipdate)
EXPLAIN (ANALYZE, FORMAT JSON) /*+
Leading(lineitem)
IndexScan(lineitem idx_lineitem_shipdate)
*/ SELECT
    SUM(l_quantity), SUM(l_extendedprice),
    SUM(l_extendedprice * (1 - l_discount)),
    SUM(l_extendedprice * (1 - l_discount) * (1 + l_tax)),
    AVG(l_quantity), AVG(l_extendedprice),
    AVG(l_discount), COUNT(*)
FROM lineitem
WHERE l_shipdate <= '1992-01-28';

-- RT(Pj, qi): Force Pj at qi=1992-01-27 (warm cache - run twice)
-- Hints: Leading(lineitem), BitmapScan(lineitem)
EXPLAIN (ANALYZE, FORMAT JSON) /*+
Leading(lineitem)
BitmapScan(lineitem)
*/ SELECT
    SUM(l_quantity), SUM(l_extendedprice),
    SUM(l_extendedprice * (1 - l_discount)),
    SUM(l_extendedprice * (1 - l_discount) * (1 + l_tax)),
    AVG(l_quantity), AVG(l_extendedprice),
    AVG(l_discount), COUNT(*)
FROM lineitem
WHERE l_shipdate <= '1992-01-27';

-- Switch 3: 1992-03-29 -> 1992-03-30

-- RT(Pi, qi): Natural execution at qi=1992-03-29 (warm cache - run twice)
EXPLAIN (ANALYZE, FORMAT JSON) SELECT
    SUM(l_quantity), SUM(l_extendedprice),
    SUM(l_extendedprice * (1 - l_discount)),
    SUM(l_extendedprice * (1 - l_discount) * (1 + l_tax)),
    AVG(l_quantity), AVG(l_extendedprice),
    AVG(l_discount), COUNT(*)
FROM lineitem
WHERE l_shipdate <= '1992-03-29';

-- RT(Pj, qj): Natural execution at qj=1992-03-30 (warm cache - run twice)
EXPLAIN (ANALYZE, FORMAT JSON) SELECT
    SUM(l_quantity), SUM(l_extendedprice),
    SUM(l_extendedprice * (1 - l_discount)),
    SUM(l_extendedprice * (1 - l_discount) * (1 + l_tax)),
    AVG(l_quantity), AVG(l_extendedprice),
    AVG(l_discount), COUNT(*)
FROM lineitem
WHERE l_shipdate <= '1992-03-30';

-- RT(Pi, qj): Force Pi at qj=1992-03-30 (warm cache - run twice)
-- Hints: Leading(lineitem), BitmapScan(lineitem)
EXPLAIN (ANALYZE, FORMAT JSON) /*+
Leading(lineitem)
BitmapScan(lineitem)
*/ SELECT
    SUM(l_quantity), SUM(l_extendedprice),
    SUM(l_extendedprice * (1 - l_discount)),
    SUM(l_extendedprice * (1 - l_discount) * (1 + l_tax)),
    AVG(l_quantity), AVG(l_extendedprice),
    AVG(l_discount), COUNT(*)
FROM lineitem
WHERE l_shipdate <= '1992-03-30';

-- RT(Pj, qi): Force Pj at qi=1992-03-29 (warm cache - run twice)
-- Hints: Leading(lineitem), SeqScan(lineitem)
EXPLAIN (ANALYZE, FORMAT JSON) /*+
Leading(lineitem)
SeqScan(lineitem)
*/ SELECT
    SUM(l_quantity), SUM(l_extendedprice),
    SUM(l_extendedprice * (1 - l_discount)),
    SUM(l_extendedprice * (1 - l_discount) * (1 + l_tax)),
    AVG(l_quantity), AVG(l_extendedprice),
    AVG(l_discount), COUNT(*)
FROM lineitem
WHERE l_shipdate <= '1992-03-29';

-- QUERY 2
-- Switch 1: 1992-01-01 -> 1992-01-02
-- RT(Pi, qi): Natural execution at qi=1992-01-01 (warm cache - run twice)
EXPLAIN (ANALYZE, FORMAT JSON) SELECT o_orderpriority, count(*) AS order_count
FROM orders
WHERE o_orderdate >= DATE '1992-01-01'
  AND o_orderdate < DATE '1992-01-01'
  AND EXISTS (
      SELECT 1 FROM lineitem
      WHERE l_orderkey = o_orderkey
      AND l_commitdate < l_receiptdate
  )
GROUP BY o_orderpriority;

-- RT(Pj, qj): Natural execution at qj=1992-01-02 (warm cache - run twice)
EXPLAIN (ANALYZE, FORMAT JSON) SELECT o_orderpriority, count(*) AS order_count
FROM orders
WHERE o_orderdate >= DATE '1992-01-01'
  AND o_orderdate < DATE '1992-01-02'
  AND EXISTS (
      SELECT 1 FROM lineitem
      WHERE l_orderkey = o_orderkey
      AND l_commitdate < l_receiptdate
  )
GROUP BY o_orderpriority;

-- RT(Pi, qj): Force Pi at qj=1992-01-02 (warm cache - run twice)
-- Hints: Leading(orders lineitem), IndexScan(orders idx_orders_orderdate), IndexScan(lineitem lineitem_pkey), NestLoop(orders lineitem)
EXPLAIN (ANALYZE, FORMAT JSON) /*+
Leading(orders lineitem)
IndexScan(orders idx_orders_orderdate)
IndexScan(lineitem lineitem_pkey)
NestLoop(orders lineitem)
*/ SELECT o_orderpriority, count(*) AS order_count
FROM orders
WHERE o_orderdate >= DATE '1992-01-01'
  AND o_orderdate < DATE '1992-01-02'
  AND EXISTS (
      SELECT 1 FROM lineitem
      WHERE l_orderkey = o_orderkey
      AND l_commitdate < l_receiptdate
  )
GROUP BY o_orderpriority;

-- RT(Pj, qi): Force Pj at qi=1992-01-01 (warm cache - run twice)
-- Hints: Leading(orders lineitem), BitmapScan(orders), IndexScan(lineitem lineitem_pkey), NestLoop(orders lineitem)
EXPLAIN (ANALYZE, FORMAT JSON) /*+
Leading(orders lineitem)
BitmapScan(orders)
IndexScan(lineitem lineitem_pkey)
NestLoop(orders lineitem)
*/ SELECT o_orderpriority, count(*) AS order_count
FROM orders
WHERE o_orderdate >= DATE '1992-01-01'
  AND o_orderdate < DATE '1992-01-01'
  AND EXISTS (
      SELECT 1 FROM lineitem
      WHERE l_orderkey = o_orderkey
      AND l_commitdate < l_receiptdate
  )
GROUP BY o_orderpriority;

-- Switch 2: 1992-05-13 -> 1992-05-14
-- RT(Pi, qi): Natural execution at qi=1992-05-13 (warm cache - run twice)
EXPLAIN (ANALYZE, FORMAT JSON) SELECT o_orderpriority, count(*) AS order_count
FROM orders
WHERE o_orderdate >= DATE '1992-01-01'
  AND o_orderdate < DATE '1992-05-13'
  AND EXISTS (
      SELECT 1 FROM lineitem
      WHERE l_orderkey = o_orderkey
      AND l_commitdate < l_receiptdate
  )
GROUP BY o_orderpriority;

-- RT(Pj, qj): Natural execution at qj=1992-05-14 (warm cache - run twice)
EXPLAIN (ANALYZE, FORMAT JSON) SELECT o_orderpriority, count(*) AS order_count
FROM orders
WHERE o_orderdate >= DATE '1992-01-01'
  AND o_orderdate < DATE '1992-05-14'
  AND EXISTS (
      SELECT 1 FROM lineitem
      WHERE l_orderkey = o_orderkey
      AND l_commitdate < l_receiptdate
  )
GROUP BY o_orderpriority;

-- RT(Pi, qj): Force Pi at qj=1992-05-14 (warm cache - run twice)
-- Hints: Leading(orders lineitem), BitmapScan(orders), IndexScan(lineitem lineitem_pkey), NestLoop(orders lineitem)
EXPLAIN (ANALYZE, FORMAT JSON) /*+
Leading(orders lineitem)
BitmapScan(orders)
IndexScan(lineitem lineitem_pkey)
NestLoop(orders lineitem)
*/ SELECT o_orderpriority, count(*) AS order_count
FROM orders
WHERE o_orderdate >= DATE '1992-01-01'
  AND o_orderdate < DATE '1992-05-14'
  AND EXISTS (
      SELECT 1 FROM lineitem
      WHERE l_orderkey = o_orderkey
      AND l_commitdate < l_receiptdate
  )
GROUP BY o_orderpriority;

-- RT(Pj, qi): Force Pj at qi=1992-05-13 (warm cache - run twice)
-- Hints: Leading(orders lineitem), SeqScan(orders), SeqScan(lineitem), HashJoin(orders lineitem)
EXPLAIN (ANALYZE, FORMAT JSON) /*+
Leading(orders lineitem)
SeqScan(orders)
SeqScan(lineitem)
HashJoin(orders lineitem)
*/ SELECT o_orderpriority, count(*) AS order_count
FROM orders
WHERE o_orderdate >= DATE '1992-01-01'
  AND o_orderdate < DATE '1992-05-13'
  AND EXISTS (
      SELECT 1 FROM lineitem
      WHERE l_orderkey = o_orderkey
      AND l_commitdate < l_receiptdate
  )
GROUP BY o_orderpriority;

-- Switch 3: 1997-11-25 -> 1997-11-26
-- RT(Pi, qi): Natural execution at qi=1997-11-25 (warm cache - run twice)
EXPLAIN (ANALYZE, FORMAT JSON) SELECT o_orderpriority, count(*) AS order_count
FROM orders
WHERE o_orderdate >= DATE '1992-01-01'
  AND o_orderdate < DATE '1997-11-25'
  AND EXISTS (
      SELECT 1 FROM lineitem
      WHERE l_orderkey = o_orderkey
      AND l_commitdate < l_receiptdate
  )
GROUP BY o_orderpriority;

-- RT(Pj, qj): Natural execution at qj=1997-11-26 (warm cache - run twice)
EXPLAIN (ANALYZE, FORMAT JSON) SELECT o_orderpriority, count(*) AS order_count
FROM orders
WHERE o_orderdate >= DATE '1992-01-01'
  AND o_orderdate < DATE '1997-11-26'
  AND EXISTS (
      SELECT 1 FROM lineitem
      WHERE l_orderkey = o_orderkey
      AND l_commitdate < l_receiptdate
  )
GROUP BY o_orderpriority;

-- RT(Pi, qj): Force Pi at qj=1997-11-26 (warm cache - run twice)
-- Hints: Leading(orders lineitem), SeqScan(orders), SeqScan(lineitem), HashJoin(orders lineitem)
EXPLAIN (ANALYZE, FORMAT JSON) /*+
Leading(orders lineitem)
SeqScan(orders)
SeqScan(lineitem)
HashJoin(orders lineitem)
*/ SELECT o_orderpriority, count(*) AS order_count
FROM orders
WHERE o_orderdate >= DATE '1992-01-01'
  AND o_orderdate < DATE '1997-11-26'
  AND EXISTS (
      SELECT 1 FROM lineitem
      WHERE l_orderkey = o_orderkey
      AND l_commitdate < l_receiptdate
  )
GROUP BY o_orderpriority;

-- RT(Pj, qi): Force Pj at qi=1997-11-25 (warm cache - run twice)
-- Hints: Leading(orders lineitem), SeqScan(orders), SeqScan(lineitem), HashJoin(orders lineitem)
EXPLAIN (ANALYZE, FORMAT JSON) /*+
Leading(orders lineitem)
SeqScan(orders)
SeqScan(lineitem)
HashJoin(orders lineitem)
*/ SELECT o_orderpriority, count(*) AS order_count
FROM orders
WHERE o_orderdate >= DATE '1992-01-01'
  AND o_orderdate < DATE '1997-11-25'
  AND EXISTS (
      SELECT 1 FROM lineitem
      WHERE l_orderkey = o_orderkey
      AND l_commitdate < l_receiptdate
  )
GROUP BY o_orderpriority;

-- QUERY 3
-- Switch 1: 1992-01-01 -> 1992-01-02
-- RT(Pi, qi): Natural execution at qi=1992-01-01 (warm cache - run twice)
EXPLAIN (ANALYZE, FORMAT JSON) SELECT
    l.l_orderkey,
    l.l_extendedprice * (1 - l.l_discount) AS revenue,
    o.o_orderdate,
    o.o_shippriority
FROM customer c
JOIN orders o ON c.c_custkey = o.o_custkey
JOIN lineitem l ON l.l_orderkey = o.o_orderkey
WHERE c.c_mktsegment = 'BUILDING'
  AND o.o_orderdate < DATE '1992-01-01'
  AND l.l_shipdate > DATE '1992-01-01';

-- RT(Pj, qj): Natural execution at qj=1992-01-02 (warm cache - run twice)
EXPLAIN (ANALYZE, FORMAT JSON) SELECT
    l.l_orderkey,
    l.l_extendedprice * (1 - l.l_discount) AS revenue,
    o.o_orderdate,
    o.o_shippriority
FROM customer c
JOIN orders o ON c.c_custkey = o.o_custkey
JOIN lineitem l ON l.l_orderkey = o.o_orderkey
WHERE c.c_mktsegment = 'BUILDING'
  AND o.o_orderdate < DATE '1992-01-02'
  AND l.l_shipdate > DATE '1992-01-02';

-- RT(Pi, qj): Force Pi at qj=1992-01-02 (warm cache - run twice)
-- Hints: Leading(o c l), IndexScan(o idx_orders_orderdate), IndexScan(c customer_pkey), IndexScan(l lineitem_pkey), NestLoop(o c l), NestLoop(o c)
EXPLAIN (ANALYZE, FORMAT JSON) /*+
Leading(o c l)
IndexScan(o idx_orders_orderdate)
IndexScan(c customer_pkey)
IndexScan(l lineitem_pkey)
NestLoop(o c l)
NestLoop(o c)
*/ SELECT
    l.l_orderkey,
    l.l_extendedprice * (1 - l.l_discount) AS revenue,
    o.o_orderdate,
    o.o_shippriority
FROM customer c
JOIN orders o ON c.c_custkey = o.o_custkey
JOIN lineitem l ON l.l_orderkey = o.o_orderkey
WHERE c.c_mktsegment = 'BUILDING'
  AND o.o_orderdate < DATE '1992-01-02'
  AND l.l_shipdate > DATE '1992-01-02';

-- RT(Pj, qi): Force Pj at qi=1992-01-01 (warm cache - run twice)
-- Hints: Leading(o c l), BitmapScan(o), IndexScan(c customer_pkey), IndexScan(l lineitem_pkey), NestLoop(o c l), NestLoop(o c)
EXPLAIN (ANALYZE, FORMAT JSON) /*+
Leading(o c l)
BitmapScan(o)
IndexScan(c customer_pkey)
IndexScan(l lineitem_pkey)
NestLoop(o c l)
NestLoop(o c)
*/ SELECT
    l.l_orderkey,
    l.l_extendedprice * (1 - l.l_discount) AS revenue,
    o.o_orderdate,
    o.o_shippriority
FROM customer c
JOIN orders o ON c.c_custkey = o.o_custkey
JOIN lineitem l ON l.l_orderkey = o.o_orderkey
WHERE c.c_mktsegment = 'BUILDING'
  AND o.o_orderdate < DATE '1992-01-01'
  AND l.l_shipdate > DATE '1992-01-01';

-- Switch 2: 1992-01-03 -> 1992-01-04
-- RT(Pi, qi): Natural execution at qi=1992-01-03 (warm cache - run twice)
EXPLAIN (ANALYZE, FORMAT JSON) SELECT
    l.l_orderkey,
    l.l_extendedprice * (1 - l.l_discount) AS revenue,
    o.o_orderdate,
    o.o_shippriority
FROM customer c
JOIN orders o ON c.c_custkey = o.o_custkey
JOIN lineitem l ON l.l_orderkey = o.o_orderkey
WHERE c.c_mktsegment = 'BUILDING'
  AND o.o_orderdate < DATE '1992-01-03'
  AND l.l_shipdate > DATE '1992-01-03';

-- RT(Pj, qj): Natural execution at qj=1992-01-04 (warm cache - run twice)
EXPLAIN (ANALYZE, FORMAT JSON) SELECT
    l.l_orderkey,
    l.l_extendedprice * (1 - l.l_discount) AS revenue,
    o.o_orderdate,
    o.o_shippriority
FROM customer c
JOIN orders o ON c.c_custkey = o.o_custkey
JOIN lineitem l ON l.l_orderkey = o.o_orderkey
WHERE c.c_mktsegment = 'BUILDING'
  AND o.o_orderdate < DATE '1992-01-04'
  AND l.l_shipdate > DATE '1992-01-04';

-- RT(Pi, qj): Force Pi at qj=1992-01-04 (warm cache - run twice)
-- Hints: Leading(o c l), BitmapScan(o), IndexScan(c customer_pkey), IndexScan(l lineitem_pkey), NestLoop(o c l), NestLoop(o c)
EXPLAIN (ANALYZE, FORMAT JSON) /*+
Leading(o c l)
BitmapScan(o)
IndexScan(c customer_pkey)
IndexScan(l lineitem_pkey)
NestLoop(o c l)
NestLoop(o c)
*/ SELECT
    l.l_orderkey,
    l.l_extendedprice * (1 - l.l_discount) AS revenue,
    o.o_orderdate,
    o.o_shippriority
FROM customer c
JOIN orders o ON c.c_custkey = o.o_custkey
JOIN lineitem l ON l.l_orderkey = o.o_orderkey
WHERE c.c_mktsegment = 'BUILDING'
  AND o.o_orderdate < DATE '1992-01-04'
  AND l.l_shipdate > DATE '1992-01-04';

-- RT(Pj, qi): Force Pj at qi=1992-01-03 (warm cache - run twice)
-- Hints: Leading(c o l), SeqScan(c), BitmapScan(o), IndexScan(l lineitem_pkey), NestLoop(c o l), HashJoin(c o)
EXPLAIN (ANALYZE, FORMAT JSON) /*+
Leading(c o l)
SeqScan(c)
BitmapScan(o)
IndexScan(l lineitem_pkey)
NestLoop(c o l)
HashJoin(c o)
*/ SELECT
    l.l_orderkey,
    l.l_extendedprice * (1 - l.l_discount) AS revenue,
    o.o_orderdate,
    o.o_shippriority
FROM customer c
JOIN orders o ON c.c_custkey = o.o_custkey
JOIN lineitem l ON l.l_orderkey = o.o_orderkey
WHERE c.c_mktsegment = 'BUILDING'
  AND o.o_orderdate < DATE '1992-01-03'
  AND l.l_shipdate > DATE '1992-01-03';

-- Switch 3: 1992-01-06 -> 1992-01-07
-- RT(Pi, qi): Natural execution at qi=1992-01-06 (warm cache - run twice)
EXPLAIN (ANALYZE, FORMAT JSON) SELECT
    l.l_orderkey,
    l.l_extendedprice * (1 - l.l_discount) AS revenue,
    o.o_orderdate,
    o.o_shippriority
FROM customer c
JOIN orders o ON c.c_custkey = o.o_custkey
JOIN lineitem l ON l.l_orderkey = o.o_orderkey
WHERE c.c_mktsegment = 'BUILDING'
  AND o.o_orderdate < DATE '1992-01-06'
  AND l.l_shipdate > DATE '1992-01-06';

-- RT(Pj, qj): Natural execution at qj=1992-01-07 (warm cache - run twice)
EXPLAIN (ANALYZE, FORMAT JSON) SELECT
    l.l_orderkey,
    l.l_extendedprice * (1 - l.l_discount) AS revenue,
    o.o_orderdate,
    o.o_shippriority
FROM customer c
JOIN orders o ON c.c_custkey = o.o_custkey
JOIN lineitem l ON l.l_orderkey = o.o_orderkey
WHERE c.c_mktsegment = 'BUILDING'
  AND o.o_orderdate < DATE '1992-01-07'
  AND l.l_shipdate > DATE '1992-01-07';

-- RT(Pi, qj): Force Pi at qj=1992-01-07 (warm cache - run twice)
-- Hints: Leading(c o l), SeqScan(c), BitmapScan(o), IndexScan(l lineitem_pkey), NestLoop(c o l), HashJoin(c o)
EXPLAIN (ANALYZE, FORMAT JSON) /*+
Leading(c o l)
SeqScan(c)
BitmapScan(o)
IndexScan(l lineitem_pkey)
NestLoop(c o l)
HashJoin(c o)
*/ SELECT
    l.l_orderkey,
    l.l_extendedprice * (1 - l.l_discount) AS revenue,
    o.o_orderdate,
    o.o_shippriority
FROM customer c
JOIN orders o ON c.c_custkey = o.o_custkey
JOIN lineitem l ON l.l_orderkey = o.o_orderkey
WHERE c.c_mktsegment = 'BUILDING'
  AND o.o_orderdate < DATE '1992-01-07'
  AND l.l_shipdate > DATE '1992-01-07';

-- RT(Pj, qi): Force Pj at qi=1992-01-06 (warm cache - run twice)
-- Hints: Leading(o c l), BitmapScan(o), SeqScan(c), IndexScan(l lineitem_pkey), NestLoop(o c l), HashJoin(o c)
EXPLAIN (ANALYZE, FORMAT JSON) /*+
Leading(o c l)
BitmapScan(o)
SeqScan(c)
IndexScan(l lineitem_pkey)
NestLoop(o c l)
HashJoin(o c)
*/ SELECT
    l.l_orderkey,
    l.l_extendedprice * (1 - l.l_discount) AS revenue,
    o.o_orderdate,
    o.o_shippriority
FROM customer c
JOIN orders o ON c.c_custkey = o.o_custkey
JOIN lineitem l ON l.l_orderkey = o.o_orderkey
WHERE c.c_mktsegment = 'BUILDING'
  AND o.o_orderdate < DATE '1992-01-06'
  AND l.l_shipdate > DATE '1992-01-06';

-- Switch 4: 1992-01-18 -> 1992-01-19
-- RT(Pi, qi): Natural execution at qi=1992-01-18 (warm cache - run twice)
EXPLAIN (ANALYZE, FORMAT JSON) SELECT
    l.l_orderkey,
    l.l_extendedprice * (1 - l.l_discount) AS revenue,
    o.o_orderdate,
    o.o_shippriority
FROM customer c
JOIN orders o ON c.c_custkey = o.o_custkey
JOIN lineitem l ON l.l_orderkey = o.o_orderkey
WHERE c.c_mktsegment = 'BUILDING'
  AND o.o_orderdate < DATE '1992-01-18'
  AND l.l_shipdate > DATE '1992-01-18';

-- RT(Pj, qj): Natural execution at qj=1992-01-19 (warm cache - run twice)
EXPLAIN (ANALYZE, FORMAT JSON) SELECT
    l.l_orderkey,
    l.l_extendedprice * (1 - l.l_discount) AS revenue,
    o.o_orderdate,
    o.o_shippriority
FROM customer c
JOIN orders o ON c.c_custkey = o.o_custkey
JOIN lineitem l ON l.l_orderkey = o.o_orderkey
WHERE c.c_mktsegment = 'BUILDING'
  AND o.o_orderdate < DATE '1992-01-19'
  AND l.l_shipdate > DATE '1992-01-19';

-- RT(Pi, qj): Force Pi at qj=1992-01-19 (warm cache - run twice)
-- Hints: Leading(o c l), BitmapScan(o), SeqScan(c), IndexScan(l lineitem_pkey), NestLoop(o c l), HashJoin(o c)
EXPLAIN (ANALYZE, FORMAT JSON) /*+
Leading(o c l)
BitmapScan(o)
SeqScan(c)
IndexScan(l lineitem_pkey)
NestLoop(o c l)
HashJoin(o c)
*/ SELECT
    l.l_orderkey,
    l.l_extendedprice * (1 - l.l_discount) AS revenue,
    o.o_orderdate,
    o.o_shippriority
FROM customer c
JOIN orders o ON c.c_custkey = o.o_custkey
JOIN lineitem l ON l.l_orderkey = o.o_orderkey
WHERE c.c_mktsegment = 'BUILDING'
  AND o.o_orderdate < DATE '1992-01-19'
  AND l.l_shipdate > DATE '1992-01-19';

-- RT(Pj, qi): Force Pj at qi=1992-01-18 (warm cache - run twice)
-- Hints: Leading(l o c), SeqScan(l), BitmapScan(o), SeqScan(c), HashJoin(l o c), HashJoin(l o)
EXPLAIN (ANALYZE, FORMAT JSON) /*+
Leading(l o c)
SeqScan(l)
BitmapScan(o)
SeqScan(c)
HashJoin(l o c)
HashJoin(l o)
*/ SELECT
    l.l_orderkey,
    l.l_extendedprice * (1 - l.l_discount) AS revenue,
    o.o_orderdate,
    o.o_shippriority
FROM customer c
JOIN orders o ON c.c_custkey = o.o_custkey
JOIN lineitem l ON l.l_orderkey = o.o_orderkey
WHERE c.c_mktsegment = 'BUILDING'
  AND o.o_orderdate < DATE '1992-01-18'
  AND l.l_shipdate > DATE '1992-01-18';

-- Switch 5: 1992-02-14 -> 1992-02-15
-- RT(Pi, qi): Natural execution at qi=1992-02-14 (warm cache - run twice)
EXPLAIN (ANALYZE, FORMAT JSON) SELECT
    l.l_orderkey,
    l.l_extendedprice * (1 - l.l_discount) AS revenue,
    o.o_orderdate,
    o.o_shippriority
FROM customer c
JOIN orders o ON c.c_custkey = o.o_custkey
JOIN lineitem l ON l.l_orderkey = o.o_orderkey
WHERE c.c_mktsegment = 'BUILDING'
  AND o.o_orderdate < DATE '1992-02-14'
  AND l.l_shipdate > DATE '1992-02-14';

-- RT(Pj, qj): Natural execution at qj=1992-02-15 (warm cache - run twice)
EXPLAIN (ANALYZE, FORMAT JSON) SELECT
    l.l_orderkey,
    l.l_extendedprice * (1 - l.l_discount) AS revenue,
    o.o_orderdate,
    o.o_shippriority
FROM customer c
JOIN orders o ON c.c_custkey = o.o_custkey
JOIN lineitem l ON l.l_orderkey = o.o_orderkey
WHERE c.c_mktsegment = 'BUILDING'
  AND o.o_orderdate < DATE '1992-02-15'
  AND l.l_shipdate > DATE '1992-02-15';

-- RT(Pi, qj): Force Pi at qj=1992-02-15 (warm cache - run twice)
-- Hints: Leading(l o c), SeqScan(l), BitmapScan(o), SeqScan(c), HashJoin(l o c), HashJoin(l o)
EXPLAIN (ANALYZE, FORMAT JSON) /*+
Leading(l o c)
SeqScan(l)
BitmapScan(o)
SeqScan(c)
HashJoin(l o c)
HashJoin(l o)
*/ SELECT
    l.l_orderkey,
    l.l_extendedprice * (1 - l.l_discount) AS revenue,
    o.o_orderdate,
    o.o_shippriority
FROM customer c
JOIN orders o ON c.c_custkey = o.o_custkey
JOIN lineitem l ON l.l_orderkey = o.o_orderkey
WHERE c.c_mktsegment = 'BUILDING'
  AND o.o_orderdate < DATE '1992-02-15'
  AND l.l_shipdate > DATE '1992-02-15';

-- RT(Pj, qi): Force Pj at qi=1992-02-14 (warm cache - run twice)
-- Hints: Leading(l o c), SeqScan(l), SeqScan(o), SeqScan(c), HashJoin(l o c), HashJoin(l o)
EXPLAIN (ANALYZE, FORMAT JSON) /*+
Leading(l o c)
SeqScan(l)
SeqScan(o)
SeqScan(c)
HashJoin(l o c)
HashJoin(l o)
*/ SELECT
    l.l_orderkey,
    l.l_extendedprice * (1 - l.l_discount) AS revenue,
    o.o_orderdate,
    o.o_shippriority
FROM customer c
JOIN orders o ON c.c_custkey = o.o_custkey
JOIN lineitem l ON l.l_orderkey = o.o_orderkey
WHERE c.c_mktsegment = 'BUILDING'
  AND o.o_orderdate < DATE '1992-02-14'
  AND l.l_shipdate > DATE '1992-02-14';

-- Switch 6: 1992-03-08 -> 1992-03-09
-- RT(Pi, qi): Natural execution at qi=1992-03-08 (warm cache - run twice)
EXPLAIN (ANALYZE, FORMAT JSON) SELECT
    l.l_orderkey,
    l.l_extendedprice * (1 - l.l_discount) AS revenue,
    o.o_orderdate,
    o.o_shippriority
FROM customer c
JOIN orders o ON c.c_custkey = o.o_custkey
JOIN lineitem l ON l.l_orderkey = o.o_orderkey
WHERE c.c_mktsegment = 'BUILDING'
  AND o.o_orderdate < DATE '1992-03-08'
  AND l.l_shipdate > DATE '1992-03-08';

-- RT(Pj, qj): Natural execution at qj=1992-03-09 (warm cache - run twice)
EXPLAIN (ANALYZE, FORMAT JSON) SELECT
    l.l_orderkey,
    l.l_extendedprice * (1 - l.l_discount) AS revenue,
    o.o_orderdate,
    o.o_shippriority
FROM customer c
JOIN orders o ON c.c_custkey = o.o_custkey
JOIN lineitem l ON l.l_orderkey = o.o_orderkey
WHERE c.c_mktsegment = 'BUILDING'
  AND o.o_orderdate < DATE '1992-03-09'
  AND l.l_shipdate > DATE '1992-03-09';

-- RT(Pi, qj): Force Pi at qj=1992-03-09 (warm cache - run twice)
-- Hints: Leading(l o c), SeqScan(l), SeqScan(o), SeqScan(c), HashJoin(l o c), HashJoin(l o)
EXPLAIN (ANALYZE, FORMAT JSON) /*+
Leading(l o c)
SeqScan(l)
SeqScan(o)
SeqScan(c)
HashJoin(l o c)
HashJoin(l o)
*/ SELECT
    l.l_orderkey,
    l.l_extendedprice * (1 - l.l_discount) AS revenue,
    o.o_orderdate,
    o.o_shippriority
FROM customer c
JOIN orders o ON c.c_custkey = o.o_custkey
JOIN lineitem l ON l.l_orderkey = o.o_orderkey
WHERE c.c_mktsegment = 'BUILDING'
  AND o.o_orderdate < DATE '1992-03-09'
  AND l.l_shipdate > DATE '1992-03-09';

-- RT(Pj, qi): Force Pj at qi=1992-03-08 (warm cache - run twice)
-- Hints: Leading(l o c), SeqScan(l), SeqScan(o), SeqScan(c), HashJoin(l o c), HashJoin(o c)
EXPLAIN (ANALYZE, FORMAT JSON) /*+
Leading(l o c)
SeqScan(l)
SeqScan(o)
SeqScan(c)
HashJoin(l o c)
HashJoin(o c)
*/ SELECT
    l.l_orderkey,
    l.l_extendedprice * (1 - l.l_discount) AS revenue,
    o.o_orderdate,
    o.o_shippriority
FROM customer c
JOIN orders o ON c.c_custkey = o.o_custkey
JOIN lineitem l ON l.l_orderkey = o.o_orderkey
WHERE c.c_mktsegment = 'BUILDING'
  AND o.o_orderdate < DATE '1992-03-08'
  AND l.l_shipdate > DATE '1992-03-08';

-- Switch 7: 1992-03-13 -> 1992-03-14
-- RT(Pi, qi): Natural execution at qi=1992-03-13 (warm cache - run twice)
EXPLAIN (ANALYZE, FORMAT JSON) SELECT
    l.l_orderkey,
    l.l_extendedprice * (1 - l.l_discount) AS revenue,
    o.o_orderdate,
    o.o_shippriority
FROM customer c
JOIN orders o ON c.c_custkey = o.o_custkey
JOIN lineitem l ON l.l_orderkey = o.o_orderkey
WHERE c.c_mktsegment = 'BUILDING'
  AND o.o_orderdate < DATE '1992-03-13'
  AND l.l_shipdate > DATE '1992-03-13';

-- RT(Pj, qj): Natural execution at qj=1992-03-14 (warm cache - run twice)
EXPLAIN (ANALYZE, FORMAT JSON) SELECT
    l.l_orderkey,
    l.l_extendedprice * (1 - l.l_discount) AS revenue,
    o.o_orderdate,
    o.o_shippriority
FROM customer c
JOIN orders o ON c.c_custkey = o.o_custkey
JOIN lineitem l ON l.l_orderkey = o.o_orderkey
WHERE c.c_mktsegment = 'BUILDING'
  AND o.o_orderdate < DATE '1992-03-14'
  AND l.l_shipdate > DATE '1992-03-14';

-- RT(Pi, qj): Force Pi at qj=1992-03-14 (warm cache - run twice)
-- Hints: Leading(l o c), SeqScan(l), SeqScan(o), SeqScan(c), HashJoin(l o c), HashJoin(o c)
EXPLAIN (ANALYZE, FORMAT JSON) /*+
Leading(l o c)
SeqScan(l)
SeqScan(o)
SeqScan(c)
HashJoin(l o c)
HashJoin(o c)
*/ SELECT
    l.l_orderkey,
    l.l_extendedprice * (1 - l.l_discount) AS revenue,
    o.o_orderdate,
    o.o_shippriority
FROM customer c
JOIN orders o ON c.c_custkey = o.o_custkey
JOIN lineitem l ON l.l_orderkey = o.o_orderkey
WHERE c.c_mktsegment = 'BUILDING'
  AND o.o_orderdate < DATE '1992-03-14'
  AND l.l_shipdate > DATE '1992-03-14';

-- RT(Pj, qi): Force Pj at qi=1992-03-13 (warm cache - run twice)
-- Hints: Leading(l o c), SeqScan(l), BitmapScan(o), SeqScan(c), HashJoin(l o c), HashJoin(o c)
EXPLAIN (ANALYZE, FORMAT JSON) /*+
Leading(l o c)
SeqScan(l)
BitmapScan(o)
SeqScan(c)
HashJoin(l o c)
HashJoin(o c)
*/ SELECT
    l.l_orderkey,
    l.l_extendedprice * (1 - l.l_discount) AS revenue,
    o.o_orderdate,
    o.o_shippriority
FROM customer c
JOIN orders o ON c.c_custkey = o.o_custkey
JOIN lineitem l ON l.l_orderkey = o.o_orderkey
WHERE c.c_mktsegment = 'BUILDING'
  AND o.o_orderdate < DATE '1992-03-13'
  AND l.l_shipdate > DATE '1992-03-13';

-- Switch 8: 1992-05-16 -> 1992-05-17
-- RT(Pi, qi): Natural execution at qi=1992-05-16
EXPLAIN (ANALYZE, FORMAT JSON) SELECT
    l.l_orderkey,
    l.l_extendedprice * (1 - l.l_discount) AS revenue,
    o.o_orderdate,
    o.o_shippriority
FROM customer c
JOIN orders o ON c.c_custkey = o.o_custkey
JOIN lineitem l ON l.l_orderkey = o.o_orderkey
WHERE c.c_mktsegment = 'BUILDING'
  AND o.o_orderdate < DATE '1992-05-16'
  AND l.l_shipdate > DATE '1992-05-16';

-- RT(Pj, qj): Natural execution at qj=1992-05-17
EXPLAIN (ANALYZE, FORMAT JSON) SELECT
    l.l_orderkey,
    l.l_extendedprice * (1 - l.l_discount) AS revenue,
    o.o_orderdate,
    o.o_shippriority
FROM customer c
JOIN orders o ON c.c_custkey = o.o_custkey
JOIN lineitem l ON l.l_orderkey = o.o_orderkey
WHERE c.c_mktsegment = 'BUILDING'
  AND o.o_orderdate < DATE '1992-05-17'
  AND l.l_shipdate > DATE '1992-05-17';

-- RT(Pi, qj): Force Pi at qj=1992-05-17 
-- Hints: Leading(l o c), SeqScan(l), BitmapScan(o), SeqScan(c), HashJoin(l o c), HashJoin(o c)
EXPLAIN (ANALYZE, FORMAT JSON) /*+
Leading(l o c)
SeqScan(l)
BitmapScan(o)
SeqScan(c)
HashJoin(l o c)
HashJoin(o c)
*/ SELECT
    l.l_orderkey,
    l.l_extendedprice * (1 - l.l_discount) AS revenue,
    o.o_orderdate,
    o.o_shippriority
FROM customer c
JOIN orders o ON c.c_custkey = o.o_custkey
JOIN lineitem l ON l.l_orderkey = o.o_orderkey
WHERE c.c_mktsegment = 'BUILDING'
  AND o.o_orderdate < DATE '1992-05-17'
  AND l.l_shipdate > DATE '1992-05-17';

-- RT(Pj, qi): Force Pj at qi=1992-05-16
-- Hints: Leading(l o c), SeqScan(l), SeqScan(o), SeqScan(c), HashJoin(l o c), HashJoin(o c)
EXPLAIN (ANALYZE, FORMAT JSON) /*+
Leading(l o c)
SeqScan(l)
SeqScan(o)
SeqScan(c)
HashJoin(l o c)
HashJoin(o c)
*/ SELECT
    l.l_orderkey,
    l.l_extendedprice * (1 - l.l_discount) AS revenue,
    o.o_orderdate,
    o.o_shippriority
FROM customer c
JOIN orders o ON c.c_custkey = o.o_custkey
JOIN lineitem l ON l.l_orderkey = o.o_orderkey
WHERE c.c_mktsegment = 'BUILDING'
  AND o.o_orderdate < DATE '1992-05-16'
  AND l.l_shipdate > DATE '1992-05-16';