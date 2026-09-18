# Query Plan Comparison

## Objective
This program determines whether two PostgreSQL compile-time query execution plans are structurally identical. Structural equivalence means the plans use the exact same sequence of physical operators (e.g., scans, joins, aggregations) on the same relations/indexes, ignoring parameter values, cost estimates, and cardinality estimations.

## Approach and Implementation

The solution is implemented in Python and broken down into three main logical steps:

### 1. Pre-processing the `psql` Output (`extract_json`)
Often, query plans exported from the `psql` command-line interface are wrapped in ASCII table formatting (e.g., `QUERY PLAN`, `---`, trailing `+` signs, and `(1 row)` at the end). 
Before parsing the JSON, the script cleans the raw text file by stripping out these headers, footers, and line-continuation characters. This ensures the built-in `json` library can successfully parse the file.

### 2. Extracting the Physical Operator Tree (`extract_physical_operator_tree`)
PostgreSQL query plans contain a vast amount of information, much of which is highly sensitive to the specific parameters used in the query (like `Startup Cost`, `Total Cost`, `Plan Rows`, `Plan Width`, and `Filter` conditions). 

To compare purely the *structure* of the execution plans, this function recursively traverses the parsed JSON plan and extracts only the keys that define the physical operator tree. 

**Keys Retained:**
* `Node Type` (e.g., Seq Scan, Aggregate, Hash Join)
* `Join Type` (e.g., Inner, Semi)
* `Relation Name` (The table being accessed)
* `Index Name` (The index being used, if applicable)
* `Scan Direction` (e.g., Forward)
* `Strategy` (e.g., Plain, Hashed)
* `Plans` (Recursively parsed child operations)

**Keys Ignored:**
* Costs, row estimates, parallel workers planned, JIT metrics, and specific filter/index conditions.

### 3. Comparing the Plans (`compare_plans`)
Once the structural dictionaries are extracted for both plans, the program compares them using standard Python dictionary equality (`==`). Because dictionaries and lists in Python evaluate equality based on their deep contents, this effectively checks if the two operator trees are perfectly identical in structure and sequence.

## Prerequisites
* Python 3.x
* No external libraries are required (only standard libraries: `json`, `sys`).

## How to Generate Plan JSON Files

The input JSON files (`plan1.json` and `plan2.json`) are generated directly from the PostgreSQL database using the `EXPLAIN (FORMAT JSON)` command via the `psql` command-line interface.

To generate a plan, connect to your TPC-H database and use the `\o` command to redirect the query output to a file, followed by your query prefixed with `EXPLAIN (FORMAT JSON)`.

**Example for generating `plan1.json` (using Query 1 with DATE '1994-01-01'):**
```sql
-- 1. Redirect output to a file
\o plan1.json

-- 2. Run the EXPLAIN command with JSON format
EXPLAIN (FORMAT JSON)
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
WHERE l_shipdate <= '1994-01-01';

-- 3. Stop redirecting output
\o