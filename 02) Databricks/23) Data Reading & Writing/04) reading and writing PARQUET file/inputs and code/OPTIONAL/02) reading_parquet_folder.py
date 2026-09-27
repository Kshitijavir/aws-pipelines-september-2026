# ============================================================
# PIPELINE : Databricks Volume -> PySpark -> DataFrame
# INPUT    : /Volumes/workspace/default/parquet_volume/input/employees_parquet/          (folder)
#            /Volumes/workspace/default/parquet_volume/input/employees_partitioned/      (partitions)
# PURPOSE  : Parquet has no delimiters, but it DOES have one real
#            variation - reading a FOLDER of part files, with or without
#            partitioning. This script covers every practical case.
# ============================================================
from pyspark.sql import SparkSession
from pyspark.sql.functions import col

# Create Spark Session
spark = SparkSession.builder.appName("PARQUET Folder Read Practice").getOrCreate()

# ------------------------------------------------------------
#  >>> YOUR CODE GOES HERE <<<
# ------------------------------------------------------------

############################################################
# CASE 1 - the folder (part files written by one job)
############################################################
# employees_parquet/
# ├── part-00000-....snappy.parquet
# ├── part-00001-....snappy.parquet
# └── _SUCCESS
one = spark.read.parquet("/Volumes/workspace/default/parquet_volume/input/employees_parquet/")
one.printSchema()
one.show()

############################################################
# CASE 2 - a single part file, by name
############################################################
single = spark.read.parquet(
    "/Volumes/workspace/default/parquet_volume/input/employees_parquet/part-00000-....snappy.parquet"
)
single.show()

############################################################
# CASE 3 - a glob pattern
############################################################
globbed = spark.read.parquet(
    "/Volumes/workspace/default/parquet_volume/input/employees_parquet/*.parquet"
)
globbed.show()

############################################################
# CASE 4 - PARTITIONED data, reading the WHOLE dataset
############################################################
partitions = spark.read.parquet(
    "/Volumes/workspace/default/parquet_volume/input/employees_partitioned/"
)
partitions.printSchema()   # department IS auto-detected from the folder names
partitions.show()

############################################################
# CASE 5 - PARTITIONED data, reading ONE partition (partition pruning)
############################################################
# basePath tells Spark the partition root, so that when you point at a
# SUBFOLDER it still restores the department column and can do pruning.
it_only = spark.read \
    .option("basePath", "/Volumes/workspace/default/parquet_volume/input/employees_partitioned/") \
    .parquet("/Volumes/workspace/default/parquet_volume/input/employees_partitioned/department=IT/")

it_only.printSchema()   # department IS a column here
it_only.show()

############################################################
# CASE 6 - SCHEMA EVOLUTION (files written at different times)
############################################################
evolved = spark.read \
    .option("mergeSchema", "true") \
    .parquet("/Volumes/workspace/default/parquet_volume/input/employees_parquet/")

evolved.printSchema()

# ============================================================
# NOTES
# ============================================================
# 1. ⭐ WHY THERE IS NO "employees.parquet" SINGLE FILE
#
#    Spark writes ONE PART FILE PER TASK. So 1 job can easily produce
#    200 part files. A "Parquet dataset" is really a DIRECTORY, and the
#    normal thing to read is the directory, not a file name.
#
#    This is the one genuine difference from the CSV/JSON/TXT topics:
#
#       there, the FORMAT varied (delimiter, shape, layout)
#       here,  the LAYOUT varies (folder, part files, partitions)
#
# 2. THE _SUCCESS FILE. Spark writes an EMPTY "_SUCCESS" marker when a
#       write finishes cleanly. It is a flag, not data - Spark's Parquet
#       reader ignores it. If it is MISSING, the write was interrupted and
#       the folder may be incomplete. Worth checking in real pipelines.
#
# 3. PARTITION COLUMNS AND printSchema() - the classic bug
#
#       Reading the ROOT  (.../employees_partitioned/)
#           -> Spark sees the "department=IT" FOLDER NAMES and adds
#              department as a real column. Nothing extra needed. (CASE 4)
#
#       Reading a SUBFOLDER  (.../employees_partitioned/department=IT/)
#       WITH .option("basePath", root)
#           -> Spark knows the partition root, so it RESTORES the
#              department column. (CASE 5)
#
#       Reading a SUBFOLDER WITHOUT basePath
#           -> "department=IT" is not a legal data path segment, so Spark
#              strips it, keeps only the parquet files, and the partition
#              column DISAPPEARS from the schema.
#
#    That last case is a very common real-world bug: "my partition column
#    vanished". The fix is always to pass basePath, or just read the root.
#
# 4. PARTITION PRUNING - the whole point of partitioning.
#       CASE 5 reads ONLY the department=IT folder. If the dataset holds
#       10 departments, Spark reads roughly 1/10th of the data.
#       Check it with .explain() - look for "PartitionFilters".
#
# 5. mergeSchema vs default MERGE behaviour.
#       Default: Spark uses the schema of ONE part file (usually the first
#       it finds) and IGNORES extra columns in the others - silently
#       dropping data.
#       mergeSchema=true: unions them, filling missing values with null.
#       For production, prefer managing this with a table format
#       (Iceberg / Delta / Hive) rather than relying on mergeSchema.
#
# 6. What you CANNOT do with Parquet:
#           - open it in Notepad (binary, unreadable)
#           - pass sep / header / quote / multiLine  (no text formatting)
#    To LOOK at a Parquet file outside Spark use: Athena, parquet-tools,
#    or a notebook with pyarrow/pandas.
#
# 7. Parquet is OPTIMISED FOR READING the full dataset and a FEW columns.
#       It is NOT good for: single-row lookups, frequent small updates,
#       or appending one row at a time. Those need Iceberg / Delta.
