# ============================================================
# PIPELINE : Databricks Volume -> PySpark -> DataFrame
# INPUT    : 01) table.parquet      (BINARY parquet - 3 rows, 6 columns)
#            upload it to  /Volumes/workspace/default/parquet_volume/input/table.parquet
# PURPOSE  : The base case - read Parquet with NO options at all.
# ============================================================
from pyspark.sql import SparkSession
from pyspark.sql.functions import col

# Create Spark Session
spark = SparkSession.builder.appName("PARQUET Read Practice").getOrCreate()

# ------------------------------------------------------------
#  >>> YOUR CODE GOES HERE <<<
# ------------------------------------------------------------

df = spark.read \
    .parquet("/Volumes/workspace/default/parquet_volume/input/table.parquet")

df.printSchema()

df.show(truncate=False)

# ============================================================
# NOTES
# ============================================================
# 1. THIS IS THE SIMPLEST READER OF ALL.
#
#           spark.read.parquet(path)
#
#    NO sep, NO header, NO inferSchema, NO multiLine, NO quoting.
#    Parquet carries its own schema and its own types INSIDE the file,
#    so there is nothing for you to declare and nothing for Spark to guess.
#
#    Compare the same intent across the four topics:
#
#       spark.read.option("header", "true")
#                 .option("inferSchema", "true")
#                 .csv(path)                     <- CSV, options needed
#
#       spark.read.json(path)                  <- JSON, already typed
#
#       spark.read.text(path)                  <- TXT, 1 column "value"
#
#       spark.read.parquet(path)               <- PARQUET, nothing needed
#
# 2. A SINGLE FILE *AND* A FOLDER BOTH WORK.
#
#       ONE file   (what we have here):
#           spark.read.parquet("/Volumes/workspace/default/parquet_volume/input/table.parquet")
#
#       A FOLDER   (what Spark itself writes for big data):
#           spark.read.parquet("/Volumes/workspace/default/parquet_volume/input/employees_parquet/")
#
#           employees_parquet/
#           ├── part-00000-....snappy.parquet
#           ├── part-00001-....snappy.parquet
#           └── _SUCCESS
#
#    Spark writes ONE PART FILE PER TASK, so a real dataset is almost always
#    a DIRECTORY. Pointing at the directory reads every part file as ONE
#    DataFrame. (See 02) reading_parquet_folder.py for the folder cases.)
#
#    01) table.parquet is the simple SINGLE-FILE case - typical of a small
#    file exported from pandas / pyarrow, which is exactly how this one was
#    made (parquet-cpp-arrow 10.0.1).

# 3. THE SCHEMA COMES BACK EXACTLY ON PURPOSE.
#       Parquet stores the schema in the file FOOTER, so printSchema()
#       returns the SAME types the writer used - no inference, no
#       integer-vs-long surprises, no "everything is a string".
#
#    What Spark actually prints for 01) table.parquet:
#
#           root
#            |-- one: double
#            |-- two: string
#            |-- three: boolean
#            |-- four: timestamp
#            |-- five: timestamp
#            |-- __index_level_0__: string
#
#    Look at what Parquet handed over that CSV could NEVER have given us:
#
#      - one    DOUBLE     -> holds a real NaN (not the text "nan")
#      - three  BOOLEAN    -> True / False / null in one typed column
#      - four   TIMESTAMP  -> a real date-time type, not a string
#      - five   TIMESTAMP
#
#    In CSV all of these arrive as TEXT and YOU must cast them - and a
#    timestamp would need a date format decided by you.
#
#    __index_level_0__ is NOT real data: it is the pandas DataFrame INDEX
#    that leaked into the file when it was written. You will see this A LOT
#    on files exported from pandas - so just be aware it is there.
#    (Removing it would be a transformation, not part of reading.)
#
# 4. WHY PARQUET IS CHEAP TO READ - PART 1: COLUMNAR STORAGE.
#       Parquet stores data COLUMN by COLUMN, not row by row. So if a later
#       step needs only a few of the 6 columns, Spark can skip reading the
#       other column chunks from storage completely.
#       With CSV, Spark must read whole lines and then throw parts away.
#
#    📖 Explained in pipeline details.md -> section 7.
#
# 5. WHY PARQUET IS CHEAP TO READ - PART 2: ROW-GROUP STATISTICS.
#       Parquet rows are grouped into ROW GROUPS (01) table.parquet has just 1),
#       and every row group keeps MIN/MAX statistics per column. Those stats
#       let a filter skip whole row groups WITHOUT reading them at all.
#       With CSV, every byte must be read and every row tested.
#
#    📖 Explained in pipeline details.md -> section 8.
#
#    You can even see those stats yourself, without Spark:
#           python -c "import pyarrow.parquet as pq; \
#                      print(pq.ParquetFile('01) table.parquet').metadata)"
#
# 6. THE READING SIDE HAS NO "FORMATS FAMILY".
#       CSV has comma / pipe / tab / semicolon / quoted / no-header.
#       TXT has plain / delimited / fixed-width.
#       Parquet has NONE of that - it is one binary layout, always.
#       The only real variation is: ONE file vs a FOLDER, and whether the
#       folder is PARTITIONED. Both are covered in this topic's scripts.
#
# 7. Common extra options (all optional):
#           .option("mergeSchema", "true")        read mixed schemas together
#           .option("basePath", "...")            restore partition columns
#           .option("pathGlobFilter", "*.parquet")
#           .option("recursiveFileLookup", "true")
#           .option("spark.sql.parquet.filterPushdown", "false")  disable 5.
#
# 8. The typed built-in reader is the same thing:
#           spark.read.format("parquet")
#    or, for a catalog table:
#           spark.table("db.employees")
