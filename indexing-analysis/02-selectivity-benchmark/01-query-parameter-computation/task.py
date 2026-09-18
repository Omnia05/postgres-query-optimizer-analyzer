import psycopg2
import sys
import os

# ------------------------------------------------------------
# Database Connection
# ------------------------------------------------------------

def connect_to_db():
    """
    Establish connection to PostgreSQL database.
    """
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
# Helper Functions
# ------------------------------------------------------------

def get_total_rows(cursor):
    """
    Return total number of rows in lineitem table.
    """
    cursor.execute("SELECT COUNT(*) FROM lineitem;")
    return cursor.fetchone()[0]


def get_column_type(cursor, column_name):
    """
    Get data type of the specified column.
    """
    cursor.execute("""
        SELECT data_type
        FROM information_schema.columns
        WHERE table_name = 'lineitem'
        AND column_name = %s;
    """, (column_name,))
    
    result = cursor.fetchone()
    if result is None:
        print("Invalid column name.")
        sys.exit(1)
    
    return result[0]


def get_threshold_value(cursor, column_name, selectivity):
    """
    Compute threshold X using percentile_disc.
    """
    query = f"""
        SELECT percentile_disc(%s)
        WITHIN GROUP (ORDER BY {column_name})
        FROM lineitem;
    """
    cursor.execute(query, (selectivity,))
    return cursor.fetchone()[0]


def verify_selectivity(cursor, column_name, threshold, total_rows):
    """
    Verify actual selectivity achieved.
    """
    query = f"""
        SELECT COUNT(*) FROM lineitem
        WHERE {column_name} <= %s;
    """
    cursor.execute(query, (threshold,))
    count = cursor.fetchone()[0]
    
    return count / total_rows


# ------------------------------------------------------------
# Main Program
# ------------------------------------------------------------

def main():
    if len(sys.argv) != 3:
        print("Usage: python3 task.py <column_name> <selectivity>")
        sys.exit(1)

    column_name = sys.argv[1]
    selectivity = float(sys.argv[2])

    if not (0 < selectivity < 1):
        print("Selectivity must be between 0 and 1.")
        sys.exit(1)

    conn = connect_to_db()
    cursor = conn.cursor()

    queries_executed = 0

    # get total rows
    total_rows = get_total_rows(cursor)
    queries_executed += 1

    # validate column
    col_type = get_column_type(cursor, column_name)
    queries_executed += 1

    supported_types = [
        'integer',
        'numeric',
        'real',
        'double precision',
        'date',
        'character varying',
        'text',
        'character'
    ]

    if col_type not in supported_types:
        print("Unsupported column type.")
        sys.exit(1)

    # 3️compute threshold
    threshold = get_threshold_value(cursor, column_name, selectivity)
    queries_executed += 1

    # verify actual selectivity
    actual_selectivity = verify_selectivity(
        cursor,
        column_name,
        threshold,
        total_rows
    )
    queries_executed += 1

    cursor.close()
    conn.close()

    # ------------------------------------------------------------
    # Output
    # ------------------------------------------------------------

    print(f"QUERY_PARAMETER: {threshold}")
    print(f"QUERIES_EXECUTED: {queries_executed}")
    print(f"ACTUAL_SELECTIVITY: {actual_selectivity:.4f}")


if __name__ == "__main__":
    main()
