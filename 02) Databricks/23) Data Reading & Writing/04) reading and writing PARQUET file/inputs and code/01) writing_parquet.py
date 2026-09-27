# ============================================================
# PIPELINE : Databricks Volume -> PySpark -> DataFrame -> Databricks Volume
# INPUT    : 01) table.parquet
# OUTPUT   : /Volumes/workspace/default/parquet_volume/output/table_*    (a FOLDER per write)
# PURPOSE  : The base case - WRITE a DataFrame out as PARQUET, and see all
#            FOUR write modes: append / overwrite / ignore / error.
# ============================================================
from pyspark.sql import SparkSession
from pyspark.sql.functions import col

# Create Spark Session
spark = SparkSession.builder.appName("PARQUET Write Practice").getOrCreate()

from pyspark.sql.functions import col, current_timestamp, upper

# ------------------------------------------------------------
#  >>> YOUR CODE GOES HERE <<<
# ------------------------------------------------------------

# ---------- STEP 1 - READ ----------
df = spark.read \
    .parquet("/Volumes/workspace/default/parquet_volume/input/table.parquet")

df.printSchema()

df.show(truncate=False)

# ---------- STEP 2 - make a VISIBLE CHANGE before writing  ⭐ ----------
# ⚠️ If we wrote `df` unchanged, the output would look EXACTLY like the input
#    and you could never PROVE the write happened.
# ✅ So add columns you can SEE:
#       two_upper -> "foo" becomes "FOO"     (proves the transform ran)
#       load_ts   -> the time this job ran   (proves WHICH run wrote it)
df_new = df \
    .withColumn("two_upper", upper(col("two"))) \
    .withColumn("load_ts", current_timestamp())

df_new.printSchema()   # now 8 columns
df_new.show(truncate=False)

# ------------------------------------------------------------
# STEP 3 - WRITE. Two decisions, exactly like CSV and JSON:
#   1. the MODE   -> what to do if the output path already exists
#   2. the FORMAT -> .parquet() here
# ------------------------------------------------------------
# ⚠️ NOTE: there is NO .option("header", ...) here, and no separator.
#    Parquet carries the column names and the types inside the file itself,
#    so writing needs NOTHING declared - the mirror of reading needing nothing.
#
# ⭐ Each mode writes to its OWN folder, and the folder name ENDS WITH THE
#    MODE NAME - so a glance at the volume tells you which mode produced it.
# ⚠️ They are FOLDERS, so they end with a SLASH. You must NOT write
#    "table_mode_overwrite.parquet".

# 1) OVERWRITE - delete what is already there, then write fresh
df_new.write \
    .mode("overwrite") \
    .parquet("/Volumes/workspace/default/parquet_volume/output/table_mode_overwrite/")

# 2) APPEND - keep what is already there, and ADD these new files
df_new.write \
    .mode("append") \
    .parquet("/Volumes/workspace/default/parquet_volume/output/table_mode_append/")

# 3) IGNORE - if the path EXISTS: do nothing at all.
df_new.write \
    .mode("ignore") \
    .parquet("/Volumes/workspace/default/parquet_volume/output/table_mode_ignore/")

# ------------------------------------------------------------
# STEP 4 - VERIFY: read the output BACK and look at it  ⭐
# ------------------------------------------------------------
print("=" * 60)
print("VERIFYING THE WRITTEN OUTPUT")
print("=" * 60)

check = spark.read.parquet("/Volumes/workspace/default/parquet_volume/output/table_mode_overwrite/")

check.printSchema()
check.show(truncate=False)

# ✅ two_upper and load_ts present  -> the write worked
# ⚠️ missing                        -> you are reading OLD data
# 💡 Parquet keeps the TYPES too, so two_upper comes back as a real string
#    column and load_ts as a real timestamp - not as text.
for m in ["overwrite", "append", "ignore"]:
    n = spark.read.parquet(f"/Volumes/workspace/default/parquet_volume/output/table_mode_{m}/").count()
    print(f"  table_mode_{m}/  ->  {n} rows")

# ------------------------------------------------------------
# OPTIONAL - choose the compression codec explicitly
# (snappy is the default; you can see it in the part-file names)
# ------------------------------------------------------------
df_new.write \
    .mode("overwrite") \
    .option("compression", "gzip") \
    .parquet("/Volumes/workspace/default/parquet_volume/output/table_mode_overwrite_gzip/")

# 4) ERROR - if the path EXISTS: FAIL the job loudly. (this is the default)
#    ⚠️ KEPT LAST: on the SECOND run this kills the job, so nothing after it runs.
print("about to write with mode=error (fails if the path exists)")
df_new.write \
    .mode("error") \
    .parquet("/Volumes/workspace/default/parquet_volume/output/table_mode_error/")

# ============================================================
# NOTES - THE FOUR WRITE MODES
# ============================================================
# 1. ⭐ THE MODE TABLE - the standard interview answer
#
#     mode          path exists?          what happens
#     ----------------------------------------------------------------
#     error         no                    writes
#     (default)     yes                   ❌ FAILS the job
#
#     overwrite     no                    writes
#                   yes                   🗑️ DELETES it, then writes
#
#     append        no                    writes
#                   yes                   ➕ keeps old + adds new files
#
#     ignore        no                    writes
#                   yes                   😶 does nothing, job still succeeds
#
#    Think:
#       overwrite → "replace everything"
#       append    → "add to it"
#       ignore    → "if it's there, leave me alone"
#       error     → "STOP, something is wrong"
#
# 2. ⚠️ "error" is the DEFAULT. So this FAILS on the second run:
#
#           df.write.parquet(path)          # no .mode() -> error
#
#    On Parquet this bites even harder than on CSV, because PARTITIONED
#    output creates a whole tree of folders - with append you can very
#    easily end up with the same partition written twice.
#
# 3. ⭐⭐ THE BIG PARQUET-WRITE POINT: .mode("append") IS NOT A SAFE UPDATE.
#
#    Parquet has NO concept of row-level change. "append" only means
#    "put MORE FILES next to the old ones". So if you append the same data
#    twice, you do not get an error - you get DUPLICATE ROWS that are now
#    baked into the dataset, and nothing marks which file is the "new" one.
#
#           overwrite  -> a clean, idempotent full replacement  ✅
#           append     -> grows forever, duplicates silently     ⚠️
#
#    🎤 So for a re-runnable Databricks job, prefer .mode("overwrite").
#       If you genuinely need incremental loads without duplicates, that is
#       what table formats (Iceberg / Delta) exist for - they add a
#       transaction log on top of the Parquet files so UPSERT/MERGE work.
#
# 4. ⭐ WHY EVERYONE WRITES PARQUET INSTEAD OF CSV
#
#       - columnar   -> downstream reads only the columns it needs
#       - typed     -> the schema travels with the file, no inference
#       - compressed -> typically 3-10x smaller than the same CSV
#       - stats     -> min/max per row group enables file skipping
#       - nested    -> structs and arrays are supported
#
#    👉 The normal lakehouse pattern is: land RAW data as CSV/JSON, then write
#       PARQUET for everything downstream. This script is that second half.
#
# 5. 📂 THE OUTPUT IS A FOLDER OF PART FILES:
#
#           table_overwrite/
#           ├── part-00000-....snappy.parquet
#           ├── part-00001-....snappy.parquet
#           └── _SUCCESS
#
#    ✔️ _SUCCESS is the empty marker that says "the write finished".
#       Reading ignores it; humans and monitoring use it.
#
#    One part file PER TASK - so 200 tasks = 200 files. That is normal and
#    it is why reading points at a FOLDER.
#
# 6. ⭐ CONTROLLING THE FILE COUNT (measured in the NEXT run, not this one)
#
#           df.repartition(8)   -> ~8 part files, full shuffle (use for BIG data)
#           df.coalesce(1)      -> 1 part file, NO shuffle (SMALL data only)
#
#    ⚠️ Too many tiny files is the classic Spark performance killer - it is
#    called the small-files problem. Many small parquet files mean many storage
#    open/close operations and a slow driver listing. If your job writes
#    thousands of 2 KB files, fix the partitioning.
#
# 7. ⭐ COMPRESSION
#
#       snappy   default - fast, good ratio, the safe choice
#       gzip     smaller files, slower to write
#       zstd     modern favourite - good ratio and speed
#       none     already-compressed data
#
#    You can see the codec in the file names: part-....snappy.parquet
#
# 8. ⚠️ NEVER WRITE TO THE PATH YOU ARE READING FROM - the lazy read may
#    execute AFTER the overwrite has already deleted the data.
#
# 9. 📖 The other parquet write case (partitioned output, many folders):
#           OPTIONAL/02) writing_parquet_folder.py
