import json
import sys

def extract_json(content):
    """Helper to remove psql formatting: header lines, trailing +, (1 row)"""
    lines = content.split('\n')
    json_lines = []
    for line in lines:
        if 'QUERY PLAN' in line or '---' in line or '(1 row)' in line:
            continue
        line = line.rstrip()
        if line.endswith('+'):
            line = line[:-1]
        json_lines.append(line)
    return '\n'.join(json_lines).strip()


def extract_physical_operator_tree(plan):
    """
    Extract the physical operator tree from a PostgreSQL compile-time query execution plan.
    Strips out all costs, row estimates, parameter values etc.
    """
    if plan is None:
        return None

    structure = {
        "Node Type": plan.get("Node Type"),
    }

    # Keep specific structural identifiers
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

    # Recursively process child plans
    if "Plans" in plan:
        structure["Plans"] = [extract_physical_operator_tree(child) for child in plan["Plans"]]

    return structure


def compare_plans(plan1, plan2):
    """
    Compare two PostgreSQL query execution plans for structural equivalence.
    """
    struct1 = extract_physical_operator_tree(plan1)
    struct2 = extract_physical_operator_tree(plan2)

    return struct1 == struct2


if __name__ == "__main__":
    # Determine filenames either from args or default to task requirements
    file1 = sys.argv[1] if len(sys.argv) > 1 else "plan1.json"
    file2 = sys.argv[2] if len(sys.argv) > 2 else "plan2.json"

    with open(file1, 'r') as f:
        content1 = f.read()
    with open(file2, 'r') as f:
        content2 = f.read()

    # Clean the psql formatting and parse to JSON
    json1 = json.loads(extract_json(content1))
    json2 = json.loads(extract_json(content2))

    # Extract the actual plan root
    actual_plan1 = json1[0]["Plan"]
    actual_plan2 = json2[0]["Plan"]

    # Compare and output exact required strings
    if compare_plans(actual_plan1, actual_plan2):
        print("YES: Both plans are structurally identical")
    else:
        print("NO: Plans are structurally different")