from google.cloud import bigquery
import os

# Set the path to your service account JSON file
# Replace "your_credentials.json" with your actual file name
os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = "your_credentials.json"

# Initialize the BigQuery client
client = bigquery.Client()

# List of tables in the thelook_ecommerce dataset
tables = ["events", "order_items", "orders", "products", "users", "distribution_centers", "inventory_items"]

# Loop through tables and download data
for table in tables:
    query = f"SELECT * FROM `bigquery-public-data.thelook_ecommerce.{table}`"
    df = client.query(query).to_dataframe()  # Execute query and convert to DataFrame

    # Save each table to a CSV file
    df.to_csv(f"{table}.csv", index=False)
    print(f"Table {table} saved as {table}.csv")
