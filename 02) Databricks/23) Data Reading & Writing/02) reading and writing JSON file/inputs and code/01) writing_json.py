# ============================================================
# PIPELINE : Databricks Volume -> PySpark -> DataFrame -> Databricks Volume
# INPUT    : 01) employees.json
# OUTPUT   : /Volumes/workspace/default/json_volume/output/employees_*  (a FOLDER per write)
# PURPOSE  : The base case - WRITE a DataFrame out as JSON, and see all
#            FOUR write modes: append / overwrite / ignore / error.
# ============================================================
from pyspark.sql import SparkSession
from pyspark.sql.functions import col

# Create Spark Session
spark = SparkSession.builder.appName("JSON Write Practice").getOrCreate()

from pyspark.sql.functions import col, current_timestamp, upper

# ------------------------------------------------------------
#  >>> YOUR CODE GOES HERE <<<
# ------------------------------------------------------------

# ---------- STEP 1 - READ ----------
df = spark.read \
    .json("/Volumes/workspace/default/json_volume/input/employees.json")

df.printSchema()

df.show()

# ---------- STEP 2 - make a VISIBLE CHANGE before writing  ⭐ ----------
# ⚠️ If we wrote `df` unchanged, the output would look EXACTLY like the input
#    and you could never PROVE the write happened.
# ✅ So add columns you can SEE:
#       name_upper -> the name in CAPITALS    (proves the transform ran)
#       load_ts    -> the time this job ran   (proves WHICH run wrote it)
df_new = df \
    .withColumn("name_upper", upper(col("name"))) \
    .withColumn("load_ts", current_timestamp())

df_new.show(truncate=False)

# ------------------------------------------------------------
# STEP 3 - WRITE. Two decisions, exactly like CSV:
#   1. the MODE   -> what to do if the output path already exists
#   2. the FORMAT -> .json() here
# ------------------------------------------------------------
# ⭐ Each mode writes to its OWN folder, and the folder name ENDS WITH THE
#    MODE NAME - so a glance at the volume tells you which mode produced it.
# ⚠️ They are FOLDERS, so they end with a SLASH. You must NOT write
#    "employees_mode_overwrite.json".

# 1) OVERWRITE - delete what is already there, then write fresh
df_new.write \
    .mode("overwrite") \
    .json("/Volumes/workspace/default/json_volume/output/employees_mode_overwrite/")

# 2) APPEND - keep what is already there, and ADD these new files
df_new.write \
    .mode("append") \
    .json("/Volumes/workspace/default/json_volume/output/employees_mode_append/")

# 3) IGNORE - if the path EXISTS: do nothing at all.
df_new.write \
    .mode("ignore") \
    .json("/Volumes/workspace/default/json_volume/output/employees_mode_ignore/")

# ------------------------------------------------------------
# STEP 4 - VERIFY: read the output BACK and look at it  ⭐
# ------------------------------------------------------------
# This is the answer to "how do I know the output has my changes?"
print("=" * 60)
print("VERIFYING THE WRITTEN OUTPUT")
print("=" * 60)

check = spark.read.json("/Volumes/workspace/default/json_volume/output/employees_mode_overwrite/")

check.printSchema()
check.show(truncate=False)

# ✅ name_upper and load_ts present  -> the write worked
# ⚠️ missing                          -> you are reading OLD data
for m in ["overwrite", "append", "ignore"]:
    n = spark.read.json(f"/Volumes/workspace/default/json_volume/output/employees_mode_{m}/").count()
    print(f"  employees_mode_{m}/  ->  {n} rows")

# 4) ERROR - if the path EXISTS: FAIL the job loudly. (this is the default)
#    ⚠️ KEPT LAST: on the SECOND run this kills the job, so nothing after it runs.
print("about to write with mode=error (fails if the path exists)")
df_new.write \
    .mode("error") \
    .json("/Volumes/workspace/default/json_volume/output/employees_mode_error/")

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
#           df.write.json(path)          # no .mode() -> error
#
# 3. ⭐ THE BIG JSON-WRITE FACT: SPARK ONLY WRITES "JSON LINES".
#
#    What you get, no matter what the input looked like:
#
#           {"employee_id":101,"name":"Rahul","department":"IT","salary":60000}
#           {"employee_id":102,"name":"Amit","department":"HR","salary":50000}
#
#    one complete object PER LINE. That is it.
#
#    ⚠️ There is NO "multiLine" option on the WRITE side. You CANNOT ask
#    Spark to write a pretty-printed array. Reading has multiLine, writing
#    does not - a very common surprise.
#
#    If you MUST produce a pretty/array JSON, see:
#           OPTIONAL/02) writing_json_single_line_array.py
#
# 4. ⚠️ ONE OBJECT PER LINE also means NO TRAILING COMMAS and no wrapping
#    [ ]. That is exactly why JSON Lines is the format big data prefers:
#    each line is independently readable and splittable.
#
# 5. ⭐ THE OUTPUT IS A FOLDER OF PART FILES - same as CSV:
#
#           employees_overwrite/
#           ├── part-00000-....json
#           ├── part-00001-....json
#           └── _SUCCESS
#
#    To get ONE file (small data only):
#           df.coalesce(1).write.mode("overwrite").json(path)
#
# 6. ⚠️ NEVER WRITE TO THE PATH YOU ARE READING FROM - the lazy read may
#    execute AFTER the overwrite has deleted the data.
#
# 7. JSON-WRITE options worth knowing:
#           .option("compression", "gzip")     -> part-....json.gz
#           .option("dateFormat", "yyyy-MM-dd")
#           .option("timestampFormat", "yyyy-MM-dd'T'HH:mm:ss")
#    ⚠️ Dates/timestamps in JSON follow these format options - if you do not
#    set them, the default format may not be what the consumer expects.
#
# 8. 📖 The other two write cases:
#           OPTIONAL/02) writing_json_single_line_array.py
#           OPTIONAL/03) writing_json_nested.py
