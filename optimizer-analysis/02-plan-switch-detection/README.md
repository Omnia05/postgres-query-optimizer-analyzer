# Plan Switch Detection

## Objective
The objective of this task is to identify all "plan switches" for three parameterized PostgreSQL queries. A plan switch occurs when the database query optimizer changes its underlying physical execution strategy (the query plan) due to a change in the selectivity of a variable parameter (in this case, a `[DATE]` parameter). 

## Methodology: Binary Search over Parameter Space
To find the exact dates where the execution plan changes, one could simply iterate through every single day in the dataset's date range and compare adjacent days ($O(N)$). However, this linear scan is highly inefficient, especially for large date ranges spanning several years.

Instead, this implementation utilizes a **Recursive Binary Search (Divide and Conquer)** approach, drastically reducing the number of database queries required.

### The Monotonicity Assumption
This optimized approach relies on the assignment's assumption that **plan cost monotonicity holds**. Because the estimated cost (and therefore the chosen plan) varies monotonically with the selectivity of the variable predicate:
1. If the execution plan at `start_date` is structurally identical to the plan at `end_date`, we can safely deduce that **no plan switches occurred anywhere between those two dates**.
2. If the plans differ, there must be at least one plan switch within that range. 

### Search Algorithm
1. The algorithm takes a date range `[start_date, end_date]`.
2. It fetches the compile-time plans for both boundary dates and compares their structural equivalence (reusing the structural extraction logic from Task 1).
3. If the plans are identical, it returns an empty list (no switches).
4. If the plans are different and the range is exactly 1 day apart, it records a plan switch between `start_date` and `end_date`.
5. If the plans differ and the range is larger than 1 day, it calculates the `mid_date`.
6. It then recursively calls itself on the left half `[start_date, mid_date]` and the right half `[mid_date, end_date]`, combining the discovered switches.

## Implementation Details

The solution is implemented in Python (`task.py`) and utilizes the `psycopg2` library to interact directly with the PostgreSQL database.

### 1. Dynamic Date Range Extraction
Instead of hardcoding the date ranges, the script dynamically queries the database to find the valid parameter domains:
* **Query 1:** `MIN` and `MAX` of `lineitem.l_shipdate`
* **Query 2 & 3:** `MIN` and `MAX` of `orders.o_orderdate`

### 2. Plan Generation and Extraction
The script uses the `EXPLAIN (FORMAT JSON)` command to retrieve compile-time plans from PostgreSQL. 
It then filters out cost estimates, row counts, and specific filter parameters using the `extract_structure` function (developed in Task 01). This ensures that we are strictly comparing the physical operator trees (e.g., Node Types, Join Types, Index Names).

## Prerequisites
* Python 3.x
* `psycopg2` library (`pip install psycopg2-binary`)
* A running PostgreSQL instance containing the `tpch_db` database.

## How to Run

1. Ensure your PostgreSQL server is running and the credentials in the `conn = psycopg2.connect(...)` block of `task.py` match your local setup.
2. Execute the script from the command line:
   ```bash
   python task.py