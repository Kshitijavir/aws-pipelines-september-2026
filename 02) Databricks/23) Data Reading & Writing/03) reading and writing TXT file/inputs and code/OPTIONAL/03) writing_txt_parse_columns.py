# ============================================================
# PIPELINE : Databricks Volume -> PySpark -> DataFrame -> Databricks Volume
# INPUT    : 01) employees.txt      (raw log lines)
# OUTPUT   : /Volumes/workspace/default/txt_volume/output/employees_log_delimited/
# PURPOSE  : Parse a raw text file into COLUMNS, then WRITE those columns
#            back out as a delimited text line using concat_ws + .text().
#            This is the write-side mirror of the reading parse script.
# ============================================================
from pyspark.sql import SparkSession
from pyspark.sql.functions import col

# Create Spark Session
spark = SparkSession.builder.appName("TXT Parse Columns Write Practice").getOrCreate()

from pyspark.sql.functions import col, concat_ws, regexp_extract

# ------------------------------------------------------------
#  >>> YOUR CODE GOES HERE <<<
# ------------------------------------------------------------

# ---------- READ (raw text: ONE column called "value") ----------
raw = spark.read.text("/Volumes/workspace/default/txt_volume/input/employees.txt")

# ---------- PARSE the log line into real columns ----------
log_df = raw.select(
    regexp_extract("value", r"^(\d{4}-\d{2}-\d{2})", 1).alias("log_date"),
    regexp_extract("value", r"\b(INFO|WARN|ERROR)\b", 1).alias("level"),
    regexp_extract("value", r"Employee (\w+)", 1).alias("employee"),
    regexp_extract("value", r"from (\w+)", 1).alias("department"),
)

log_df.show(truncate=False)

# ---------- WRITE: join the columns back into ONE string per row ----------
# concat_ws = concatenate WITH separator. It returns a SINGLE string column,
# which is exactly what .text() requires.
out = log_df.select(
    concat_ws("|", col("log_date"), col("level"), col("employee"), col("department"))
    .alias("value")
)

out.write \
    .mode("overwrite") \
    .text("/Volumes/workspace/default/txt_volume/output/employees_log_delimited_mode_overwrite/")

# ============================================================
# NOTES
# ============================================================
# 1. 🔁 THE SYMMETRY WITH READING
#
#       READ   .text()  ->  ONE column  ->  split / regexp_extract  ->  columns
#       WRITE  columns  ->  concat_ws   ->  ONE column             ->  .text()
#
#    Reading takes a line APART. Writing puts it BACK TOGETHER. Same idea,
#    opposite direction.
#
# 2. ⭐ concat_ws vs concat - KNOW THE DIFFERENCE
#
#       concat_ws("|", a, b, c)   skips NULLs, puts the separator only
#                                 BETWEEN real values
#       concat(a, lit("|"), ...)  keeps NULLs as the string "null" and
#                                 drags the separators along
#
#    So concat_ws is what you almost always want, and the difference matters
#    the moment your data has missing values.
#
# 3. ⚠️⚠️ .text() DOES NOT QUOTE ANYTHING - AND THAT IS DANGEROUS.
#
#    If a value already contains your separator, you silently produce a
#    broken file:
#
#       department = "IT|Ops"
#       -> 2026-09-20|INFO|Rahul|IT|Ops        <- now FIVE fields, not four
#
#    And nothing warns you. The file looks fine until someone parses it.
#
#    ✅ If your data could contain the delimiter, DO NOT build the line by
#       hand. Use the CSV writer instead - it quotes automatically:
#           .option("sep", "|").csv(path)
#       See ../OPTIONAL/04) writing_txt_pipe.py
#
# 4. 🎯 SO WHEN IS concat_ws + .text() THE RIGHT CHOICE?
#       - you control the data and KNOW the values are clean
#       - the consumer needs a multi-character separator: "||", "~|~", ":::"
#         (the CSV writer can only do a SINGLE character, so for those you
#          have no alternative but to build the line yourself)
#       - you are writing a report line, not a data interchange file
#
# 5. 💡 TYPES ARE GONE. .text() writes no schema, so numbers and dates are
#    just characters in a line. If the next job needs types, it must parse
#    them again - which is exactly the cost of using text as a format.
#
# 6. WRITE MODES - covered in full in ../01) writing_txt.py. Short version:
#
#       .mode("overwrite")  replace anything already at the path  <- used here
#       .mode("append")     keep old files and add new ones
#       .mode("ignore")     do nothing if the path already exists
#       .mode("error")      FAIL if the path exists (the default)
#
# 7. 📂 Output is a FOLDER of part files, one line per row.
