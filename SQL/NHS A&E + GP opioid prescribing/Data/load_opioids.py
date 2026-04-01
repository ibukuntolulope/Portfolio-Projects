import pandas as pd
import mysql.connector

MYSQL_PASSWORD = "Iyanu..b3354!"

INPUT_FILE = r"C:\ProgramData\MySQL\MySQL Server 8.0\Uploads\opioids_clean.csv"

print("Connecting to MySQL...")
conn = mysql.connector.connect(
    host="localhost",
    user="root",
    password=MYSQL_PASSWORD,
    database="nhs_ae"
)
cursor = conn.cursor()
print("Connected!")

print("Reading CSV...")
df = pd.read_csv(INPUT_FILE, dtype=str, encoding="latin-1")
df = df.where(pd.notnull(df), None)  # Replace NaN with None (NULL in MySQL)
print(f"Rows to insert: {len(df):,}")

# Clean numeric columns
for col in ["YEAR_MONTH", "QUANTITY", "ITEMS", "TOTAL_QUANTITY", "ADQUSAGE", "NIC", "ACTUAL_COST"]:
    df[col] = pd.to_numeric(df[col], errors="coerce")

INSERT_SQL = """
INSERT INTO gp_prescribing (
    year_month, regional_office_name, regional_office_code,
    icb_name, icb_code, pco_name, pco_code,
    practice_name, practice_code,
    address_1, address_2, address_3, address_4, postcode,
    bnf_chemical_substance, chemical_substance_descr,
    bnf_code, bnf_description, bnf_chapter_plus_code,
    quantity, items, total_quantity, adqusage,
    nic, actual_cost, unidentified, snomed_code
) VALUES (
    %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s,
    %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s
)
"""

batch_size = 5000
total = 0

print("Inserting data in batches...")
for i in range(0, len(df), batch_size):
    batch = df.iloc[i:i+batch_size]
    rows = [tuple(row) for row in batch[[
        "YEAR_MONTH", "REGIONAL_OFFICE_NAME", "REGIONAL_OFFICE_CODE",
        "ICB_NAME", "ICB_CODE", "PCO_NAME", "PCO_CODE",
        "PRACTICE_NAME", "PRACTICE_CODE",
        "ADDRESS_1", "ADDRESS_2", "ADDRESS_3", "ADDRESS_4", "POSTCODE",
        "BNF_CHEMICAL_SUBSTANCE", "CHEMICAL_SUBSTANCE_BNF_DESCR",
        "BNF_CODE", "BNF_DESCRIPTION", "BNF_CHAPTER_PLUS_CODE",
        "QUANTITY", "ITEMS", "TOTAL_QUANTITY", "ADQUSAGE",
        "NIC", "ACTUAL_COST", "UNIDENTIFIED", "SNOMED_CODE"
    ]].values]
    cursor.executemany(INSERT_SQL, rows)
    conn.commit()
    total += len(rows)
    print(f"  Inserted {total:,} rows so far...")

cursor.close()
conn.close()
print(f"\nDone! Total rows inserted: {total:,}")
