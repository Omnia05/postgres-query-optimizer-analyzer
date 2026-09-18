import json
import matplotlib.pyplot as plt

# ------------------------------------------------------------
# Load JSON Data
# ------------------------------------------------------------

def load_scenario(filename):
    with open(filename, "r") as f:
        data = json.load(f)

    selectivities = []
    execution_times = []

    for entry in data:
        selectivities.append(entry["actual_selectivity"])
        execution_times.append(entry["execution_time_ms"])

    return selectivities, execution_times


# ------------------------------------------------------------
# Main Plotting Function
# ------------------------------------------------------------

def main():

    base_path = "query_plans/"

    scenarios = {
        "Without Index": "without_index.json",
        "With Index": "with_index.json",
        "No Sequential Scan": "no_sequential_scan.json",
        "Clustered Index": "clustered_index.json",
        "Select Column Only": "select_column.json"
    }

    plt.figure(figsize=(10, 6))

    for label, filename in scenarios.items():
        x, y = load_scenario(base_path + filename)
        plt.plot(x, y, marker='o', label=label)

    plt.xlabel("Actual Selectivity")
    plt.ylabel("Execution Time (ms)")
    plt.title("Query Performance vs Selectivity (l_quantity)")
    plt.legend()
    plt.grid(True)
    plt.savefig("performance_plot.png", dpi=300)
    plt.show()


if __name__ == "__main__":
    main()
