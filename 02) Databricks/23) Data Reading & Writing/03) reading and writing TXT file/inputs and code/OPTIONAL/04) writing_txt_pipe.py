# ============================================================
# PIPELINE : Databricks Volume -> PySpark -> DataFrame -> Databricks Volume
# INPUT    : OPTIONAL/04) employees_pipe.txt   (pipe-delimited .txt)
# OUTPUT   : /Volumes/workspace/default/txt_volume/output/employees_pipe_txt/
# PURPOSE  : WRITE a pipe-delimited .txt file - safely, with quoting,
#            using the CSV writer.
# ============================================================
from pyspark.sql import SparkSession
from pyspark.sql.functions import col

# Create Spark Session
spark = SparkSession.builder.appName("TXT Pipe Write Practice").getOrCreate()

# ------------------------------------------------------------
#  >>> YOUR CODE GOES HERE <<<
# ------------------------------------------------------------

df = spark.read \
    .option("sep", "|") \
    .option("header", "true") \
    .option("inferSchema", "true") \
    .csv("/Volumes/workspace/default/txt_volume/input/employees_pipe.txt")

df.show()

# ---------- WRITE AS A PIPE-DELIMITED .txt ----------
df.write \
    .mode("overwrite") \
    .option("sep", "|") \
    .option("header", "true") \
    .csv("/Volumes/workspace/default/txt_volume/output/employees_pipe_txt_mode_overwrite/")

# ============================================================
# NOTES
# ============================================================
# 1. ⭐ THE KEY POINT OF THIS FILE: TO WRITE A DELIMITED .txt, USE .csv().
#
#    Reading taught us that Spark reads by CONTENT, not by extension.
#    Writing is exactly the same:
#
#           READING   employees_pipe.txt  ->  .csv(sep="|")   ✅
#           WRITING   output "as .txt"    ->  .csv(sep="|")   ✅
#
#    ⚠️ There is NO ".txt with delimiters" writer in Spark. A delimited file
#    IS a CSV - the extension you give the output folder does not change that.
#    Spark always writes part-00000-....csv style names anyway.
#
# 2. 🎯 WHY THIS INSTEAD OF concat_ws + .text()?
#
#                            .text() + concat_ws   .csv(sep="|")
#       quoting                       ❌ none          ✅ automatic
#       a value with a "|"        💥 breaks file      ✅ survives
#       a value with a newline    💥 breaks file      ✅ survives
#       realistic for data            rarely            yes
#
#    Rule of thumb: for DATA, use the CSV writer. For a hand-built report
#    line you fully control, .text() is fine.
#
# 3. 🎤 INTERVIEW POINT: "How do you write a pipe-delimited file in Spark?"
#    Answer: you do NOT build strings - you use the CSV writer with
#    .option("sep", "|"). Spark then handles quoting and escaping for you.
#
# 4. ⚠️ THE SEPARATOR IS ONE CHARACTER ONLY. If a system demands "||", the
#    CSV writer cannot do it, and you are pushed back to concat_ws + .text()
#    (with the quoting risk that carries). Ask whether the consumer can
#    accept a single "|" first - often they can.
#
# 5. ⚠️ A NOTE ON THE .txt EXTENSION. Some consumers only accept files that
#    END in .txt. Spark will not name the file for you - you get
#    part-00000-....csv. If the name matters, rename after the job
#    (dbutils.fs.mv on the volume) - that is a normal, expected
#    step in real pipelines.
#
# 6. WRITE MODES - covered in full in ../01) writing_txt.py. Short version:
#
#       .mode("overwrite")  replace anything already at the path  <- used here
#       .mode("append")     keep old files and add new ones
#       .mode("ignore")     do nothing if the path already exists
#       .mode("error")      FAIL if the path exists (the default)
