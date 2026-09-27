# ============================================================
# PIPELINE : Databricks Volume -> PySpark -> DataFrame -> Databricks Volume
# INPUT    : OPTIONAL/05) employees_tab.txt   (tab-delimited .txt)
# OUTPUT   : /Volumes/workspace/default/txt_volume/output/employees_tab_txt/
# PURPOSE  : WRITE a tab-delimited .txt file (a TSV), safely, with quoting.
# ============================================================
from pyspark.sql import SparkSession
from pyspark.sql.functions import col

# Create Spark Session
spark = SparkSession.builder.appName("TXT Tab Write Practice").getOrCreate()

# ------------------------------------------------------------
#  >>> YOUR CODE GOES HERE <<<
# ------------------------------------------------------------

df = spark.read \
    .option("sep", "\t") \
    .option("header", "true") \
    .option("inferSchema", "true") \
    .csv("/Volumes/workspace/default/txt_volume/input/employees_tab.txt")

df.show()

# ---------- WRITE AS A TAB-DELIMITED .txt ----------
df.write \
    .mode("overwrite") \
    .option("sep", "\t") \
    .option("header", "true") \
    .csv("/Volumes/workspace/default/txt_volume/output/employees_tab_txt_mode_overwrite/")

# ============================================================
# NOTES
# ============================================================
# 1. ⭐ TAB IS THE SAFEST DELIMITER IN TEXT DATA.
#
#    Why? Because tabs are almost never inside real values, while commas and
#    pipes often are. That means quoting is rarely triggered at all, and the
#    file stays simple and readable for both machines and humans.
#
#    It is also why databases export TSV by default for bulk loads.
#
# 2. 🎯 SAME RULE AS THE PIPE CASE: use the CSV writer, not .text().
#    "\t" is just another single-character separator for .csv().
#
# 3. ⚠️ TABS HIDE IN YOUR SOURCE DATA ANYWAY. A value copied from Excel or a
#    PDF often contains a stray tab that you cannot see. The CSV writer will
#    quote it, which is correct - but the receiving system may not expect a
#    quoted field in a "TSV". If that happens, remove the tabs before writing:
#
#           from pyspark.sql.functions import regexp_replace, col
#           df = df.withColumn("name", regexp_replace(col("name"), "\t", " "))
#
# 4. ⚠️ TRAILING TABS. Some writers add a tab at the end of every line,
#    which produces an extra EMPTY column when the file is read back.
#    On the read side the fix is to drop the extra column; on the write side
#    the fix is not to create it. If you build lines by hand with concat_ws,
#    be careful about a trailing empty column - another reason to prefer the
#    CSV writer.
#
# 5. 💡 WHICH SEPARATOR SHOULD YOU PICK?
#
#           ","   most portable, but needs quoting for text fields
#           "\t"  safest against collisions, poor for manual reading
#           "|"   readable and collision-resistant, common in data feeds
#           ";"   needed when commas are decimal separators
#
# 6. WRITE MODES - covered in full in ../01) writing_txt.py. Short version:
#
#       .mode("overwrite")  replace anything already at the path  <- used here
#       .mode("append")     keep old files and add new ones
#       .mode("ignore")     do nothing if the path already exists
#       .mode("error")      FAIL if the path exists (the default)
#
# 7. 📂 Output is a FOLDER of part files - not one .tsv file.
