# ============================================================
# PIPELINE : Databricks Volume -> PySpark -> DataFrame -> Databricks Volume
# INPUT    : OPTIONAL/06) employees_no_header.csv  (no header row)
# OUTPUT   : /Volumes/workspace/default/csv_volume/output/employees_no_header/
# PURPOSE  : WRITE a CSV with NO header row - for a downstream system
#            that only accepts bare data rows.
# ============================================================
from pyspark.sql import SparkSession
from pyspark.sql.functions import col

# Create Spark Session
spark = SparkSession.builder.appName("CSV No Header Write Practice").getOrCreate()

# ------------------------------------------------------------
#  >>> YOUR CODE GOES HERE <<<
# ------------------------------------------------------------

# read the no-header file and name the columns ourselves
df = spark.read \
    .option("header", "false") \
    .option("inferSchema", "true") \
    .csv("/Volumes/workspace/default/csv_volume/input/employees_no_header.csv") \
    .toDF("employee_id", "name", "department", "salary")

df.show()

# ---------- WRITE WITH NO HEADER ----------
# Option A - just leave header off (it is false by default)
df.write \
    .mode("overwrite") \
    .csv("/Volumes/workspace/default/csv_volume/output/employees_no_header_mode_overwrite/")

# Option B - be explicit, so the next reader of this script knows it is intended
df.write \
    .mode("overwrite") \
    .option("header", "false") \
    .csv("/Volumes/workspace/default/csv_volume/output/employees_no_header_explicit_mode_overwrite/")

# ============================================================
# NOTES
# ============================================================
# 1. ⚠️ header on WRITE defaults to FALSE - the opposite of what you
#    usually want. So writing without a header is the DEFAULT, and most
#    real jobs must turn it ON:
#
#           .option("header", "true")      <- remember this one
#
#    Forgetting it is the single most common "my output has no column
#    names" bug when a CSV is written from Spark.
#
# 2. 🎯 SO WHY WRITE WITHOUT A HEADER AT ALL?
#    Because some consumers REJECT it:
#       - databases using a bulk loader (COPY / \copy / LOAD DATA)
#       - older mainframe / fixed-layout importers
#       - systems that validate "every row must have N fields"
#    A header row breaks all of those.
#
# 3. 🎤 INTERVIEW POINT: reading and writing have OPPOSITE header defaults.
#       read  : header defaults to false, so you set it TRUE
#       write : header defaults to false, and you often FORGET to set TRUE
#    Same option name, same default - but the "expected" value is different
#    on each side because the goal is different.
#
# 4. ⚠️ A CAUTION ABOUT LOSING NAMES. With no header, the column names only
#    exist inside your code. The moment the file leaves your job, nobody
#    knows what _c0.._c3 mean unless someone wrote the mapping down.
#    Keep the order documented somewhere (a schema file, a ticket, a wiki)
#    or the file becomes unusable six months later.
#
# 5. WRITE MODES - covered in full in ../01) writing_csv.py. Short version:
#
#       .mode("overwrite")  replace anything already at the path  <- used here
#       .mode("append")     keep old files and add new ones
#       .mode("ignore")     do nothing if the path already exists
#       .mode("error")      FAIL if the path exists (the default)
#
# 6. 📂 Output is a FOLDER of part files, and each part file also has no
#    header - Spark applies the option to every part file it writes.
