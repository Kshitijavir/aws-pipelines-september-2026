# ============================================================
# PIPELINE : Databricks Volume -> PySpark -> DataFrame -> Databricks Volume
# INPUT    : 01) employees.csv
# OUTPUT   : /Volumes/workspace/default/csv_volume/output/employees_mode_<MODE>/   (a FOLDER each)
# PURPOSE  : The base case - WRITE a DataFrame out as CSV, see all FOUR
#            write modes, and PROVE the written file really changed.
# ============================================================
from pyspark.sql import SparkSession
from pyspark.sql.functions import col

# Create Spark Session
spark = SparkSession.builder.appName("CSV Write Practice").getOrCreate()

from pyspark.sql.functions import col, current_timestamp, upper

# ------------------------------------------------------------
#  >>> YOUR CODE GOES HERE <<<
# ------------------------------------------------------------

# ------------------------------------------------------------
# STEP 1 - READ the input
# ------------------------------------------------------------
df = spark.read \
    .option("header", "true") \
    .option("inferSchema", "true") \
    .csv("/Volumes/workspace/default/csv_volume/input/employees.csv")

df.printSchema()   # employee_id, name, department, salary

df.show()          # 4 rows

# ------------------------------------------------------------
# STEP 2 - make a VISIBLE CHANGE before writing  ⭐
# ------------------------------------------------------------
# ⚠️ WHY? If we wrote `df` unchanged, the output would look EXACTLY like the
#    input - and you could never tell whether the write actually happened,
#    or whether you were somehow still looking at the source file.
#
# ✅ So we add columns you can SEE:
#       name_upper -> the name in CAPITALS      (proves the transform ran)
#       load_ts    -> the time this job ran     (proves WHICH run wrote it)
#
# 💡 load_ts is extra useful with append: run twice and the duplicate rows
#    will carry DIFFERENT timestamps, so you can see they came from two runs.
df_new = df \
    .withColumn("name_upper", upper(col("name"))) \
    .withColumn("load_ts", current_timestamp())

df_new.printSchema()   # now 6 columns

df_new.show(truncate=False)

# ------------------------------------------------------------
# STEP 3 - WRITE. Every write makes TWO decisions:
#   1. the MODE   -> what to do if the output path already exists
#   2. the FORMAT -> .csv() / .json() / .parquet() / .text()
# ------------------------------------------------------------
# .mode() is optional. If you leave it out, Spark uses "error".
#
# ⭐ Each mode writes to its OWN folder, and the folder name ENDS WITH THE
#    MODE NAME. That way, one glance at the volume tells you which mode produced it.
#
#       output/employees_mode_overwrite/
#       output/employees_mode_append/
#       output/employees_mode_ignore/
#       output/employees_mode_error/
#
# ⚠️ Note these are FOLDERS, so they end with a SLASH. See NOTES 9 - you must
#    NOT write "employees_mode_overwrite.csv".

# 1) OVERWRITE - delete what is already there, then write fresh
#    Always succeeds.
df_new.write \
    .mode("overwrite") \
    .option("header", "true") \
    .csv("/Volumes/workspace/default/csv_volume/output/employees_mode_overwrite/")

# 2) APPEND - keep what is already there, and ADD these new files
#    1st run: 4 rows.  2nd run: 8 rows - the SAME 4 rows again.
df_new.write \
    .mode("append") \
    .option("header", "true") \
    .csv("/Volumes/workspace/default/csv_volume/output/employees_mode_append/")

# 3) IGNORE - if the path EXISTS: do nothing at all.
#             if the path is EMPTY/missing: write normally.
df_new.write \
    .mode("ignore") \
    .option("header", "true") \
    .csv("/Volumes/workspace/default/csv_volume/output/employees_mode_ignore/")

# ------------------------------------------------------------
# STEP 4 - VERIFY: read the output BACK and look at it
# ------------------------------------------------------------
# ⭐ This is the answer to "how do I know the output has my changes?"
#    You read it - you never assume it.
print("=" * 60)
print("VERIFYING THE WRITTEN OUTPUT")
print("=" * 60)

check = spark.read \
    .option("header", "true") \
    .csv("/Volumes/workspace/default/csv_volume/output/employees_mode_overwrite/")

check.printSchema()
check.show(truncate=False)

# ✅ If you can SEE name_upper and load_ts here, the write worked.
# ⚠️ If they are missing, you are reading the OLD data - check the path.

# Row counts per mode - run this twice and compare:
for m in ["overwrite", "append", "ignore"]:
    n = spark.read.option("header", "true") \
             .csv(f"/Volumes/workspace/default/csv_volume/output/employees_mode_{m}/") \
             .count()
    print(f"  employees_mode_{m}/  ->  {n} rows")

# 4) ERROR - if the path EXISTS: FAIL the job loudly. (this is the default)
#    ⚠️ KEPT LAST on purpose: on the SECOND run this line kills the job, so
#       anything written after it would never execute.
print("about to write with mode=error (fails if the path exists)")
df_new.write \
    .mode("error") \
    .option("header", "true") \
    .csv("/Volumes/workspace/default/csv_volume/output/employees_mode_error/")

# ============================================================
# NOTES - THE FOUR WRITE MODES
# ============================================================
# 1. ⭐ THE MODE TABLE - memorise this, it is a standard interview question
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
#    Think of it as:
#       overwrite → "replace everything"
#       append    → "add to it"
#       ignore    → "if it's there, leave me alone"
#       error     → "STOP, something is wrong"
#
# 2. ⚠️ "error" is the DEFAULT - so this line FAILS on the second run:
#
#           df.write.csv(path)          # no .mode() -> error
#
#    First run  ✅ writes.
#    Second run ❌ "path already exists" and the Databricks job FAILS.
#    This is the classic first-job error people hit.
#
# 3. ⚠️ SO THIS SCRIPT IS NOT RE-RUNNABLE BY DESIGN.
#    Run it twice and:
#       overwrite → fine (replaces)
#       append    → fine (adds MORE duplicate rows!)
#       ignore    → silently skips
#       error     → ❌ FAILS the job
#    That is exactly what these modes mean, so it is a good thing to watch
#    happen once. In a real pipeline you pick ONE mode deliberately.
#
# 4. ⭐ THE OUTPUT IS A FOLDER, NOT A FILE - exactly like reading.
#    Spark writes one part file PER TASK:
#
#           employees_mode_overwrite/
#           ├── part-00000-....csv
#           ├── part-00001-....csv
#           └── _SUCCESS
#
#    So you do NOT get "employees.csv" out. With 1 task you get 1 part file,
#    with 200 tasks you get 200. There is no "filename" option - that is the
#    whole point of the folder model.
#
#    ⭐ That is also why each mode writes to a folder whose NAME ends in the
#    mode: from the volume alone you can tell which write produced which folder.
#
# 5. HOW TO GET ONE FILE (small data only):
#           df.coalesce(1).write.mode("overwrite").csv(path)
#    ⚠️ coalesce(1) forces everything through ONE task - fine for a small
#    file, terrible for big data. Use it for reports, never for volumes.
#
# 6. ⚠️ NEVER WRITE TO THE PATH YOU ARE READING FROM.
#
#           reader = spark.read.csv(PathA)      # lazy - nothing read yet
#           reader.write.mode("overwrite").csv(PathA)   # 💥
#
#    The write can delete PathA BEFORE the lazy read has executed, so you
#    either lose your data or get an empty result. Always write to a NEW
#    path, or to a temp path and then move it.
#
# 7. CSV-WRITE-ONLY options worth knowing:
#           .option("header", "true")     write the header row
#           .option("sep", "|")           choose the delimiter
#           .option("quote", "\"")        quoting style
#           .option("nullValue", "")      how nulls are written
#           .option("compression", "gzip")   -> part-....csv.gz
#
# 8. 📖 FULL mode table + every write option for the other formats:
#           OPTIONAL/02) writing_csv_pipe.py      sep = "|"
#           OPTIONAL/03) writing_csv_tab.py       sep = "\t"
#           OPTIONAL/04) writing_csv_semicolon.py sep = ";"
#           OPTIONAL/05) writing_csv_quoted.py    quotes inside values
#           OPTIONAL/06) writing_csv_no_header.py header = false
#
# 9. ⚠️⚠️ THE PATH IS A FOLDER - DO NOT PUT ".csv" ON THE END.
#
#    This looks reasonable...
#
#           .csv("/Volumes/workspace/default/csv_volume/output/employees_mode_overwrite.csv")
#
#    ...but it does NOT give you a file called that. Spark treats the string
#    as a DIRECTORY PREFIX, so it CREATES A FOLDER literally named
#    "employees_mode_overwrite.csv" and puts part-00000-....csv INSIDE it:
#
#           employees_mode_overwrite.csv/       <-- a FOLDER, not a file
#           ├── part-00000-....csv
#           └── _SUCCESS
#
#    💥 The damage: it looks like a single file in the volume, so someone will
#       eventually try to READ it as one and be confused, and if a consumer
#       downloads "employees_mode_overwrite.csv" they get a folder.
#
#    ✅ CORRECT - point at a folder, end with a slash:
#           .csv("/Volumes/workspace/default/csv_volume/output/employees_mode_overwrite/")
#
#    🎤 Interview point: in Spark, the write path is a DIRECTORY, not a file
#    name. There is no way to say "write exactly one file called X" - the
#    closest you get is .coalesce(1) (see NOTE 5) and then RENAME the part
#    file yourself with dbutils.fs.mv (or shutil.move on a volume).
#
#    ⚠️ The ONE exception is a file-based sink like a database JDBC URL or a
#    Hive table name - there the path is not a folder. But for .csv/.json/
#    .parquet/.text() on a volume, it always is.
#
# 10. 🔍 HOW DO YOU KNOW THE OUTPUT REALLY HAS YOUR CHANGES?
#    STEP 4 in the code above does exactly this: it READS THE OUTPUT BACK
#    and prints the schema and the rows.
#
#    ✅ You should SEE:
#           name_upper   -> proof the transform ran
#           load_ts      -> proof of WHICH run wrote the data
#
#    ⚠️ You should NOT trust:
#           - that the job "succeeded" (a job can succeed and write nothing)
#           - that the folder exists (it may hold only _SUCCESS)
#           - that the row count "looks right" (append doubles it silently)
#
#    📌 The habit: verify by READING BACK, and always .count() a write you
#       do not fully control. That is also what catches the append-duplicate
#       problem (NOTE 3) - the count goes 4 -> 8 -> 12. The data never
#       errors, it just quietly grows.
