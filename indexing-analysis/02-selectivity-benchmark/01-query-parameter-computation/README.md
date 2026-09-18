# Query Parameter Computation for Target Selectivity

## OBJECTIVE :

The program is written to find the value X (query parameter) that achieves a target selectivity value (between 0 and 1) on the given input Column.
Selectivity is the fraction of total rows returned.

* INPUT -  a column name and a target selectivity value (between 0 and 1)
* OUTPUT - query parameter value X

## IMPLEMENTATION DETAILS : 

Brute Force Implementation - We can check every different possible value in the column and check how many rows satisfy <=X to match selectivity.

This implementation utilizes PostgreSQL's built-in Inverse Distribution Functions - percentile_disc(selectivity) function as a tool to find the exact value in your data that marks a specific cut-off point using rank-based retrieval method.

1. __LOGIC / Working of percentile_disc__ :

* We first sort the column for all 'N' rows.
* We calculate Rank(r) = N x selectivity 
* Round up 'r' to the Nearest whole number
* Value that 'r' points to will be desired X.

2. __Execution Flow__ : 

* Total Row Calculation: The script first counts the total rows in the lineitem table to calculate the actual selectivity later.Type 
* Validation: It queries the information_schema to ensure the provided column is a numeric, date, or text type that supports ordering.
* Threshold Computation: It executes the percentile_disc query to find the parameter $X$.
* Verification: It runs a final COUNT(*) query using the computed $X$ to verify the Actual Selectivity and ensure it meets the + or - 1% tolerance requirement.

## Installation 

1. __Requirements__ : __Python 3.x__ version & __psycopg2-binary__ (PostgreSQL adapter for Python)

__To install psycopg2-binary__ : pip install psycopg2-binary
__Execution command__ : python3 task.py <column_name> <target_selectivity>

2. __Output Format__ : 

    ```bash
    QUERY_PARAMETER: 'calculated threshold value'
    QUERIES_EXECUTED: 'total number of SQL queries sent to the database'
    ACTUAL_SELECTIVITY: 'verified selectivity (rows returned / total rows)'
    ```


## REASONING BEHING APPROACH :

Comparision of percentile_disc approach to brute force -

* Finds the threshold in one logical operation instead of running multiple COUNT(*) queries for every guess.
* Rank-Based: Navigates to specific row position rather than guessing random values that might not exist
* Index Optimized: It can use a B-tree index to navigate directly to the target row, turning a slow table scan into a fast pointer lookup.
* Guaranteed to return an actual value from your table
* Reduced I/O: It minimizes disk reads by avoiding the repeated table processing required by iterative search loops.

## CODE OVERVIEW : 

* ```bash __connect_to_db()__ : ```
Establishes a connection to the PostgreSQL database using psycopg2. The program exits gracefully if the connection fails.

* ```bash __get_total_rows(cursor)__ ```:
Executes a COUNT(*) query on the lineitem table to determine the total number of rows, which is required to compute selectivity.

* ```bash __get_column_type(cursor, column_name)__ ```: 
Validates the user-provided column name by querying information_schema.columns. This ensures the column exists and prevents invalid or unsafe queries.

* ```bash __get_threshold_value(cursor, column_name, selectivity)__ ```:
Uses PostgreSQL’s percentile_disc to compute the threshold value for the target selectivity.

* ```bash  __verify_selectivity(cursor, column_name, threshold, total_rows)__ ```: 
Verifies the actual selectivity achieved by executing a COUNT(*) query with the threshold that is computed and dividing by the total row count.

* ```bash __main()__ ```: 
Handles command-line argument parsing, input validation, execution flow, query counting, and also prints the final output in the required format.

## Results : 

The following are the results when run on terminal to evaluate the program on different columns and target selectivities. Each execution reports the computed query parameter, the number of SQL queries executed, and the actual selectivity achieved

```bash 
python3 task.py l_orderkey 0.25
QUERY_PARAMETER: 14999910
QUERIES_EXECUTED: 4
ACTUAL_SELECTIVITY: 0.2500


python3 task.py l_partkey 0.25
QUERY_PARAMETER: 500197
QUERIES_EXECUTED: 4
ACTUAL_SELECTIVITY: 0.2500

python3 task.py l_suppkey 0.25
QUERY_PARAMETER: 25005
QUERIES_EXECUTED: 4
ACTUAL_SELECTIVITY: 0.2500

python3 task.py l_linenumber 0.25
QUERY_PARAMETER: 1
QUERIES_EXECUTED: 4
ACTUAL_SELECTIVITY: 0.2501

python3 task.py l_quantity 0.25
QUERY_PARAMETER: 13
QUERIES_EXECUTED: 4
ACTUAL_SELECTIVITY: 0.2600

python3 task.py l_extendedprice 0.25
QUERY_PARAMETER: 18716.15
QUERIES_EXECUTED: 4
ACTUAL_SELECTIVITY: 0.2500

Diff selectivity:
python3 task.py l_extendedprice 0.10
QUERY_PARAMETER: 7887.68
QUERIES_EXECUTED: 4
ACTUAL_SELECTIVITY: 0.1000

python3 task.py l_discount 0.27
QUERY_PARAMETER: 0.02
QUERIES_EXECUTED: 4
ACTUAL_SELECTIVITY: 0.2727

python3 task.py l_tax 0.33
QUERY_PARAMETER: 0.02
QUERIES_EXECUTED: 4
ACTUAL_SELECTIVITY: 0.3331


python3 task.py l_shipdate 0.25
QUERY_PARAMETER: 1993-10-24
QUERIES_EXECUTED: 4
ACTUAL_SELECTIVITY: 0.2502

python3 task.py l_commitdate 0.25
QUERY_PARAMETER: 1993-10-23
QUERIES_EXECUTED: 4
ACTUAL_SELECTIVITY: 0.2502

python3 task.py l_receiptdate 0.25
QUERY_PARAMETER: 1993-11-08
QUERIES_EXECUTED: 4
ACTUAL_SELECTIVITY: 0.2500

python3 task.py l_returnflag 0.75
QUERY_PARAMETER: N
QUERIES_EXECUTED: 4
ACTUAL_SELECTIVITY: 0.7531

python3 task.py l_linestatus 0.50
QUERY_PARAMETER: F
QUERIES_EXECUTED: 4
ACTUAL_SELECTIVITY: 0.5001

python3 task.py l_shipinstruct 0.49
QUERY_PARAMETER: DELIVER IN PERSON
QUERIES_EXECUTED: 4
ACTUAL_SELECTIVITY: 0.4999

python3 task.py l_shipmode 0.28
QUERY_PARAMETER: FOB
QUERIES_EXECUTED: 4
ACTUAL_SELECTIVITY: 0.2857

python3 task.py l_comment 0.25
QUERY_PARAMETER: ckages haggle blithely. blithely expre
QUERIES_EXECUTED: 4
ACTUAL_SELECTIVITY: 0.2500
```








