import psycopg2
from datetime import date, timedelta
import os

# ─── DB CONNECTION ────────────────────────────────────────────────
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
    1: """SELECT
    SUM(l_quantity), SUM(l_extendedprice),
    SUM(l_extendedprice * (1 - l_discount)),
    SUM(l_extendedprice * (1 - l_discount) * (1 + l_tax)),
    AVG(l_quantity), AVG(l_extendedprice),
    AVG(l_discount), COUNT(*)
FROM lineitem
WHERE l_shipdate <= '{date}'""",

    2: """SELECT o_orderpriority, count(*) AS order_count
FROM orders
WHERE o_orderdate >= DATE '1992-01-01'
  AND o_orderdate < DATE '{date}'
  AND EXISTS (
      SELECT 1 FROM lineitem
      WHERE l_orderkey = o_orderkey
      AND l_commitdate < l_receiptdate
  )
GROUP BY o_orderpriority""",

    3: """SELECT
    l.l_orderkey,
    l.l_extendedprice * (1 - l.l_discount) AS revenue,
    o.o_orderdate,
    o.o_shippriority
FROM customer c
JOIN orders o ON c.c_custkey = o.o_custkey
JOIN lineitem l ON l.l_orderkey = o.o_orderkey
WHERE c.c_mktsegment = 'BUILDING'
  AND o.o_orderdate < DATE '{date}'
  AND l.l_shipdate > DATE '{date}'"""
}

# ─── DATA RANGES (from Task 02 output) ────────────────────────────
DATA_RANGES = {
    1: (date(1992, 1, 2),  date(1998, 12, 1)),
    2: (date(1992, 1, 1),  date(1998, 8,  2)),
    3: (date(1992, 1, 1),  date(1998, 8,  2)),
}

# ─── INCORRECT SWITCHES FROM TASK 03 (new warm-cache results) ─────
# Format: (query_num, switch_label, classification, di, dj)
INCORRECT_SWITCHES = [
    (1, "S2", "DELAYED", date(1992, 1, 27),  date(1992, 1, 28)),
    (1, "S3", "EARLY",   date(1992, 3, 29),  date(1992, 3, 30)),
    (2, "S1", "EARLY",   date(1992, 1,  1),  date(1992, 1,  2)),
    (2, "S2", "EARLY",   date(1992, 5, 13),  date(1992, 5, 14)),
    (3, "S1", "EARLY",   date(1992, 1,  1),  date(1992, 1,  2)),
    (3, "S2", "DELAYED", date(1992, 1,  3),  date(1992, 1,  4)),
    (3, "S3", "EARLY",   date(1992, 1,  6),  date(1992, 1,  7)),
    (3, "S4", "EARLY",   date(1992, 1, 18),  date(1992, 1, 19)),
    (3, "S6", "EARLY",   date(1992, 3,  8),  date(1992, 3,  9)),
    (3, "S7", "DELAYED", date(1992, 3, 13),  date(1992, 3, 14)),
]

# ─── EXTRACT STRUCTURE ────────────────────────────────────────────
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
        structure["Plans"] = [extract_structure(c) for c in plan["Plans"]]
    return structure

# ─── GET LEAF ALIASES ─────────────────────────────────────────────
def get_leaf_aliases(plan):
    if "Relation Name" in plan:
        return [plan.get("Alias", plan["Relation Name"])]
    aliases = []
    for child in plan.get("Plans", []):
        aliases.extend(get_leaf_aliases(child))
    return aliases

# ─── EXTRACT HINTS ────────────────────────────────────────────────
def extract_hints(plan):
    scan_hints = []
    join_hints = []

    def traverse(node):
        node_type = node.get("Node Type", "")
        alias = node.get("Alias", node.get("Relation Name", ""))
        index_name = node.get("Index Name", "")

        if node_type == "Seq Scan" and alias:
            scan_hints.append(f"SeqScan({alias})")
        elif node_type == "Index Scan" and alias:
            hint = f"IndexScan({alias} {index_name})" if index_name else f"IndexScan({alias})"
            scan_hints.append(hint)
        elif node_type == "Index Only Scan" and alias:
            hint = f"IndexOnlyScan({alias} {index_name})" if index_name else f"IndexOnlyScan({alias})"
            scan_hints.append(hint)
        elif node_type == "Bitmap Heap Scan" and alias:
            scan_hints.append(f"BitmapScan({alias})")

        if node_type in ("Nested Loop", "Hash Join", "Merge Join"):
            leaves = get_leaf_aliases(node)
            if node_type == "Nested Loop":
                join_hints.append(f"NestLoop({' '.join(leaves)})")
            elif node_type == "Hash Join":
                join_hints.append(f"HashJoin({' '.join(leaves)})")
            elif node_type == "Merge Join":
                join_hints.append(f"MergeJoin({' '.join(leaves)})")

        for child in node.get("Plans", []):
            traverse(child)

    traverse(plan)
    leaf_aliases = get_leaf_aliases(plan)
    leading = f"Leading({' '.join(leaf_aliases)})"
    all_hints = [leading] + scan_hints + join_hints
    return "\n".join(all_hints)

# ─── GET NATURAL PLAN ─────────────────────────────────────────────
def get_plan(query_num, date_val):
    base_query = QUERIES[query_num].format(date=date_val)
    cursor.execute(f"EXPLAIN (FORMAT JSON) {base_query}")
    row = cursor.fetchone()
    return row[0][0]["Plan"]

# ─── MEASURE RUNTIME (WARM CACHE) ────────────────────────────────
def measure_runtime(query_num, date_val, hint_str=None):
    """Run twice, record second run (warm cache)."""
    base_query = QUERIES[query_num].format(date=date_val)
    if hint_str:
        full_query = f"EXPLAIN (ANALYZE, FORMAT JSON) /*+\n{hint_str}\n*/ {base_query}"
    else:
        full_query = f"EXPLAIN (ANALYZE, FORMAT JSON) {base_query}"
    # Warm up
    cursor.execute(full_query)
    cursor.fetchone()
    # Record
    cursor.execute(full_query)
    row = cursor.fetchone()
    return row[0][0].get("Execution Time", 0.0)

# ─── FORMAT STRUCTURE ─────────────────────────────────────────────
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

# ─── BINARY SEARCH FOR OPTIMAL SWITCH ────────────────────────────
def find_optimal_switch(query_num, hints_i, hints_j, classification, di, dj):
    """
    DELAYED: Pj already faster at di. Search BEFORE di for crossover.
             Binary search in [data_start, di] for last date Pi is better.

    EARLY:   Pi still faster at dj. Search AFTER dj for crossover.
             Binary search in [dj, data_end] for first date Pj becomes better.

    Returns (d_star_i, d_star_j) — optimal adjacent switch pair.
    Pi better at d_star_i, Pj better at d_star_j.
    """
    data_start, data_end = DATA_RANGES[query_num]

    if classification == "DELAYED":
        search_start = data_start
        search_end   = di

        # Boundary check: is Pi better at data_start?
        rt_pi = measure_runtime(query_num, search_start, hints_i)
        rt_pj = measure_runtime(query_num, search_start, hints_j)
        print(f"      Boundary [{search_start}]: RT(Pi)={rt_pi:.1f}ms RT(Pj)={rt_pj:.1f}ms")

        if rt_pj <= rt_pi:
            print(f"      Pj better even at data_start — optimal switch is at very beginning")
            return search_start, search_start + timedelta(days=1)

        # Binary search: find last date where Pi is still better
        start = search_start
        end   = search_end

        while (end - start).days > 1:
            mid = start + timedelta(days=(end - start).days // 2)
            rt_pi = measure_runtime(query_num, mid, hints_i)
            rt_pj = measure_runtime(query_num, mid, hints_j)
            print(f"      [{start} ... {mid} ... {end}] RT(Pi)={rt_pi:.1f} RT(Pj)={rt_pj:.1f}", end=" ")
            if rt_pi <= rt_pj:
                # Pi still better at mid → crossover is to the right
                start = mid
                print("→ Pi better, search RIGHT")
            else:
                # Pj better at mid → crossover is to the left
                end = mid
                print("→ Pj better, search LEFT")

        return start, end

    elif classification == "EARLY":
        search_start = dj
        search_end   = data_end

        # Boundary check: does Pj eventually become better?
        rt_pi = measure_runtime(query_num, search_end, hints_i)
        rt_pj = measure_runtime(query_num, search_end, hints_j)
        print(f"      Boundary [{search_end}]: RT(Pi)={rt_pi:.1f}ms RT(Pj)={rt_pj:.1f}ms")

        if rt_pi <= rt_pj:
            print(f"      Pi always better in range — no crossover found")
            return None, None

        # Binary search: find first date where Pj becomes better
        start = search_start
        end   = search_end

        while (end - start).days > 1:
            mid = start + timedelta(days=(end - start).days // 2)
            rt_pi = measure_runtime(query_num, mid, hints_i)
            rt_pj = measure_runtime(query_num, mid, hints_j)
            print(f"      [{start} ... {mid} ... {end}] RT(Pi)={rt_pi:.1f} RT(Pj)={rt_pj:.1f}", end=" ")
            if rt_pi <= rt_pj:
                # Pi still better at mid → crossover is to the right
                start = mid
                print("→ Pi better, search RIGHT")
            else:
                # Pj better at mid → crossover is to the left
                end = mid
                print("→ Pj better, search LEFT")

        return start, end

# ─── VALIDATE OPTIMAL SWITCH ─────────────────────────────────────
def validate(query_num, hints_i, hints_j, d_star_i, d_star_j):
    """Measure all 4 RTs at optimal switch point."""
    print(f"      Measuring RT(Pi, d*i={d_star_i})...", end=" ", flush=True)
    rt_pi_qi = measure_runtime(query_num, d_star_i, hints_i)
    print(f"{rt_pi_qi:.2f} ms")

    print(f"      Measuring RT(Pj, d*j={d_star_j})...", end=" ", flush=True)
    rt_pj_qj = measure_runtime(query_num, d_star_j, hints_j)
    print(f"{rt_pj_qj:.2f} ms")

    print(f"      Measuring RT(Pi, d*j={d_star_j}) [forced]...", end=" ", flush=True)
    rt_pi_qj = measure_runtime(query_num, d_star_j, hints_i)
    print(f"{rt_pi_qj:.2f} ms")

    print(f"      Measuring RT(Pj, d*i={d_star_i}) [forced]...", end=" ", flush=True)
    rt_pj_qi = measure_runtime(query_num, d_star_i, hints_j)
    print(f"{rt_pj_qi:.2f} ms")

    return rt_pi_qi, rt_pj_qj, rt_pi_qj, rt_pj_qi

# ─── MAIN ─────────────────────────────────────────────────────────
def main():
    results_lines = []
    results_lines.append("Plan Switch Correction Results")
    results_lines.append("=" * 60)

    for (query_num, switch_label, classification, di, dj) in INCORRECT_SWITCHES:
        print(f"\n{'='*60}")
        print(f"Query {query_num} — Switch {switch_label} ({classification})")
        print(f"  Optimizer's switch: {di} → {dj}")
        print(f"{'='*60}")

        # Get Pi at di and Pj at dj (natural plans)
        plan_i = get_plan(query_num, di)
        plan_j = get_plan(query_num, dj)
        hints_i = extract_hints(plan_i)
        hints_j = extract_hints(plan_j)
        struct_i = extract_structure(plan_i)
        struct_j = extract_structure(plan_j)

        result_block = (
            f"\nQuery {query_num} — Switch {switch_label} ({classification})\n"
            f"  Optimizer's switch: {di} → {dj}\n"
            f"  Plan Pi:\n{format_structure(struct_i, 2)}"
            f"  Plan Pj:\n{format_structure(struct_j, 2)}"
        )

        # Find optimal switch
        print(f"  Searching for optimal switch...")
        d_star_i, d_star_j = find_optimal_switch(
            query_num, hints_i, hints_j, classification, di, dj
        )

        if d_star_i is None:
            print(f"  No crossover found — Pi remains better throughout range")
            result_block += (
                f"  Optimal Switch: NOT FOUND\n"
                f"  Pi remains better throughout the entire data range.\n"
                f"  The optimizer should never have switched to Pj.\n"
            )
        else:
            print(f"\n  Optimal switch found: {d_star_i} → {d_star_j}")
            print(f"  Validating...")

            rt_pi_qi, rt_pj_qj, rt_pi_qj, rt_pj_qi = validate(
                query_num, hints_i, hints_j, d_star_i, d_star_j
            )

            # Check validity
            pi_better_before = rt_pi_qi <= rt_pj_qi
            pj_better_after  = rt_pj_qj <= rt_pi_qj
            valid = pi_better_before and pj_better_after

            print(f"\n  Pi better before: {pi_better_before} ({rt_pi_qi:.1f} vs {rt_pj_qi:.1f})")
            print(f"  Pj better after:  {pj_better_after} ({rt_pj_qj:.1f} vs {rt_pi_qj:.1f})")
            print(f"  Valid optimal switch: {'YES ' if valid else 'NO  (boundary case)'}")

            result_block += (
                f"  Optimal Switch: {d_star_i} → {d_star_j}\n"
                f"  (Optimizer switched at {di} → {dj})\n\n"
                f"  Execution Times at Optimal Switch:\n"
                f"    RT(Pi, d*i={d_star_i}) = {rt_pi_qi:.2f} ms\n"
                f"    RT(Pj, d*j={d_star_j}) = {rt_pj_qj:.2f} ms\n"
                f"    RT(Pi, d*j={d_star_j}) = {rt_pi_qj:.2f} ms  [forced]\n"
                f"    RT(Pj, d*i={d_star_i}) = {rt_pj_qi:.2f} ms  [forced]\n\n"
                f"  Validation:\n"
                f"    Pi better at d*i: RT(Pi,d*i)={rt_pi_qi:.2f} <= RT(Pj,d*i)={rt_pj_qi:.2f} → {pi_better_before}\n"
                f"    Pj better at d*j: RT(Pj,d*j)={rt_pj_qj:.2f} <= RT(Pi,d*j)={rt_pi_qj:.2f} → {pj_better_after}\n"
                f"  Optimal Switch Valid: {'YES' if valid else 'NO (boundary case)'}\n"
            )

        results_lines.append(result_block)
        print()

    # Save results
    output_path = "/Users/manasvigampa/projects/postgres-query-optimizer-analyzer/optimizer-analysis/02-plan-switch-detection/results.txt"
    with open(output_path, "w") as f:
        f.write("\n".join(results_lines))
    print(f"\nResults saved to results.txt ")

    cursor.close()
    conn.close()

if __name__ == "__main__":
    main()