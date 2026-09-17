# Databricks notebook source
#
# ================================================================
# PURPOSE
# ================================================================
# This notebook reads files from a Unity Catalog Volume.
#
# Supported file formats:
#   1. CSV   -> Spark CSV reader
#   2. JSON  -> Spark JSON reader
#   3. TXT   -> Spark CSV reader
#   4. XLSX  -> Pandas + OpenPyXL
#
# The notebook automatically identifies the file type based on
# the file extension and reads the file using the appropriate reader.
#
#
# ================================================================
# HOW TO USE
# ================================================================
# 1. Run Cell 1 to install OpenPyXL.
# 2. Run Cell 2 to restart Python.
# 3. Add your files to the Volume path mentioned in Cell 3.
# 4. Run Cell 3.
#
# The notebook will:
#   - Find all files in the Volume
#   - Identify the file format
#   - Read the file
#   - Convert the result to a Spark DataFrame
#   - Print the schema
#   - Display the data
#
# ================================================================


# COMMAND ----------
# CELL 1 - INSTALL REQUIRED LIBRARY
# ================================================================
# OpenPyXL is required to read Excel (.xlsx) files.

# MAGIC =    %pip install openpyxl


# COMMAND ----------
# CELL 2 - RESTART PYTHON
# ================================================================
# Restart Python so that the newly installed OpenPyXL library
# is available in the notebook.

# MAGIC =    %restart_python


# COMMAND ----------
# CELL 3 - READ FILES
# ================================================================

import pandas as pd

path = "/Volumes/lambda-to-databricks/default/structured-2026"

files = dbutils.fs.ls(path)

for file in files:

    # File path used for reading the file.
    file_path = file.path.replace("dbfs:", "")

    # Convert file name to lowercase so that .CSV, .Csv and .csv
    # are treated the same way.
    file_name = file.name.lower()

    print("=" * 60)
    print(f"Reading: {file.name}")
    print("=" * 60)


    # ============================================================
    # CSV FILE
    # ============================================================
    # Example:
    # employee.csv

    if file_name.endswith(".csv"):

        df = spark.read.csv(
            file_path,
            header=True,
            inferSchema=True
        )


    # ============================================================
    # JSON FILE
    # ============================================================
    # Example:
    # employee.json

    elif file_name.endswith(".json"):

        df = (
            spark.read
            .option("multiLine", True)
            .json(file_path)
        )


    # ============================================================
    # TXT FILE
    # ============================================================
    # TXT files containing comma-separated data can be read
    # using the Spark CSV reader.

    elif file_name.endswith(".txt"):

        df = spark.read.csv(
            file_path,
            header=True,
            inferSchema=True
        )


    # ============================================================
    # EXCEL FILE
    # ============================================================
    # Example:
    # employee.xlsx
    #
    # Excel files are first read using Pandas and OpenPyXL.
    # Then the Pandas DataFrame is converted into a Spark DataFrame.

    elif file_name.endswith(".xlsx"):

        pandas_df = pd.read_excel(
            file_path,
            engine="openpyxl"
        )

        df = spark.createDataFrame(pandas_df)


    # ============================================================
    # UNSUPPORTED FILE
    # ============================================================
    # If the file is not CSV, JSON, TXT or XLSX,
    # skip the file and continue with the next one.

    else:

        print(f"Skipping unsupported file: {file.name}")
        continue


    # ============================================================
    # STEP 4 - DISPLAY RESULT
    # ============================================================
    # All supported formats are converted into a Spark DataFrame.
    # Therefore, the same commands can be used for every file.

    df.printSchema()
    display(df)