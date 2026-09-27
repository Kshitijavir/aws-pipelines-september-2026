# ============================================================
# PIPELINE : Databricks Volume -> PySpark -> DataFrame -> Databricks Volume
# INPUT    : 01) table.parquet
# OUTPUT   : /Volumes/workspace/default/parquet_volume/output/table_partitioned/   (many folders)
# PURPOSE  : WRITE partitioned Parquet - one FOLDER per column value.
#            This is the write-side mirror of reading a partitioned dataset
#            with basePath / partition pruning.
# ============================================================
from pyspark.sql import SparkSession
from pyspark.sql.functions import col

# Create Spark Session
spark = SparkSession.builder.appName("PARQUET Folder Write Practice").getOrCreate()

from pyspark.sql.functions import col, when

# ------------------------------------------------------------
#  >>> YOUR CODE GOES HERE <<<
# ------------------------------------------------------------

df = spark.read \
    .parquet("/Volumes/workspace/default/parquet_volume/input/table.parquet")

df.printSchema()
df.show(truncate=False)

# ------------------------------------------------------------
# WRITE AS PARTITIONED PARQUET - one folder PER VALUE
# ------------------------------------------------------------
# partitionBy("two") turns the 3 distinct values of "two" into 3 folders:
#
#           table_partitioned/
#           ├── two=bar/part-00000-....snappy.parquet
#           ├── two=baz/part-00000-....snappy.parquet
#           ├── two=foo/part-00000-....snappy.parquet
#           └── _SUCCESS
#
# 🎯 The column name and value are encoded IN the folder name - that is how
#    a reader can skip whole folders later (partition pruning).
df.write \
    .mode("overwrite") \
    .partitionBy("two") \
    .parquet("/Volumes/workspace/default/parquet_volume/output/table_partitioned_mode_overwrite/")

# ------------------------------------------------------------
# SAME THING WITH A DERIVED COLUMN - this is how year/month/date
# partitioning is normally done in real pipelines.
# ------------------------------------------------------------
df_typed = df.withColumn(
    "three_label",
    when(col("three").isNull(), "unknown")
    .otherwise(col("three").cast("string"))
)

df_typed.write \
    .mode("overwrite") \
    .partitionBy("three_label") \
    .parquet("/Volumes/workspace/default/parquet_volume/output/table_partitioned_bool_mode_overwrite/")

# ============================================================
# NOTES
# ============================================================
# 1. 🔁 THE SYMMETRY WITH READING
#
#       WRITE  .partitionBy("two")                       -> makes the "two=bar/"
#                                                           folder structure
#       READ   .parquet(".../table_partitioned/")         -> "two" comes back
#                                                           as a real column
#       READ   .option("basePath", root).parquet(".../two=bar/")
#                                                         -> restores "two"
#
#    So a partition is really just "a column whose value lives in the path".
#
# 2. ⚠️⚠️ THE PARTITION COLUMN MOVES FROM INSIDE THE FILE TO THE FOLDER NAME.
#    That means the column is NO LONGER STORED IN THE PARQUET FILE ITSELF.
#    If you then read a SINGLE partition folder WITHOUT basePath, the column
#    disappears from the schema - the exact trap covered on the reading side.
#
# 3. ⚠️⚠️ TOO MANY PARTITIONS IS WORSE THAN NONE - THE #1 MISTAKE.
#
#       partitionBy("employee_id")   -> 10,000 folders, each holding 1 tiny file
#                                     -> 10,000 storage listing operations
#                                     -> driver memory pressure, slow, expensive
#                                     -> the small-files problem on steroids
#
#    ✅ GOOD partition columns: LOW cardinality (a few to a few thousand):
#           department, country, status, year, month, event_date
#    ❌ BAD partition columns: HIGH cardinality (unique-ish):
#           employee_id, order_id, timestamp-to-the-second
#
#    📌 Rule of thumb: if the column has thousands of distinct values per day,
#       do NOT partition on it. A file size around 100 MB - 1 GB per partition
#       folder is a sensible target.
#
# 4. ⭐ WHAT PARTITIONING BUYS YOU
#
#       without partitions:  filter department='IT'
#                            -> read ALL data, then discard 90% of it
#
#       with partitions:     filter department='IT'
#                            -> read ONLY department=IT/
#                            -> ~10x less data on a 10-partition dataset
#
#    ⚠️ The filter must be on the PARTITION COLUMN for this to work. A filter
#    on a normal column inside the file cannot skip folders - it only skips
#    row groups (that is predicate pushdown, a different trick).
#
# 5. ⭐ PARTITIONING + THE WRITE MODES INTERACT BADLY
#
#       overwrite  -> replaces the WHOLE dataset (all partitions)  ✅ safe, predictable
#       append     -> adds files, and can leave DUPLICATE rows inside the
#                     SAME partition folder with no way to tell them apart  ⚠️
#
#    🎤 So for a re-runnable Databricks job, .mode("overwrite") is the safe default.
#    For real incremental refinement you need a table format (Iceberg/Delta)
#    that tracks which files are current.
#
# 6. 💡 HANDLING NULLS IN A PARTITION COLUMN
#    A null value becomes the literal folder name  two=__HIVE_DEFAULT_PARTITION__
#    which is ugly and awkward downstream. That is why the second write above
#    maps null to a readable "unknown" first - a small habit that saves a lot
#    of confusion later.
#
# 7. WHAT YOU CANNOT DO WITH PARQUET (and why Iceberg/Delta exist)
#           ❌ UPDATE / DELETE a single row
#           ❌ MERGE / UPSERT
#           ❌ time travel ("show me yesterday's version")
#           ❌ safe concurrent writers
#    Parquet is just files in folders. Iceberg and Delta ADD a metadata /
#    transaction log on top of Parquet to get those features - they do not
#    replace the format.
#
# 8. 📂 Output is a FOLDER PER PARTITION, each containing its own part files.
