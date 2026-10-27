# TKP Collector

Aplikasi Android untuk mengambil foto barang bukti + koordinat GPS di TKP lalu mengirimnya ke server di laptop (satu jaringan Wi-Fi).

## Isi
| File | Fungsi |
|---|---|
| `lib/main.dart` | Kode aplikasi (foto, GPS, kirim ke server, alamat server bisa diubah di aplikasi) |
| `android/app/src/main/AndroidManifest.xml` | Sudah berisi izin INTERNET, lokasi, dan izin HTTP biasa |
| `build_apk_windows.ps1` | Pasang semua alat (Git, Java 17, Flutter, Android SDK) + build APK, sekali jalan |
| `server/jalankan_server.bat` | Menjalankan server penerima di laptop (port 8000) |
| `.github/workflows/build-apk.yml` | Build APK otomatis di GitHub (tanpa pasang apa pun di laptop) |

## Cara A — build di laptop (Windows)
1. Klik kanan `build_apk_windows.ps1` → **Run with PowerShell**.
   Kalau diblokir: buka PowerShell di folder ini lalu jalankan
   `powershell -ExecutionPolicy Bypass -File .\build_apk_windows.ps1`
2. Tunggu (pertama kali ±20–40 menit, unduhan ±3 GB).
3. APK: `build\app\outputs\flutter-apk\app-release.apk` (folder otomatis terbuka).

## Cara B — build di GitHub (tanpa instal apa pun)
1. Setiap push ke repo ini otomatis mem-build APK.
2. Buka tab **Actions** di https://github.com/aamutakaliman-gif/TKP-app → tunggu "Build APK" hijau (±8 menit).
3. Unduh APK terbaru langsung (bisa dari HP, tanpa login):
   https://github.com/aamutakaliman-gif/TKP-app/releases/latest/download/tkp-collector.apk

## Menjalankan server di laptop
1. Pasang Python sekali: `winget install Python.Python.3.12`
2. Klik kanan `server\jalankan_server.bat` → **Run as administrator** (pertama kali, supaya firewall port 8000 dibuka).
3. Catat IP Wi-Fi yang muncul, misal `192.168.1.15`.
4. Foto & metadata (lat/lng, waktu, SHA-256) tersimpan di `server\evidence\<nomor perkara>\`.

## Di HP
1. Instal APK (izinkan "sumber tidak dikenal").
2. Isi **Alamat server** `http://192.168.1.15:8000` → tekan ikon Wi-Fi untuk tes koneksi.
3. Isi nomor perkara → Ambil Foto → Ambil GPS → Kirim ke Server.

Kalau tes koneksi gagal: HP & laptop harus satu Wi-Fi/hotspot, IP laptop bisa berubah (cek `ipconfig`), server harus sedang jalan.
