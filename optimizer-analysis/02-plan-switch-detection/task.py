import psycopg2
import json
import sys
from datetime import date, timedelta
import os

# ─── DB CONNECTION ───────────────────────────────────────────────
conn = psycopg2.connect(
    host=os.getenv("DB_HOST"),
    dbname=os.getenv("DB_NAME"),
    user=os.getenv("DB_USER"),
    password=os.getenv("DB_PASSWORD"),
    port=os.getenv("DB_PORT")
)
conn.autocommit = True
cursor = conn.cursor()

# ─── QUERY TEMPLATES ─────────────────────────────────────────────
QUERIES = {
    1: """
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
        WHERE l_shipdate <= '{date}'
    """,
    2: """
        SELECT
            o_orderpriority,
            count(*) AS order_count
        FROM orders
        WHERE
            o_orderdate >= DATE '1992-01-01'
            AND o_orderdate < DATE '{date}'
            AND EXISTS (
                SELECT 1
                FROM lineitem
                WHERE l_orderkey = o_orderkey
                AND l_commitdate < l_receiptdate
            )
        GROUP BY o_orderpriority
    """,
    3: """
        SELECT
            l.l_orderkey,
            l.l_extendedprice * (1 - l.l_discount) AS revenue,
            o.o_orderdate,
            o.o_shippriority
        FROM
            customer c
            JOIN orders o ON c.c_custkey = o.o_custkey
            JOIN lineitem l ON l.l_orderkey = o.o_orderkey
        WHERE
            c.c_mktsegment = 'BUILDING'
            AND o.o_orderdate < DATE '{date}'
            AND l.l_shipdate > DATE '{date}'
    """
}

# ─── DATE RANGES FOR EACH QUERY ──────────────────────────────────
def get_date_range(query_num):
    if query_num == 1:
        cursor.execute("SELECT MIN(l_shipdate), MAX(l_shipdate) FROM lineitem")
    elif query_num == 2:
        cursor.execute("SELECT MIN(o_orderdate), MAX(o_orderdate) FROM orders")
    elif query_num == 3:
        # Both predicates use same DATE, use orders date range
        cursor.execute("SELECT MIN(o_orderdate), MAX(o_orderdate) FROM orders")
    row = cursor.fetchone()
    return row[0], row[1]

# ─── GET PLAN FOR A DATE ─────────────────────────────────────────
def get_plan(query_num, date_val):
    query = QUERIES[query_num].format(date=date_val)
    explain_query = f"EXPLAIN (FORMAT JSON) {query}"
    cursor.execute(explain_query)
    row = cursor.fetchone()
    plan_json = row[0]  # psycopg2 auto-parses JSON
    return plan_json[0]["Plan"]

# ─── EXTRACT STRUCTURE (from Task 1) ─────────────────────────────
def extract_structure(plan):
    if plan is None:
        return None

    structure = {"Node Type": plan.get("Node Type")}

    if "Join Type" in plan:
        structure["Join Type"] = plan["Join Type"]
    if "Scan Direction" in plan:
        structure["Scan Direction"] = plan["Scan Direction"]
    if "Relation Name" in plan:
        structure["Relation Name"] = plan["Relation Name"]
    if "Index Name" in plan:
        structure["Index Name"] = plan["Index Name"]
    if "Strategy" in plan:
        structure["Strategy"] = plan["Strategy"]
    if "Plans" in plan:
        structure["Plans"] = [extract_structure(child) for child in plan["Plans"]]

    return structure

# ─── COMPARE TWO PLANS ───────────────────────────────────────────
def plans_equivalent(plan1, plan2):
    return extract_structure(plan1) == extract_structure(plan2)

# ─── BINARY SEARCH FOR PLAN SWITCHES ────────────────────────────
def find_switches(query_num, start_date, end_date):
    """
    Recursively binary searches the date range to find all plan switches.
    Returns a list of (date_before_switch, date_after_switch) tuples.
    """
    switches = []

    plan_start = get_plan(query_num, start_date)
    plan_end = get_plan(query_num, end_date)

    # Base case: dates are adjacent (differ by 1 day)
    if (end_date - start_date).days <= 1:
        if not plans_equivalent(plan_start, plan_end):
            switches.append((start_date, end_date))
        return switches

    # If same plan, no switch in this range
    if plans_equivalent(plan_start, plan_end):
        return switches

    # Different plans — binary search for the switch
    mid_date = start_date + (end_date - start_date) / 2

    # Search left half
    switches += find_switches(query_num, start_date, mid_date)
    # Search right half
    switches += find_switches(query_num, mid_date, end_date)

    return switches

# ─── FORMAT PLAN STRUCTURE FOR OUTPUT ───────────────────────────
def format_structure(structure, indent=0):
    if structure is None:
        return ""
    prefix = "  " * indent
    result = f"{prefix}{structure['Node Type']}"
    if "Strategy" in structure:
        result += f" ({structure['Strategy']})"
    if "Relation Name" in structure:
        result += f" on {structure['Relation Name']}"
    if "Index Name" in structure:
        result += f" using {structure['Index Name']}"
    if "Join Type" in structure:
        result += f" [{structure['Join Type']}]"
    result += "\n"
    for child in structure.get("Plans", []):
        result += format_structure(child, indent + 1)
    return result

# ─── MAIN ────────────────────────────────────────────────────────
def main():
    output_lines = []

    for query_num in [1, 2, 3]:
        print(f"\nProcessing Query {query_num}...")
        output_lines.append(f"Query {query_num}:")

        start_date, end_date = get_date_range(query_num)
        print(f"  Date range: {start_date} to {end_date}")

        switches = find_switches(query_num, start_date, end_date)

        if not switches:
            print(f"  No plan switches found!")
            output_lines.append("  No plan switches detected.")
        else:
            print(f"  Found {len(switches)} plan switch(es)!")
            for i, (d1, d2) in enumerate(switches, 1):
                line = f"Plan Switch {i}: {d1} and {d2}"
                print(f"  {line}")
                output_lines.append(f"  {line}")

                # Print plans before and after switch
                plan_before = get_plan(query_num, d1)
                plan_after = get_plan(query_num, d2)
                struct_before = extract_structure(plan_before)
                struct_after = extract_structure(plan_after)
                print(f"    Plan before:\n{format_structure(struct_before, 3)}")
                print(f"    Plan after:\n{format_structure(struct_after, 3)}")

        output_lines.append("")

    # Write output.txt
    output_path = "/Users/manasvigampa/projects/postgres-query-optimizer-analyzer/optimizer-analysis/02-plan-switch-detection/output.txt"
    with open(output_path, "w") as f:
        f.write("\n".join(output_lines))

    print(f"\nOutput written to output.txt")
    cursor.close()
    conn.close()

if __name__ == "__main__":
    main()
