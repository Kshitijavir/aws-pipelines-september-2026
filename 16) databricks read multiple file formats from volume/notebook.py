# Databricks notebook source
# Read multiple file formats from a Unity Catalog Volume.
#
# This notebook has THREE cells. The "# COMMAND ----------" lines mark where one
# cell ends and the next begins.
#
#   CELL 1 -> %pip install openpyxl
#   CELL 2 -> %restart_python
#   CELL 3 -> everything else (imports, path, list files, the loop)
#
# Paste them into Databricks in that order. Cell 1 must be run before Cell 3,
# because Cell 3 needs openpyxl to read the .xlsx file.

# COMMAND ----------

# ==========================================================
# CELL 1 - run this FIRST
# Installs openpyxl, the library used to read .xlsx files.
# ==========================================================

%pip install openpyxl

# COMMAND ----------

# ==========================================================
# CELL 2 - run this SECOND
# Restarts Python so the openpyxl installed in Cell 1 is
# actually visible to the notebook.
# ==========================================================

%restart_python

# COMMAND ----------

# ==========================================================
# CELL 3 - run this LAST
# Imports + Volume path + list files + the processing loop.
# This is the only cell that does the actual work.
# ==========================================================

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
