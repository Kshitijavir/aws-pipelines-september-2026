# ============================================================
# PIPELINE : Databricks Volume -> PySpark -> DataFrame -> Databricks Volume
# INPUT    : OPTIONAL/06) employees_fixed_width.txt   (no delimiter)
# OUTPUT   : /Volumes/workspace/default/txt_volume/output/employees_fixed_width/
# PURPOSE  : WRITE a FIXED-WIDTH text file - build the padded line by hand
#            with rpad(), then write it with .text().
#            This is the write-side mirror of reading with substr().
# ============================================================
from pyspark.sql import SparkSession
from pyspark.sql.functions import col

# Create Spark Session
spark = SparkSession.builder.appName("TXT Fixed Width Write Practice").getOrCreate()

from pyspark.sql.functions import col, concat, lit, lpad, rpad, trim

# ------------------------------------------------------------
#  >>> YOUR CODE GOES HERE <<<
# ------------------------------------------------------------
# ⚠️ We read it back through the SAME fixed-position map we used to read it,
#    so the writer and the reader agree on the layout.
#
#        position  1-3   employee_id   (3 chars)
#        position  5-11  name          (7 chars)
#        position 13-20  department    (8 chars)
#        position 22-26  salary        (5 chars)

raw = spark.read.text("/Volumes/workspace/default/txt_volume/input/employees_fixed_width.txt")

df = raw.select(
    trim(col("value").substr(1, 3)).cast("integer").alias("employee_id"),
    trim(col("value").substr(5, 7)).alias("name"),
    trim(col("value").substr(13, 8)).alias("department"),
    trim(col("value").substr(22, 5)).cast("integer").alias("salary")
)

df.show()

# ---------- WRITE: pad every field to its fixed width ----------
# rpad(text, width, fill)  pads on the RIGHT  (text fields)
# lpad(text, width, fill)  pads on the LEFT   (numbers, right-aligned)
#
# The result is ONE string column, which is what .text() needs.
out = df.select(
    concat(
        lpad(col("employee_id").cast("string"), 3, " "),   # 1-3
        lit(" "),                                          #    4
        rpad(col("name"), 7, " "),                         # 5-11
        lit(" "),                                          #   12
        rpad(col("department"), 8, " "),                   # 13-20
        lit(" "),                                          #   21
        rpad(col("salary").cast("string"), 5, " ")         # 22-26
    ).alias("value")
)

out.write \
    .mode("overwrite") \
    .text("/Volumes/workspace/default/txt_volume/output/employees_fixed_width_mode_overwrite/")

# ============================================================
# NOTES
# ============================================================
# 1. 🔁 THE SYMMETRY WITH READING
#
#       READ   substr(start, length)         cut characters OUT
#       WRITE  rpad / lpad(width, fill)      pad characters IN
#
#    Reading slices a fixed layout apart; writing builds one back up.
#    Both sides must agree on the SAME position map, or the file is garbage.
#
# 2. ⭐ rpad vs lpad - GET THIS RIGHT OR NUMBERS LOOK WRONG
#
#       rpad(value, width, " ")   pad the RIGHT   -> text fields
#       lpad(value, width, " ")   pad the LEFT    -> numbers
#
#    Numbers are right-aligned so the digits line up in a column:
#
#           102 Amit     HR        50000
#           103 Neha     Finance   70000
#                                     ^^ aligned
#
#    Left-align a number and the column still "works" - it just looks wrong
#    to anyone reading a printed report, which is the whole point of
#    fixed-width formats.
#
# 3. ⚠️⚠️ THE OVERFLOW TRAP. rpad/lpad do NOT truncate.
#    If a value is LONGER than the width, the whole line shifts right and
#    every field after it moves:
#
#           department = "Infrastructure"   (14 chars, width is 8)
#           -> the line becomes 6 characters too long
#           -> the reader slices the WRONG characters and you get silent
#              corruption, not an error
#
#    ✅ Defend against it explicitly:
#           .substr(1, 8)     truncate first, then pad
#       e.g.  rpad(col("department").substr(1, 8), 8, " ")
#
#    This is the single most important thing to know about writing
#    fixed-width files - and the reason fixed-width is the most brittle
#    text format there is.
#
# 4. ⚠️ NULLS BECOME THE TEXT "null" when you cast to string.
#    rpad(col("x").cast("string"), 8, " ") on a null gives "null    ".
#    Use coalesce(col("x"), lit("")) first if you want blanks.
#
# 5. 🎯 WHY WRITE FIXED-WIDTH AT ALL? Almost always a LEGACY consumer:
#    40+ year old banking / insurance / telecom / government systems whose
#    COBOL copybook defines exact character positions. It is a terrible
#    format, but those systems are not changing.
#
# 6. 💡 lit(" ") is used to insert the single spaces between fields. Those
#    gaps are part of the layout - do not forget them, or every field after
#    the gap shifts by one.
#
# 7. WRITE MODES - covered in full in ../01) writing_txt.py. Short version:
#
#       .mode("overwrite")  replace anything already at the path  <- used here
#       .mode("append")     keep old files and add new ones
#       .mode("ignore")     do nothing if the path already exists
#       .mode("error")      FAIL if the path exists (the default)
#
# 8. 📂 Output is a FOLDER of part files - one padded line per row.
