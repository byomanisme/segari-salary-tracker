# 🥬 Gajiku Segari - Segari Salary Tracker & Work Shift Manager

<div align="center">
  <img src="segari_salary_tracker_app/assets/images/app_logo.png" width="128" height="128" alt="Gajiku Segari Logo" />
  <h3>Aplikasi Pelacak Shift Kerja, Estimasi Gaji Bersih & Target SKU Segari</h3>
  <p>Dikembangkan untuk Daily Worker (DW) Segari dengan sistem kalkulasi multi-tier, jadwal shift resmi, denda QC, dan ekspor laporan PDF / WhatsApp.</p>
  
  <p>
    <a href="https://lukmanhakim.id/segari/"><strong>🌐 Live Landing Page</strong></a> •
    <a href="https://lukmanhakim.id/apk/SegariSalaryTracker.apk"><strong>📲 Unduh APK Langsung</strong></a>
  </p>
</div>

---

## ✨ Fitur Utama

- 💰 **Estimasi Gaji Bersih (Take Home Pay)**:
  - Perhitungan otomatis upah harian shift reguler, shift MP3H, double MP3H, dan training.
  - Siklus bulanan kalender (01 s/d akhir bulan) dengan tanggal gajian resmi setiap tanggal 6.
- 📦 **Target SKU Multi-Tier (Severity 1, 2, 3)**:
  - Pelacakan akumulasi picking SKU bulanan dengan visualisasi progress bar dan kalkulasi komisi otomatis.
- ⚠️ **Pencatatan Denda Komplain Customer**:
  - Log potongan denda QC komplain dengan kategori resmi dan bukti pendukung.
- 🕒 **Jadwal Kerja & Preset Resmi Segari**:
  - Mendukung seluruh shift resmi Segari (Subuh, Pagi, Siang, MP3H Dini Hari/Malam) dan kombinasi lembur dengan gap 1 jam istirahat (`09:00 - 18:00 & 19:00 - 22:00`).
- 🎮 **Segari Pixel Mascot System**:
  - Maskot pixel art interaktif (Ular Hijau, Ulat Sayur, Kucing Gudang, Ayam Peternak) yang melintasi contribution matrix.
- 📄 **Ekspor Slip Gaji PDF & WhatsApp**:
  - Cetak slip gaji format resmi A4 ber-watermark doodle sembako Segari.
  - Ekspor pesan WhatsApp siap kirim ke koordinator / leader.
- 🔄 **In-App OTA Auto-Update**:
  - Pembaruan aplikasi otomatis langsung dari dalam aplikasi via server remote `https://lukmanhakim.id/apk/version.json`.
- ☁️ **Cloud Sync & Backup Google Drive**:
  - Backup dan restore database SQLite/SharedPreferences secara aman.

---

## 🛠️ Tech Stack & Arsitektur

- **Framework**: [Flutter 3.x](https://flutter.dev) (Dart 3.x)
- **State Management**: Reactive Provider / Stateful Services
- **Local Database**: SharedPreferences & SQLite Data Storage
- **PDF Generation**: `pdf` & `printing` plugins
- **Networking & OTA**: `http`, `package_info_plus`, Android PackageInstaller Intent
- **Website & Portfolio**: HTML5, Vanilla CSS3 (Mobile-First responsive, glassmorphism), JavaScript ES6

---

## 🚀 Struktur Direktori

```text
hitung_gaji_segari/
├── segari_salary_tracker_app/   # Source code aplikasi Flutter (Android/Web/iOS)
│   ├── lib/
│   │   ├── models/              # Attendance, SKU Entry, Penalty, Settings
│   │   ├── screens/             # Beranda, Riwayat, Target SKU, Settings, Add/Edit
│   │   ├── services/            # UpdateService, PdfService, CloudSync
│   │   └── widgets/             # SalaryHeroCard, ContributionGrid, Mascots
│   └── assets/images/           # App icons, doodles, and branding assets
├── portfolio_web/               # Landing page web & API update endpoint
└── README.md
```

---

## 👨‍💻 Developer & Attribution

- **Developer**: [byomanisme](https://github.com/byomanisme) (Lukman Hakim)
- **Email**: `luwi.vansteve@gmail.com`
- **Website**: [lukmanhakim.id](https://lukmanhakim.id)
