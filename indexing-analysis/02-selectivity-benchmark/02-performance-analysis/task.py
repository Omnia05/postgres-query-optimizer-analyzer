import psycopg2
import sys
import json
import os


# ------------------------------------------------------------
# Database Connection 
# ------------------------------------------------------------

def connect_to_db():
    try:
        conn = psycopg2.connect(
            host=os.getenv("DB_HOST"),
            database=os.getenv("DB_NAME"),
            user=os.getenv("DB_USER"),
            password=os.getenv("DB_PASSWORD")
        )
        return conn
    except Exception as e:
        print(f"Error connecting to database: {e}")
        sys.exit(1)


# ------------------------------------------------------------
# Helper Functions (from Part A)
# ------------------------------------------------------------

def get_total_rows(cursor):
    cursor.execute("SELECT COUNT(*) FROM lineitem;")
    return cursor.fetchone()[0]


def get_threshold_value(cursor, selectivity):
    cursor.execute("""
        SELECT percentile_disc(%s)
        WITHIN GROUP (ORDER BY l_quantity)
        FROM lineitem;
    """, (selectivity,))
    return cursor.fetchone()[0]


def get_actual_selectivity(cursor, threshold, total_rows):
    cursor.execute("""
        SELECT COUNT(*) FROM lineitem
        WHERE l_quantity <= %s;
    """, (threshold,))
    count = cursor.fetchone()[0]
    return count / total_rows


# ------------------------------------------------------------
# Compute all thresholds at once
# ------------------------------------------------------------

def compute_all_thresholds():

    conn = connect_to_db()
    cursor = conn.cursor()

    total_rows = get_total_rows(cursor)

    threshold_data = []

    for i in range(0, 101, 2):  
        target_selectivity = i / 100

        threshold = get_threshold_value(cursor, target_selectivity)
        actual_selectivity = get_actual_selectivity(
            cursor, threshold, total_rows
        )

        threshold_data.append({
            "target_selectivity": target_selectivity,
            "threshold": threshold,
            "actual_selectivity": actual_selectivity
        })

    cursor.close()
    conn.close()

    return threshold_data


# ------------------------------------------------------------
# Execute Query and Get Execution Time
# ------------------------------------------------------------

def execute_query(cursor, threshold, select_only=False):

    if select_only:
        query = """
            EXPLAIN (ANALYZE, FORMAT JSON)
            SELECT l_quantity FROM lineitem
            WHERE l_quantity <= %s;
        """
    else:
        query = """
            EXPLAIN (ANALYZE, FORMAT JSON)
            SELECT * FROM lineitem
            WHERE l_quantity <= %s;
        """

    cursor.execute(query, (threshold,))
    plan = cursor.fetchone()[0]
    execution_time = plan[0]["Execution Time"]

    return execution_time, plan


# ------------------------------------------------------------
# Run Scenario Using the Precomputed Thresholds
# ------------------------------------------------------------

def run_scenario(scenario_name,
                 threshold_data,
                 setup_sql=None,
                 disable_seqscan=False,
                 select_only=False):

    conn = connect_to_db()
    cursor = conn.cursor()

    # use setup SQL if provided
    if setup_sql:
        cursor.execute(setup_sql)
        conn.commit()

    # disable sequential scan if required
    if disable_seqscan:
        cursor.execute("SET enable_seqscan = OFF;")

    scenario_results = []

    for entry in threshold_data:

        threshold = entry["threshold"]
        actual_selectivity = entry["actual_selectivity"]

        execution_time, plan = execute_query(
            cursor, threshold, select_only
        )

        scenario_results.append({
            "target_selectivity": entry["target_selectivity"],
            "actual_selectivity": actual_selectivity,
            "execution_time_ms": execution_time,
            "plan": plan
        })

    # re-enable seqscan if disabled
    if disable_seqscan:
        cursor.execute("SET enable_seqscan = ON;")

    cursor.close()
    conn.close()

    # save one JSON file per scenario
    os.makedirs("query_plans", exist_ok=True)

    filename = f"query_plans/{scenario_name}.json"
    with open(filename, "w") as f:
        json.dump(scenario_results, f, indent=4)

    print(f"{scenario_name} completed.")

    return scenario_results


# ------------------------------------------------------------
# Main
# ------------------------------------------------------------

def main():

    print("Computing thresholds.")
    threshold_data = compute_all_thresholds()

    # (a) Without Index
    run_scenario(
        scenario_name="without_index",
        threshold_data=threshold_data,
        setup_sql="DROP INDEX IF EXISTS idx_quantity;"
    )

    # (b) With Index
    run_scenario(
        scenario_name="with_index",
        threshold_data=threshold_data,
        setup_sql="""
            DROP INDEX IF EXISTS idx_quantity;
            CREATE INDEX idx_quantity ON lineitem(l_quantity);
        """
    )

    # (c) With Indexx, Disable Sequential Scan
    run_scenario(
        scenario_name="no_sequential_scan",
        threshold_data=threshold_data,
        disable_seqscan=True
    )

    # (d) Clustered Index
    run_scenario(
        scenario_name="clustered_index",
        threshold_data=threshold_data,
        setup_sql="""
            DROP INDEX IF EXISTS idx_quantity;
            CREATE INDEX idx_quantity ON lineitem(l_quantity);
            CLUSTER lineitem USING idx_quantity;
            ANALYZE lineitem;
        """
    )

    # (e) Select Only Column
    run_scenario(
        scenario_name="select_column",
        threshold_data=threshold_data,
        select_only=True
    )

    print("All scenarios completed successfully.")


if __name__ == "__main__":
    main()
