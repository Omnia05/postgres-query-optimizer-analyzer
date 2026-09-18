-- Query 6 Index Analysis
-- case 1 : without Index 

DROP INDEX IF EXISTS idx_shipdate;
DROP INDEX IF EXISTS idx_composite;
DROP INDEX IF EXISTS idx_dual;
DROP INDEX IF EXISTS idx_covering;

EXPLAIN (ANALYZE, FORMAT JSON)
SELECT SUM(l_extendedprice * l_discount) AS revenue
FROM lineitem
WHERE l_shipdate >= DATE '1994-01-01'
  AND l_shipdate <  DATE '1995-01-01'
  AND l_discount BETWEEN 0.05 AND 0.07
  AND l_quantity < 24;

-- Case 2: Single coloumn index on shipdate

CREATE INDEX idx_shipdate
ON lineitem (l_shipdate);

ANALYSE lineitem;

EXPLAIN (ANALYZE, FORMAT JSON)
SELECT SUM(l_extendedprice * l_discount) AS revenue
FROM lineitem
WHERE l_shipdate >= DATE '1994-01-01'
  AND l_shipdate <  DATE '1995-01-01'
  AND l_discount BETWEEN 0.05 AND 0.07
  AND l_quantity < 24;

DROP INDEX idx_shipdate;

-- Case 3: 2-coloumn index on shipdate, discount

CREATE INDEX idx_dual
ON lineitem (l_shipdate, l_discount);

ANALYSE lineitem;

EXPLAIN (ANALYZE, FORMAT JSON)
SELECT SUM(l_extendedprice * l_discount) AS revenue
FROM lineitem
WHERE l_shipdate >= DATE '1994-01-01'
  AND l_shipdate <  DATE '1995-01-01'
  AND l_discount BETWEEN 0.05 AND 0.07
  AND l_quantity < 24;

DROP INDEX idx_dual;

-- case 4:  3 column (composite index) on shipdate, discount and quantity

CREATE INDEX idx_composite
ON lineitem (l_shipdate, l_discount, l_quantity);

ANALYSE lineitem;

EXPLAIN (ANALYZE, FORMAT JSON)
SELECT SUM(l_extendedprice * l_discount) AS revenue
FROM lineitem
WHERE l_shipdate >= DATE '1994-01-01'
  AND l_shipdate <  DATE '1995-01-01'
  AND l_discount BETWEEN 0.05 AND 0.07
  AND l_quantity < 24;

DROP INDEX idx_composite;

-- case 5 : Covering index

CREATE INDEX idx_covering
ON lineitem (l_shipdate, l_discount, l_quantity)
INCLUDE (l_extendedprice);

ANALYSE lineitem;

EXPLAIN (ANALYZE, FORMAT JSON)
SELECT SUM(l_extendedprice * l_discount) AS revenue
FROM lineitem
WHERE l_shipdate >= DATE '1994-01-01'
  AND l_shipdate <  DATE '1995-01-01'
  AND l_discount BETWEEN 0.05 AND 0.07
  AND l_quantity < 24;

DROP INDEX idx_covering
