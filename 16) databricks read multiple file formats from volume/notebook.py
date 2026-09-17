# Databricks notebook source
# Read multiple file formats from a Unity Catalog Volume.
#
# THREE cells total. Cell boundaries are marked by the standard COMMAND
# separator lines that Databricks uses when it exports a notebook as source.
# Import this file into Databricks as notebook source, or paste the cells in order.
#
# The magics (%pip, %restart_python) are written as "# MAGIC" comments, which is
# how Databricks stores them on disk. They are comments here so the file is also
# valid Python and no IDE flags it as a syntax error.

# MAGIC %pip install openpyxl

# COMMAND ----------

# Cell 2 - Restart Python so the newly installed package is visible
# MAGIC %restart_python

# COMMAND ----------

# Cell 3 - Imports, input path, list files, and the main processing loop
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
