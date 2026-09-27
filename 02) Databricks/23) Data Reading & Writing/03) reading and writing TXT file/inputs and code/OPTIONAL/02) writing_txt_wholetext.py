# ============================================================
# PIPELINE : Databricks Volume -> PySpark -> DataFrame -> Databricks Volume
# INPUT    : 01) employees.txt     (same file as ../01) writing_txt.py)
# OUTPUT   : /Volumes/workspace/default/txt_volume/output/employees_one_file/
# PURPOSE  : Write text as ONE single file, and control the LINE separator
#            - the write-side mirror of the wholetext READ option.
# ============================================================
from pyspark.sql import SparkSession
from pyspark.sql.functions import col

# Create Spark Session
spark = SparkSession.builder.appName("TXT Whole Text Write Practice").getOrCreate()

# ------------------------------------------------------------
#  >>> YOUR CODE GOES HERE <<<
# ------------------------------------------------------------

df = spark.read.text("/Volumes/workspace/default/txt_volume/input/employees.txt")

# ---------- WRITE AS ONE SINGLE FILE ----------
# ⚠️ Without coalesce(1) Spark writes one part file PER TASK.
#    coalesce(1) forces all the data through ONE task -> ONE part file.
df.coalesce(1).write \
    .mode("overwrite") \
    .text("/Volumes/workspace/default/txt_volume/output/employees_one_file_mode_overwrite/")

# ---------- WRITE WITH A CUSTOM LINE SEPARATOR ----------
# mirror of .option("lineSep", "\r\n") on the reading side
df.coalesce(1).write \
    .mode("overwrite") \
    .option("lineSep", "\r\n") \
    .text("/Volumes/workspace/default/txt_volume/output/employees_crlf_mode_overwrite/")

# ============================================================
# NOTES
# ============================================================
# 1. ⚠️⚠️ THE BIG WARNING: coalesce(1) DESTROYS YOUR PARALLELISM.
#
#    Without it            With it
#    ------------------    ---------------------
#    200 tasks             1 task
#    200 part files        1 part file
#    ✅ fast, scalable     🐢 slow, single-threaded
#
#    ALL the data still has to be read in parallel - but only ONE task
#    may write, so one executor does the writing while the rest sit idle.
#    On a large dataset this is the classic way to make a Spark job time out.
#
#    ✅ USE IT ONLY FOR SMALL OUTPUT: a report, a config file, a CSV you
#       must hand to a system that refuses folders.
#
# 2. 📌 coalesce(1) vs repartition(1)
#
#       coalesce(1)      moves data with NO full shuffle   ✅ cheaper
#       repartition(1)   forces a full shuffle             ❌ wasteful
#
#    For "I just want one output file", coalesce(1) is the right tool.
#
# 3. 🎯 THE MIRROR OF READING - and the asymmetry to remember:
#
#       READ    has .option("wholetext", "true")   -> whole FILE as ONE row
#       WRITE   has NO wholetext option            ❌ does not exist
#
#    On the read side, wholetext is a real option. On the write side there
#    is no equivalent switch - "one file" is a PARALLELISM decision, not a
#    format option. That is why you force it with coalesce(1) instead.
#
# 4. WHY CONTROL THE LINE SEPARATOR?
#    Windows tools (and a few mainframe / EDI systems) expect CRLF:
#
#           \n     Unix / Linux / macOS  (the default)
#           \r\n   Windows
#           \r     very old Mac
#
#    ⚠️ Getting this wrong is invisible in Notepad but breaks parsers that
#    look for an exact character sequence. If a consumer says "every line is
#    one giant row", your line separator is the first thing to check.
#
# 5. ⚠️ STILL A FOLDER. Even with coalesce(1), the output is a DIRECTORY
#    containing part-00000-....txt plus a _SUCCESS marker - not a file named
#    "employees.txt". If a system requires an exact filename, copy/rename
#    the part file afterwards (dbutils.fs.mv, or a plain file move).
#
# 6. WRITE MODES - covered in full in ../01) writing_txt.py. Short version:
#
#       .mode("overwrite")  replace anything already at the path  <- used here
#       .mode("append")     keep old files and add new ones
#       .mode("ignore")     do nothing if the path already exists
#       .mode("error")      FAIL if the path exists (the default)
