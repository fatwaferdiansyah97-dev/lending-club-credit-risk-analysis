"""
01_reduce_columns.py
=====================
Tujuan: loan.csv asli (145 kolom, ~1.1GB, 2.26 juta baris) terlalu besar untuk
dimuat langsung ke pandas di banyak environment jadi perlu dikurangi

total = reduce_columns(
    "loan.csv",
    "loan_slim.csv"
)
print(f"Selesai. {total} baris ditulis ke loan_slim.csv")
