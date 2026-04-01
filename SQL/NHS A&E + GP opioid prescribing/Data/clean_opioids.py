import pandas as pd

INPUT  = r"C:\ProgramData\MySQL\MySQL Server 8.0\Uploads\opioids_202304.csv"
OUTPUT = r"C:\ProgramData\MySQL\MySQL Server 8.0\Uploads\opioids_clean.csv"

print("Reading file...")
df = pd.read_csv(INPUT, dtype=str, encoding="latin-1")
print(f"Rows: {len(df):,}")
print(f"Columns: {len(df.columns)}")

print("Saving clean version...")
df.to_csv(OUTPUT, index=False, lineterminator="\n")
print(f"Done! Saved to {OUTPUT}")
