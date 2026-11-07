# SIDEPI — Sistem Identifikasi Penyakit Padi

Aplikasi Android untuk identifikasi penyakit dan hama tanaman padi. Dirancang
untuk petugas pengamat organisme pengganggu tumbuhan (POPT) dan penyuluh
pertanian, dengan seluruh proses berjalan di dalam perangkat tanpa koneksi
internet.

[![Rilis terbaru](https://img.shields.io/github/v/release/arifrenggy/sidepi-app?label=rilis)](https://github.com/arifrenggy/sidepi-app/releases/latest)
[![Platform](https://img.shields.io/badge/platform-Android-3ddc84)](#prasyarat-dan-build)
[![Lisensi data](https://img.shields.io/badge/data-CC%20BY%204.0-2563eb)](#lisensi)

| | |
| :--- | :--- |
| Versi | 0.13.1 |
| Basis pengetahuan | 20 jenis penyakit dan hama, 42 ciri lapangan |
| Model citra | 8 kelas, TensorFlow Lite di perangkat |
| Jaringan | Tidak diperlukan (mode offline penuh) |
| Ukuran APK | 33,8 MB (arm64) |

---

## Daftar isi

1. [Ringkasan](#ringkasan)
2. [Kemampuan](#kemampuan)
3. [Arsitektur](#arsitektur)
4. [Model](#model)
5. [Dataset](#dataset)
6. [Evaluasi](#evaluasi)
7. [Basis pengetahuan](#basis-pengetahuan)
8. [Struktur proyek](#struktur-proyek)
9. [Prasyarat dan build](#prasyarat-dan-build)
10. [Batasan](#batasan)
11. [Lisensi](#lisensi)
12. [Riwayat perubahan](#riwayat-perubahan)

## Ringkasan

SIDEPI membantu petugas lapangan mengenali penyakit dan hama padi melalui dua
jalur yang saling melengkapi. Jalur pertama membaca 1 sampai 3 foto bagian
tanaman dengan model pengenalan citra. Jalur kedua menelusuri gejala yang
dicatat petugas memakai sistem pakar berbasis pembobotan ciri. Kedua jalur
merujuk pada satu basis pengetahuan yang sama dan menampilkan sumber acuan,
penjelasan, serta anjuran pengendalian.

Pengembangan diarahkan pada kondisi kerja di Kabupaten Sumba Timur: lokasi
pengamatan yang sering tanpa sinyal, perangkat kelas menengah, dan kebutuhan
hasil yang bisa langsung dipakai di lapangan.

## Kemampuan

- **Periksa foto.** Satu sampai tiga foto bagian tanaman digabung menjadi satu
  kesimpulan. Model menolak foto yang bukan tanaman padi sebelum analisis.
- **Identifikasi lewat ciri.** Petugas memilih bagian tanaman, mencentang gejala
  yang terlihat, lalu menerima peringkat kemungkinan beserta ciri kunci yang
  menentukan.
- **Klarifikasi terarah.** Bila dua kandidat teratas adalah pasangan yang sering
  tertukar, aplikasi mengajukan pertanyaan konfirmasi dan menampilkan dua foto
  acuan berdampingan.
- **Galeri acuan.** 42 foto lapangan untuk tujuh kondisi, dapat diperbesar dan
  dilengkapi catatan sumber.
- **Riwayat dan panduan.** Pemeriksaan tersimpan di perangkat, dengan panduan
  pemakaian dan batasan model.

## Arsitektur

```text
Foto kamera
     │
     ▼
[1] Gerbang tanaman ── bukan padi ──▶ ditolak
     │ MobileNetV3-Large, 224 px
     ▼
[2] Segmentasi dan potong latar
     │ indeks kelebihan hijau, ambang Otsu, komponen terbesar
     ▼
[3] Klasifikasi penyakit
     │ 8 kelas, masukan 256 px, cermin ganda
     ▼
[4] Penggabungan multi-foto
     │ rata-rata peluang berbobot keyakinan
     ▼
[5] Sistem pakar
       pembobotan ciri, syarat ciri kunci, pertanyaan konfirmasi
```

Tahap 2 hanya memotong foto yang diambil dari jarak jauh. Foto jarak dekat
dibiarkan utuh karena pemotongan justru menghilangkan bentuk dan tepi daun yang
dipakai pada tahap berikutnya. Pengukuran bagian tanaman, rasio bentuk, dan
kelurusan tepi tetap ditampilkan sebagai keterangan pendukung.

## Model

| Komponen | Keterangan |
| :--- | :--- |
| Gerbang tanaman | MobileNetV3-Large, masukan 224 × 224, keluaran biner padi atau bukan padi |
| Model penyakit | 8 kelas: blas, bercak coklat, kresek, penggerek, penggulung, tungro, sehat, bukan padi |
| Masukan model penyakit | 256 × 256 piksel, normalisasi 0–1 |
| Penguatan prediksi | cermin ganda (test-time augmentation), peluang dirata-rata |
| Format | TensorFlow Lite, dijalankan dengan `tflite_flutter` |
| Berkas | `assets/models/sidepi_gate.tflite` (6,0 MB), `assets/models/sidepi_model.tflite` (1,9 MB) |

Model dilatih dengan TensorFlow, diekspor ke TensorFlow Lite, dan dijalankan
sepenuhnya di perangkat. Foto pengguna tidak dikirim ke server mana pun.

## Dataset

| Sumber | Jumlah | Lisensi | Pemakaian |
| :--- | ---: | :--- | :--- |
| `paddy-disease-classification` (Kaggle, cermin Hugging Face `anthony2261`) | 10.407 | CC BY 4.0 | foto lapangan, 10 kelas |
| Rice Leaf Diseases, PlantVillage, Rice Leaf Disease Image (Kaggle) | 9.228 | CC BY 4.0 dan tidak dinyatakan | foto laboratorium, kelas bukan padi |
| Roboflow Universe `utopialab/rice-leaf-wfax3` | 5.188 | CC BY 4.0 | kotak berlabel per bercak |
| Zenodo 15817084 | 1.913 | CC BY 4.0 | bahan uji tetap, tidak dipakai melatih |

Dataset gabungan diperiksa duplikatnya dengan sidik dhash 64 bit, ambang jarak
Hamming 12, karena beberapa dataset publik memuat foto yang sama dalam
resolusi berbeda.

| Perbandingan | Duplikat |
| :--- | ---: |
| Roboflow terhadap data latih | 63,4% |
| DatasetNinja terhadap data latih | 63,8% |
| GitHub `aldrin233/RiceDiseases-DataSet` | 100,0% |
| Zenodo terhadap data latih | 0,0% |

Setelah penyaringan, foto Roboflow yang benar-benar baru berjumlah 313 dan itu
yang dipakai. Dataset yang seluruh isinya duplikat tidak dipakai.

Foto acuan di dalam aplikasi berasal dari dataset lapangan di atas dan
Wikimedia Commons berlisensi bebas. Daftar per berkas, pemilik, dan lisensinya
tercatat pada `assets/acuan/sumber.txt` dan dapat dibuka dari aplikasi.

## Evaluasi

Seluruh pengujian memakai foto yang tidak dipakai saat pelatihan, dipisah per
foto sumber.

| Ujian | v0.11.0 | v0.12.0 |
| :--- | ---: | ---: |
| Pembagian internal per foto sumber | 96,3% | 98,9% |
| Zenodo, 192 foto | 91,7% | 95,8% |
| Roboflow, 31 foto baru | 48,4% | 83,9% |
| Foto lapangan berlabel, 240 foto | 12,1% | 16,7% |

Rincian Zenodo v0.12.0: blas 96,9%, bercak coklat 95,3%, kresek 82,8%.

Hasil pada foto lapangan bebas masih rendah. Seluruh dataset publik berasal dari
kolam foto yang serupa, sehingga model belum terbiasa pada latar, bayangan, dan
sudut pengambilan khas sawah Sumba. Perbaikan berikutnya membutuhkan foto
lapangan berlabel dari penyuluh setempat.

Pemisahan blas dan bercak coklat diuji ulang pada tingkat potongan bercak dengan
15.903 dan 18.233 potongan. Kedua percobaan condong ke blas (98% dan 96%)
sehingga tidak dirilis. Aplikasi menanganinya dengan pertanyaan konfirmasi,
bukan dengan menebak.

## Basis pengetahuan

`assets/basis-pengetahuan.json` memuat 20 jenis dan 42 ciri.

| Kelompok | Isi |
| :--- | :--- |
| Penyakit | blas, hawar daun bakteri, tungro, bercak daun coklat, hawar pelepah, busuk pelepah bakteri, bercak sempit daun, hawar daun bergaris bakteri, busuk batang, bakanae, kerdil hampa, kerdil rumput |
| Hama | wereng batang coklat, wereng hijau, penggerek batang, penggulung daun, walang sangit, keong mas, tikus sawah, ganjur |

Setiap jenis memuat nama ilmiah, penyebab, deskripsi, bobot ciri 1–3,
pengendalian kultur, hayati, dan kimia, serta pencegahan. Aturan penilaian:
skor 60 ke atas disertai minimal satu ciri kunci (bobot 3) diangkat sebagai
hasil utama; di bawah itu ditampilkan sebagai kemungkinan yang perlu
diverifikasi.

Berkas divalidasi setiap aplikasi dimuat. Validasi menolak id ciri ganda,
rujukan ciri yang tidak ada, bobot di luar 1–3, dan jenis tanpa ciri kunci.
Basis yang gagal validasi tidak dipakai.

Basis disusun melalui studi literatur resmi dan belum divalidasi oleh POPT.
Anjuran pengendalian kimia sengaja dibuat umum karena dosis harus mengikuti
label serta arahan penyuluh.

## Struktur proyek

```text
lib/
  model_gerbang.dart    gerbang tanaman
  model_foto.dart       model penyakit, penggabungan multi-foto
  botani.dart           segmentasi latar dan pengukuran bentuk daun
  citra.dart            ciri warna, bercak, status foto
  logika.dart           mesin penilaian sistem pakar
  konfirmasi.dart       pertanyaan konfirmasi dan hitung ulang
  periksa_foto.dart     layar periksa foto
  galeri_acuan.dart     galeri foto acuan
  main.dart             beranda, identifikasi lewat ciri, riwayat, panduan
assets/
  basis-pengetahuan.json   basis pengetahuan dan ciri
  detail_penyakit.json     penjelasan, pengendalian, pasangan mirip
  acuan.json               indeks foto acuan
  models/                  dua berkas TensorFlow Lite
  acuan/, gejala/, brand/  foto acuan, gambar gejala, aset merek
test/                     23 uji logika, citra, aset, dan konfirmasi
tools/catatan_rilis.py    penyusun catatan rilis dari CHANGELOG.md
```

## Prasyarat dan build

- Flutter 3.19 atau lebih baru (Dart SDK 3.3)
- Android SDK 36, JDK 17
- Proyek Android dibuat ulang oleh CI dari `flutter create`, lalu aset merek
  dari `android_custom/` disalin ke dalamnya

```bash
flutter pub get
flutter test
flutter build apk --release --split-per-abi
```

APK rilis dibangun oleh GitHub Actions setiap tag `v*` ditekan, lalu diterbitkan
sebagai rilis GitHub bersama catatan perubahan lengkap yang disusun dari
`CHANGELOG.md`.

## Batasan

- Hasil merupakan alat bantu identifikasi, bukan diagnosis final. Keputusan
  pengendalian tetap berada pada penyuluh.
- Ketepatan pada foto lapangan bebas masih rendah sebagaimana tabel evaluasi.
- Model foto hanya mengenali tujuh kondisi. Jenis lain pada basis pengetahuan
  dapat diakses melalui jalur identifikasi lewat ciri.
- Basis pengetahuan belum divalidasi POPT Sumba Timur.

## Lisensi

Kode aplikasi ditulis untuk Dinas Pertanian dan Pangan Kabupaten Sumba Timur dan
belum diterbitkan dengan lisensi terbuka. Data latih dan foto acuan memakai
lisensi asalnya: CC BY 4.0, CC BY-SA, CC BY, dan public domain. Rincian per
berkas tercatat pada `assets/acuan/sumber.txt`.

## Riwayat perubahan

Setiap rilis memuat ringkasan versi tersebut beserta riwayat lengkap versi
sebelumnya. Berkas sumbernya ada di [CHANGELOG.md](CHANGELOG.md).

## Pengembang

Kurniawan Arif Renggi — Program Studi Teknik Informatika, Universitas Katolik
Widya Mandala Surabaya, Kampus Waingapu.
