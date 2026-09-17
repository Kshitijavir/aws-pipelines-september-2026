# Databricks notebook source
# Read multiple file formats from a Unity Catalog Volume.
#
# This notebook has exactly THREE cells, labelled CELL 1, CELL 2 and CELL 3
# below. The separator lines between them are how Databricks marks a cell
# boundary, so each labelled block is exactly one cell in the notebook.
#
#   CELL 1 -> %pip install openpyxl
#   CELL 2 -> %restart_python
#   CELL 3 -> everything else (imports, path, list files, the loop)
#
# Run them in that order. Cell 1 must run before Cell 3, because Cell 3 needs
# openpyxl to read the .xlsx file.
#
# NOTE ON THE "# MAGIC" PREFIX
# The %pip and %restart_python lines below are written as "# MAGIC %pip ...".
# That is NOT commenting them out. Databricks strips the "# MAGIC" when it
# reads this file and runs the command for real. It is the format Databricks
# itself uses to store magics in a notebook source file, and it is the only
# way to write a magic in a .py file without it being a Python syntax error.

# ==========================================================
# CELL 1 - run this FIRST
# Installs openpyxl, the library used to read .xlsx files.
# ==========================================================

# MAGIC %pip install openpyxl

# COMMAND ----------

# ==========================================================
# CELL 2 - run this SECOND
# Restarts Python so the openpyxl installed in Cell 1 is
# actually visible to the notebook.
# ==========================================================

# MAGIC %restart_python

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
