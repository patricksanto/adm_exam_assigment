import duckdb
import os
import pandas as pd

# Load the CSV file into a Pandas DataFrame
df = pd.read_csv('../raw/arrival_times.csv')


db_path = os.path.abspath('../bus.duckdb')
print('Loading into:', db_path)


# Connect to the DuckDB database
con = duckdb.connect(db_path)

# Drop the table if it already exists
con.execute("DROP TABLE IF EXISTS arrival_times")

# Load the DataFrame into a DuckDB table
con.execute("CREATE TABLE arrival_times AS SELECT * FROM df")

# Close the connection
con.close()