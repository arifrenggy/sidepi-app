# SIDEPI — Aplikasi Identifikasi Penyakit Padi

Aplikasi Android (Flutter) untuk petugas lapangan Dinas Pertanian dan Pangan Kabupaten Sumba Timur.
Petugas mencentang ciri penyakit yang terlihat, aplikasi menampilkan peringkat kemungkinan penyakit
beserta gambar, deskripsi, dan rekomendasi pengendalian. Bekerja tanpa internet.

## Status
Tahap prototipe (0.1.0). Basis pengetahuan masih data contoh dan harus diganti dengan data resmi dinas.

## Cara memasang
1. Buka tab **Actions** di repo ini, pilih workflow **Bangun APK** yang selesai (centang hijau).
2. Unduh artifact **sidepi-apk**, ekstrak, lalu pasang `app-debug.apk` di Android
   (aktifkan "izinkan pemasangan dari sumber tidak dikenal").

## Cara mengganti basis pengetahuan
1. Sunting `assets/basis-pengetahuan.json`.
2. Patuhi aturan: id unik, bobot ciri 1-3, tiap penyakit wajib punya minimal satu ciri kunci (bobot 3).
3. Aplikasi menolak menjalankan basis yang tidak lolos validasi, dengan pesan kesalahan yang jelas.

Skema dan aturan lengkap ada di PRD SIDEPI (logika aplikasi).

## Struktur
- `lib/logika.dart` — mesin penilaian (skor, aturan ciri kunci, label keyakinan, tie-break)
- `lib/models.dart` — model basis pengetahuan + validasi
- `lib/penyimpanan.dart` — riwayat identifikasi di perangkat
- `lib/main.dart` — 8 layar aplikasi
- `test/logika_test.dart` — 10 kasus uji logika

## Membangun sendiri
```
flutter pub get
flutter test
flutter build apk --debug
```
