import os
import duckdb

# =====================================================
# FILE LOCATIONS
# =====================================================

sql_file = "sql/opportunity_scoring_engine.sql"
output_file = "data/outputs/opportunity_scoring_engine.csv"

os.makedirs(os.path.dirname(output_file), exist_ok=True)

# =====================================================
# DATE PARAMETERS
# =====================================================

start_date = "2026-01-01"
end_date = "2026-06-05"

# =====================================================
# FILTER PARAMETERS
# =====================================================

page_pattern = "https://uk.rs-online.com/web/content/discovery%"

brand_regex = r".*(rs group|rs components|rs online|electrocomponents).*"
short_brand_regex = r".*\brs\b.*"

# =====================================================
# OPPORTUNITY THRESHOLDS
# =====================================================

pos_low = 10
pos_high = 30

striking_pos = 10
improve_pos = 20
ignore_pos = 7

min_words = 3
ctr_threshold = 50

# =====================================================
# QUESTION WORDS
# =====================================================

question_words = [
    "how",
    "what",
    "when",
    "where",
    "why"
]

question_words_sql = ",".join(
    [f"'{word}'" for word in question_words]
)

# =====================================================
# SCORING WEIGHTS
# =====================================================

w_position = 0.35
w_impression_gap = 0.30
w_ctr = 0.20
w_longtail = 0.15

# =====================================================
# LOAD SQL
# =====================================================

with open(sql_file, "r", encoding="utf-8") as f:
    sql_query = f.read()

# =====================================================
# REPLACE PARAMETERS
# =====================================================

replacements = {
    "$start_date": f"'{start_date}'",
    "$end_date": f"'{end_date}'",

    "$page_pattern": f"'{page_pattern}'",
    "$brand_regex": f"'{brand_regex}'",
    "$short_brand_regex": f"'{short_brand_regex}'",

    "$pos_low": str(pos_low),
    "$pos_high": str(pos_high),
    "$striking_pos": str(striking_pos),
    "$improve_pos": str(improve_pos),
    "$ignore_pos": str(ignore_pos),

    "$min_words": str(min_words),
    "$ctr_threshold": str(ctr_threshold),

    "$w_position": str(w_position),
    "$w_impression_gap": str(w_impression_gap),
    "$w_ctr": str(w_ctr),
    "$w_longtail": str(w_longtail),

    "$question_words": f"({question_words_sql})"
}

for key, value in replacements.items():
    sql_query = sql_query.replace(key, value)

# =====================================================
# EXECUTE QUERY
# =====================================================

print("Running content opportunity analysis...")

con = duckdb.connect()

export_query = f"""
COPY (
{sql_query}
)
TO '{output_file}'
(HEADER, DELIMITER ',')
"""

con.execute(export_query)

print(f"Done! Results written to {output_file}")
