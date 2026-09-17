# Databricks notebook — read multiple file formats from a Unity Catalog Volume.
#
# This notebook has THREE cells.
# Each "# COMMAND ----------" block below is one cell.
# Paste them into Databricks in order, or import this file as notebook source.

# COMMAND ----------

# Cell 1 — Install OpenPyXL (needed for the Excel branch)
%pip install openpyxl

# COMMAND ----------

# Cell 2 — Restart Python so the newly installed package is visible
%restart_python

# COMMAND ----------

# Cell 3 — Imports, input path, list files, and the main processing loop
import pandas as pd

path = "/Volumes/lambda-to-databricks/default/structured-2026"

files = dbutils.fs.ls(path)

for file in files:

    file_path = file.path.replace("dbfs:", "")
    file_name = file.name.lower()

    print("=" * 60)
    print(f"Reading: {file.name}")
    print("=" * 60)

    # CSV
    if file_name.endswith(".csv"):

        df = spark.read.csv(
            file_path,
            header=True,
            inferSchema=True
        )

    # JSON
    elif file_name.endswith(".json"):

        df = (
            spark.read
            .option("multiLine", True)
            .json(file_path)
        )

    # TXT
    elif file_name.endswith(".txt"):

        df = spark.read.csv(
            file_path,
            header=True,
            inferSchema=True
        )

    # Excel
    elif file_name.endswith(".xlsx"):

        pandas_df = pd.read_excel(
            file_path,
            engine="openpyxl"
        )

        df = spark.createDataFrame(pandas_df)

    # Unsupported file
    else:

        print(f"Skipping: {file.name}")
        continue

    df.printSchema()
    display(df)
