import json
from collections import defaultdict
from datetime import datetime

with open('scratch_user_data.json', 'r', encoding='utf-8') as f:
    full_data = json.load(f)

meta = full_data.get('sync_metadata', {})
data = full_data.get('data', {})
settings = data.get('settings', {})
records = data.get('records', [])
sku_entries = data.get('sku_entries', [])
penalties = data.get('penalties', [])

name = settings.get('name', 'N/A')
emp_id = settings.get('empId', 'N/A')
reg_rate = settings.get('regulerRate', 120000)
mp3_rate = settings.get('mp3Rate', 50000)
payday = settings.get('paydayDay', 6)

print("=== PROFIL PEKERJA ===")
print(f"Nama           : {name}")
print(f"ID Pekerja     : {emp_id}")
print(f"Tarif Reguler  : Rp {reg_rate:,}")
print(f"Tarif MP3H     : Rp {mp3_rate:,}")
print(f"Tanggal Gajian : Tanggal {payday} setiap bulan")
print(f"Waktu Sync     : {meta.get('synced_at')} (Server Hostinger)")

# Analisis catatan kerja
monthly_records = defaultdict(list)
for r in records:
    d = r.get('date', '')
    if d:
        m_key = d[:7]
        monthly_records[m_key].append(r)

print("\n=== DISTRIBUSI BULANAN SHIFT ===")
grand_total_wage = 0
grand_total_shifts = 0

for m, recs in sorted(monthly_records.items()):
    total_wage = sum(r.get('rate', 0) for r in recs)
    grand_total_wage += total_wage
    grand_total_shifts += len(recs)
    
    shifts = [r.get('typeLabel', r.get('type', '')) for r in recs]
    shift_counts = {s: shifts.count(s) for s in sorted(set(shifts))}
    print(f"Bulan {m}:")
    print(f"  • Total Catatan : {len(recs)} hari kerja/jadwal")
    print(f"  • Total Upah    : Rp {total_wage:,}")
    print(f"  • Detail Shift  : {shift_counts}")

print(f"\nGRAND TOTAL KESELURUHAN (Seluruh Riwayat):")
print(f"  • Total Hari/Catatan : {grand_total_shifts} hari")
print(f"  • Total Upah Shift   : Rp {grand_total_wage:,}")

# SKU Breakdown
print("\n=== RINCIAN DATA SKU & TARGET SEVERITY ===")
total_sku = sum(s.get('count', 0) for s in sku_entries)
for s in sorted(sku_entries, key=lambda x: x.get('date', '')):
    print(f"  • {s.get('date')} : {s.get('count', 0):,} SKU | Catatan: {s.get('notes')} (Kumulatif: {s.get('cumulativeTotal', 0):,})")

sev1_t = settings.get('severity1Target', 13500)
sev1_b = settings.get('severity1Bonus', 500000)
sev2_t = settings.get('severity2Target', 15500)
sev2_b = settings.get('severity2Bonus', 600000)
sev3_t = settings.get('severity3Target', 17500)
sev3_b = settings.get('severity3Bonus', 700000)

print(f"\nProgress SKU Saat Ini: {total_sku:,} SKU")
if total_sku >= sev3_t:
    print(f"  🎉 STATUS: MENCAPAI SEVERITY 3! Bonus Komisi: Rp {sev3_b:,}")
elif total_sku >= sev2_t:
    print(f"  🎉 STATUS: MENCAPAI SEVERITY 2! Bonus Komisi: Rp {sev2_b:,}")
    print(f"  👉 Butuh {sev3_t - total_sku:,} SKU lagi menuju Severity 3 (+Rp {sev3_b - sev2_b:,})")
elif total_sku >= sev1_t:
    print(f"  🎉 STATUS: MENCAPAI SEVERITY 1! Bonus Komisi: Rp {sev1_b:,}")
    print(f"  👉 Butuh {sev2_t - total_sku:,} SKU lagi menuju Severity 2 (+Rp {sev2_b - sev1_b:,})")
else:
    pct = (total_sku / sev1_t) * 100
    print(f"  ⏳ Progress ke Severity 1 : {pct:.1f}% ({total_sku:,} / {sev1_t:,} SKU)")
    print(f"  👉 Kurang {sev1_t - total_sku:,} SKU untuk mendapatkan bonus Rp {sev1_b:,}")

# Denda QC
print("\n=== RINCIAN POTONGAN DENDA QC ===")
total_penalty = sum(p.get('amount', 0) for p in penalties)
for p in sorted(penalties, key=lambda x: x.get('date', '')):
    print(f"  • {p.get('date')} : Rp {p.get('amount', 0):,} | {p.get('typeLabel')} | Catatan: {p.get('notes')}")
print(f"Total Denda: Rp {total_penalty:,}")

# Perhitungan Periode Gajian Segari (Cut-off ke Payday)
# Di Segari, payday adalah tanggal 6
# Periode gajian biasanya tanggal 21 bulan lalu s/d 20 bulan ini, ATAU 1 s/d akhir bulan.
# Mari kita hitung per bulan kalender lengkap

# Detailed Monthly Breakdown
print("\n" + "="*50)
print("=== RINCIAN REKAP GAJI BULAN AGUSTUS 2026 ===")
aug_recs = [r for r in records if r.get('date', '').startswith('2026-08')]
aug_wage = sum(r.get('rate', 0) for r in aug_recs)
aug_sku = sum(s.get('count', 0) for s in sku_entries if s.get('date', '').startswith('2026-08'))
aug_pen = sum(p.get('amount', 0) for p in penalties if p.get('date', '').startswith('2026-08'))

print(f"Total Shift Terdaftar : {len(aug_recs)} hari")
print(f"Total Upah Shift Pokok: Rp {aug_wage:,}")
print(f"Total SKU Terkumpul   : {aug_sku:,} SKU")
print(f"Total Potongan Denda  : -Rp {aug_pen:,}")
print(f"Estimasi Gaji Bersih  : Rp {aug_wage - aug_pen:,} (Sebelum bonus SKU)")

print("\n" + "="*50)
print("=== RINCIAN REKAP GAJI BULAN SEPTEMBER 2026 ===")
sep_recs = [r for r in records if r.get('date', '').startswith('2026-09')]
sep_wage = sum(r.get('rate', 0) for r in sep_recs)
sep_sku = sum(s.get('count', 0) for s in sku_entries if s.get('date', '').startswith('2026-09'))
sep_pen = sum(p.get('amount', 0) for p in penalties if p.get('date', '').startswith('2026-09'))

for r in sep_recs:
    print(f"  • {r.get('date')} ({r.get('dayName')}): {r.get('typeLabel')} - Rp {r.get('rate', 0):,} ({r.get('notes')})")

print(f"Total Shift Terdaftar : {len(sep_recs)} hari")
print(f"Total Upah Shift Pokok: Rp {sep_wage:,}")
print(f"Total SKU Terkumpul   : {sep_sku:,} SKU")
print(f"Total Potongan Denda  : -Rp {sep_pen:,}")
print(f"Estimasi Gaji Berjalan: Rp {sep_wage - sep_pen:,}")

print("\n" + "="*50)
print("=== LOG HARIAN AGUSTUS 2026 ===")
for r in aug_recs:
    print(f"  • {r.get('date')} ({r.get('dayName')}): {r.get('typeLabel')} | Rp {r.get('rate', 0):,} | {r.get('notes')}")
