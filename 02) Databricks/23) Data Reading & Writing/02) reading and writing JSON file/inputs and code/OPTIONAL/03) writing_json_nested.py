# ============================================================
# PIPELINE : Databricks Volume -> PySpark -> DataFrame -> Databricks Volume
# INPUT    : OPTIONAL/03) employees_nested.json  (nested struct + array)
# OUTPUT   : /Volumes/workspace/default/json_volume/output/employees_nested/
# PURPOSE  : WRITE a DataFrame that contains NESTED columns, and see how
#            Spark preserves the nesting in the JSON output.
# ============================================================
from pyspark.sql import SparkSession
from pyspark.sql.functions import col

# Create Spark Session
spark = SparkSession.builder.appName("JSON Nested Write Practice").getOrCreate()

# ------------------------------------------------------------
#  >>> YOUR CODE GOES HERE <<<
# ------------------------------------------------------------

df = spark.read \
    .option("multiLine", "true") \
    .json("/Volumes/workspace/default/json_volume/input/employees_nested.json")

df.printSchema()
#  |-- skills: array<string>
#  |-- address: struct<city: string, country: string>

df.show(truncate=False)

# ---------- WRITE - the nesting is written back out as nested JSON ----------
df.write \
    .mode("overwrite") \
    .json("/Volumes/workspace/default/json_volume/output/employees_nested_mode_overwrite/")
# -> {"employee_id":101,"name":"Rahul","skills":["python","sql"],
#     "address":{"city":"Delhi","country":"India"}}

# ============================================================
# NOTES
# ============================================================
# 1. 🎯 NESTED IN = NESTED OUT. Spark does not flatten anything for you.
#    A struct column and an array column are written as a nested JSON
#    object and a JSON array. So a read -> write round trip keeps the shape
#    intact, which is exactly what you want when you are just moving data.
#
# 2. ⚠️ THIS IS NOT TRUE FOR CSV! Writing the SAME DataFrame to CSV crashes
#    or mangles it, because CSV has no way to represent a struct or array.
#
#           .json(...)     ✅ nesting preserved
#           .parquet(...)  ✅ nesting preserved
#           .csv(...)      ❌ cannot represent it
#           .text(...)     ❌ cannot represent it
#
#    🎤 Good interview point: "JSON and Parquet are self-describing and
#    support nested structures; CSV and TXT are flat text formats."
#
# 3. FLATTENING (the opposite job). If a consumer needs a flat CSV, you must
#    pull the nesting apart yourself:
#
#           df.select("employee_id", "name",
#                     "address.city", "address.country", "skills")
#
#    And an ARRAY is trickier - one row has many skills. You either:
#           .withColumn("skills", concat_ws(",", col("skills")))   # or
#           .withColumn("skill", explode(col("skills")))           # one row per skill
#
# 4. ⚠️ NULLS AND MISSING KEYS look different on the way out.
#    Spark writes a null column as {"field": null}. If the field is absent
#    in the source it also becomes null - so a round trip can ADD explicit
#    nulls that were not in the original file. Usually harmless, but worth
#    knowing when someone diffs two JSON files byte by byte.
#
# 5. WRITE MODES - covered in full in ../01) writing_json.py. Short version:
#
#       .mode("overwrite")  replace anything already at the path  <- used here
#       .mode("append")     keep old files and add new ones
#       .mode("ignore")     do nothing if the path already exists
#       .mode("error")      FAIL if the path exists (the default)
#
# 6. 📂 Output is a FOLDER of part files, each holding JSON Lines.
