# Databricks notebook source
#
# PURPOSE
#   Read every file in a Unity Catalog Volume, whatever format it is in.
#
#   .csv / .txt  ->  Spark CSV reader
#   .json        ->  Spark JSON reader
#   .xlsx        ->  pandas + openpyxl, then converted back to a Spark DataFrame
#
# HOW TO USE
#   Three cells. Run them top to bottom, in order.
#   Add the files you want to read to the volume, then run Cell 3.

# ==================================================================
# CELL 1 - run first
# ==================================================================
# Spark cannot read Excel files, so openpyxl has to be installed.
# "%pip" is a Databricks magic. Inside a .py file magics are written with the
# "# MAGIC" prefix, which is how Databricks stores them on disk.

# MAGIC %pip install openpyxl

# COMMAND ----------
# CELL 2 - run second
# A notebook-scoped pip install only takes effect after Python restarts.

# MAGIC %restart_python

# COMMAND ----------
# CELL 3 - run last: read every file in the volume

import pandas as pd

# The Unity Catalog Volume that holds the files.
path = "/Volumes/lambda-to-databricks/default/structured-2026"

# List the contents of the volume. Each entry has .name, .path and .size.
files = dbutils.fs.ls(path)

for file in files:

    # dbutils returns paths as "dbfs:/Volumes/...". pandas cannot open a
    # "dbfs:/..." URI, so drop the prefix and keep the plain /Volumes/ path.
    # Spark understands both forms, so this line is safe for every branch.
    file_path = file.path.replace("dbfs:", "")

    # Compare against the lowercased name so ".CSV" and ".csv" both match.
    file_name = file.name.lower()

    print("=" * 60)
    print(f"Reading: {file.name}")
    print("=" * 60)

    # CSV - first row holds the column names, Spark works out the data types.
    if file_name.endswith(".csv"):

        df = spark.read.csv(
            file_path,
            header=True,
            inferSchema=True
        )

    # JSON - multiLine is needed when one file holds a single nested JSON
    # document, rather than one JSON object per line.
    elif file_name.endswith(".json"):

        df = (
            spark.read
            .option("multiLine", True)
            .json(file_path)
        )

    # TXT - same shape as CSV, so the CSV reader handles it.
    elif file_name.endswith(".txt"):

        df = spark.read.csv(
            file_path,
            header=True,
            inferSchema=True
        )

    # XLSX - Spark has no Excel reader. pandas reads the sheet with openpyxl,
    # then spark.createDataFrame turns that pandas DataFrame back into Spark
    # so the rest of the notebook can treat every file the same way.
    elif file_name.endswith(".xlsx"):

        pandas_df = pd.read_excel(
            file_path,
            engine="openpyxl"
        )

        df = spark.createDataFrame(pandas_df)

    # Anything else: say so and move to the next file, do not fail the run.
    else:

        print(f"Skipping: {file.name}")
        continue

    # Same two lines for every format, because every branch produced a Spark
    # DataFrame. printSchema shows the columns and types, display shows rows.
    df.printSchema()
    display(df)
