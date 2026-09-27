# ============================================================
# PIPELINE : Databricks Volume -> PySpark -> DataFrame -> Databricks Volume
# INPUT    : 01) employees.txt     (raw log lines)
# OUTPUT   : /Volumes/workspace/default/txt_volume/output/employees_*  (a FOLDER per write)
# PURPOSE  : The base case - WRITE text with .text(), and see all FOUR
#            write modes: append / overwrite / ignore / error.
# ============================================================
from pyspark.sql import SparkSession
from pyspark.sql.functions import col

# Create Spark Session
spark = SparkSession.builder.appName("TXT Write Practice").getOrCreate()

from pyspark.sql.functions import col, concat, current_timestamp, lit, upper

# ------------------------------------------------------------
#  >>> YOUR CODE GOES HERE <<<
# ------------------------------------------------------------

# ---------- STEP 1 - READ ----------
# .text() gives us ONE column called "value" - which is exactly what
# the text writer wants back.
df = spark.read.text("/Volumes/workspace/default/txt_volume/input/employees.txt")

df.printSchema()   # value: string

df.show(truncate=False)

# ---------- STEP 2 - make a VISIBLE CHANGE before writing  ⭐ ----------
# ⚠️ .text() needs exactly ONE string column, so we cannot add a column here
#    (unlike CSV/JSON/Parquet where we added name_upper + load_ts).
# ✅ Instead we change the LINE ITSELF - uppercased, with a marker appended.
#    The result is impossible to miss when you read the output back.
df_new = df.withColumn(
    "value",
    concat(upper(col("value")), lit("  <-- WRITTEN BY SPARK"))
)

df_new.show(truncate=False)

# ------------------------------------------------------------
# STEP 3 - WRITE - .text() writes ONE LINE PER ROW
# ------------------------------------------------------------
# ⚠️ RULE: the DataFrame must have exactly ONE column, of type STRING.
#    "value" already is that column, so we can write it directly.
#
# ⭐ Each mode writes to its OWN folder, and the folder name ENDS WITH THE
#    MODE NAME - so a glance at the volume tells you which mode produced it.
# ⚠️ They are FOLDERS, so they end with a SLASH. You must NOT write
#    "employees_mode_overwrite.txt".

# 1) OVERWRITE - delete what is already there, then write fresh
df_new.write \
    .mode("overwrite") \
    .text("/Volumes/workspace/default/txt_volume/output/employees_mode_overwrite/")

# 2) APPEND - keep what is already there, and ADD these new files
df_new.write \
    .mode("append") \
    .text("/Volumes/workspace/default/txt_volume/output/employees_mode_append/")

# 3) IGNORE - if the path EXISTS: do nothing at all.
df_new.write \
    .mode("ignore") \
    .text("/Volumes/workspace/default/txt_volume/output/employees_mode_ignore/")

# ------------------------------------------------------------
# STEP 4 - VERIFY: read the output BACK and look at it  ⭐
# ------------------------------------------------------------
print("=" * 60)
print("VERIFYING THE WRITTEN OUTPUT")
print("=" * 60)

check = spark.read.text("/Volumes/workspace/default/txt_volume/output/employees_mode_overwrite/")

check.show(truncate=False)

# ✅ You should see CAPITALS and "<-- WRITTEN BY SPARK" on every line.
# ⚠️ If the original lower-case lines come back, you are reading OLD data.
for m in ["overwrite", "append", "ignore"]:
    n = spark.read.text(f"/Volumes/workspace/default/txt_volume/output/employees_mode_{m}/").count()
    print(f"  employees_mode_{m}/  ->  {n} rows")

# 4) ERROR - if the path EXISTS: FAIL the job loudly. (this is the default)
#    ⚠️ KEPT LAST: on the SECOND run this kills the job, so nothing after it runs.
print("about to write with mode=error (fails if the path exists)")
df_new.write \
    .mode("error") \
    .text("/Volumes/workspace/default/txt_volume/output/employees_mode_error/")

# ------------------------------------------------------------
# ⚠️ WHAT IF YOU HAVE MANY COLUMNS? .text() will NOT accept them.
#    You must JOIN them into one string first - this is the mirror image
#    of split()/substr() on the reading side:
#
#           from pyspark.sql.functions import concat_ws, col
#           out = df.select(concat_ws("|", col("id"), col("name"), col("salary"))
#                           .alias("value"))
#           out.write.mode("overwrite").text(path)
#
#    concat_ws = "concatenate WITH separator". See
#           OPTIONAL/03) writing_txt_parse_columns.py
# ------------------------------------------------------------

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
#           df.write.text(path)          # no .mode() -> error
#
# 3. 🎯 WHAT .text() IS ACTUALLY GOOD FOR
#    Not really for "data" - for LOGS, reports, and flat files:
#           - writing an audit / run log line per record
#           - exporting a concatenated string for a legacy system
#           - producing a plain file that a human will open in Notepad
#    If the consumer wants STRUCTURE, use .csv() / .json() / .parquet()
#    instead - they carry column names and types, .text() carries neither.
#
# 4. 📂 THE OUTPUT IS A FOLDER OF PART FILES, exactly like every other
#    Spark write:
#
#           employees_overwrite/
#           ├── part-00000-....txt
#           └── _SUCCESS
#
#    ⚠️ .text() does NOT produce "employees.txt". If a downstream system
#    needs one exact filename, you rename it after the job (dbutils.fs.mv)
#    or write it with a single-part write - see
#           OPTIONAL/02) writing_txt_wholetext.py
#
# 5. ⚠️ NO TYPES, NO COLUMN NAMES. A text file cannot carry a schema, so
#    whoever reads it back needs the layout documented somewhere. This is
#    why .text() is the format of last resort for data interchange.
#
# 6. ⚠️ NEVER WRITE TO THE PATH YOU ARE READING FROM - the lazy read may
#    execute AFTER the overwrite has deleted the data.
#
# 7. 📖 The other text write cases:
#           OPTIONAL/02) writing_txt_wholetext.py       one file / lineSep
#           OPTIONAL/03) writing_txt_parse_columns.py   build a line with concat_ws
#           OPTIONAL/04) writing_txt_pipe.py            pipe-delimited
#           OPTIONAL/05) writing_txt_tab.py             tab-delimited
#           OPTIONAL/06) writing_txt_fixed_width.py     fixed-width output
