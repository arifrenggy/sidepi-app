# SIDEPI

**Sistem Identifikasi Penyakit Padi.** Aplikasi Android untuk petugas pengamat
OPT dan penyuluh pertanian, bekerja penuh di dalam perangkat tanpa internet.

[![Rilis](https://img.shields.io/github/v/release/arifrenggy/sidepi-app?label=rilis)](https://github.com/arifrenggy/sidepi-app/releases/latest)
[![Platform](https://img.shields.io/badge/platform-Android-3ddc84)](https://github.com/arifrenggy/sidepi-app/releases/latest)
[![Versi](https://img.shields.io/badge/versi-0.13.1-1f6f43)](CHANGELOG.md)

Aplikasi ini menggabungkan dua cara identifikasi: pembacaan foto oleh model
pengenalan citra di ponsel, dan penelusuran ciri oleh sistem pakar. Keduanya
memakai satu basis pengetahuan yang sama, yaitu 20 penyakit dan hama padi
dengan 42 ciri lapangan.

---

## Alur kerja

```text
foto kamera
    |
    v
[1] gerbang tanaman      MobileNetV3-Large 224 px, biner padi / bukan padi
    |                    foto bukan padi ditolak di sini
    v
[2] potong latar         indeks kelebihan hijau + ambang Otsu
    |                    foto jauh dipotong, foto jarak dekat dibiarkan
    v
[3] model penyakit       8 kelas, masukan 256 px, cermin ganda (TTA)
    |
    v
[4] gabung banyak foto   1-3 foto, peluang digabung menjadi satu kesimpulan
    |
    v
[5] sistem pakar         pembobotan ciri 1-3, satu ciri kunci wajib
                         pertanyaan konfirmasi bila model ragu 55-80%
```

Jalur kedua, **identifikasi lewat ciri**, tidak memakai kamera: petugas memilih
bagian tanaman, mencentang ciri yang benar-benar terlihat, lalu mesin penilaian
menghitung kecocokan tiap jenis pada basis pengetahuan. Aturan penilaian: skor
60 ke atas dengan minimal satu ciri kunci (bobot 3) baru diangkat sebagai hasil
utama, selain itu muncul sebagai kemungkinan yang perlu diverifikasi.

## Model

| Bagian | Keterangan |
| :--- | :--- |
| Gerbang tanaman | MobileNetV3-Large, 224 px, biner |
| Model penyakit | 8 kelas: blas, bercak coklat, kresek, penggerek, penggulung, tungro, sehat, bukan padi |
| Masukan | 256 x 256, normalisasi 0-1 |
| Penguatan | cermin ganda saat prediksi, hasil dirata-rata |
| Berkas | `assets/models/sidepi_gate.tflite`, `assets/models/sidepi_model.tflite` |
| Ukuran total | 7,9 MB (gerbang 6,0 MB, penyakit 1,9 MB) |

Model dilatih dengan TensorFlow, diekspor ke TensorFlow Lite, lalu dijalankan
di perangkat lewat `tflite_flutter`. Tidak ada foto yang dikirim ke server.

## Data

| Sumber | Jumlah | Lisensi | Dipakai untuk |
| :--- | ---: | :--- | :--- |
| paddy-disease-classification (Kaggle, cermin Hugging Face) | 10.407 | CC BY 4.0 | foto lapangan 10 kelas |
| Rice Leaf Diseases, PlantVillage, Rice Leaf Disease Image | 9.228 | campuran | foto laboratorium dan kelas bukan padi |
| Roboflow `rice-leaf-wfax3` | 5.188 | CC BY 4.0 | kotak berlabel per bercak |
| Zenodo 15817084 | 1.913 | CC BY 4.0 | bahan uji tetap, tidak dipakai melatih |

Duplikat antar dataset dibuang dengan sidik dhash 64 bit, ambang jarak Hamming
12. Hasil pemeriksaan: Roboflow 63,4% duplikat, DatasetNinja 63,8%, GitHub
aldrin 100%, Zenodo 0%. Setelah dibersihkan, foto Roboflow yang benar-benar baru
hanya 313 dan itu yang dipakai.

Foto acuan di dalam aplikasi memakai dataset lapangan di atas dan beberapa foto
Wikimedia Commons berlisensi bebas. Daftar lengkapnya ada di
`assets/acuan/sumber.txt` dan bisa dibuka dari dalam aplikasi.

## Hasil uji

Semua angka diukur pada foto yang tidak dipakai saat melatih.

| Ujian | v0.11.0 | v0.12.0 |
| :--- | ---: | ---: |
| Pembagian internal per foto sumber | 96,3% | 98,9% |
| Zenodo test, 192 foto | 91,7% | 95,8% |
| Roboflow test, 31 foto baru | 48,4% | 83,9% |
| Foto lapangan berlabel, 240 foto | 12,1% | 16,7% |

Angka terakhir yang paling penting dan paling rendah. Seluruh dataset publik
berasal dari kolam foto yang mirip, sehingga model masih lemah pada foto sawah
Sumba yang bercampur latar, bayangan, dan sudut pengambilan bebas. Perbaikan
berikutnya butuh foto lapangan berlabel dari penyuluh setempat.

Pemisahan blas dan bercak coklat juga diuji pada tingkat potongan bercak, dan
hasilnya bias ke blas meski data latihnya puluhan ribu. Karena itu aplikasi tidak
memaksa menebak: bila dua kandidat teratas adalah pasangan yang dikenal mirip,
pertanyaan konfirmasi selalu muncul.

## Basis pengetahuan

`assets/basis-pengetahuan.json` memuat 20 jenis dan 42 ciri.

```text
Penyakit   blas, hawar daun bakteri, tungro, bercak daun coklat, hawar pelepah,
           busuk pelepah bakteri, bercak sempit daun, hawar daun bergaris,
           busuk batang, bakanae, kerdil hampa, kerdil rumput
Hama       wereng batang coklat, wereng hijau, penggerek batang, penggulung daun,
           walang sangit, keong mas, tikus sawah, ganjur
```

Setiap jenis memuat nama ilmiah, penyebab, deskripsi, bobot ciri 1-3, pengendalian
kultur, hayati, dan kimia, serta pencegahan. Berkas divalidasi saat aplikasi
dimuat: id ciri harus unik, rujukan ciri harus ada, bobot 1-3, dan tiap jenis
wajib punya minimal satu ciri kunci. Basis yang gagal validasi tidak dipakai.

Basis ini disusun dari literature study resmi dan belum divalidasi penyuluh atau
POPT Sumba Timur.

## Struktur

```text
lib/
  model_gerbang.dart   gerbang tanaman
  model_foto.dart      model penyakit dan penggabungan banyak foto
  botani.dart          pemotongan latar dan pengukuran bentuk daun
  citra.dart           ciri warna, bercak, dan penentuan status foto
  logika.dart          mesin penilaian sistem pakar
  konfirmasi.dart      pertanyaan konfirmasi dan hitung ulang
  periksa_foto.dart    layar periksa foto
  galeri_acuan.dart    galeri foto acuan
  main.dart            beranda, identifikasi lewat ciri, riwayat, panduan
assets/
  basis-pengetahuan.json, detail_penyakit.json, acuan.json
  models/, acuan/, gejala/, brand/
test/                  23 uji logika, citra, aset, dan konfirmasi
tools/catatan_rilis.py penyusun catatan rilis dari CHANGELOG.md
```

## Membangun

```bash
flutter pub get
flutter test
flutter build apk --release --split-per-abi
```

APK rilis dibangun otomatis oleh GitHub Actions setiap tag `v*` ditekan, lalu
diterbitkan sebagai rilis GitHub bersama catatan perubahan lengkap.

## Batasan

- Alat bantu identifikasi, bukan diagnosis final. Keputusan pengendalian tetap
  lewat penyuluh.
- Ketepatan pada foto lapangan bebas masih rendah, lihat tabel hasil uji.
- Basis pengetahuan belum divalidasi POPT, dan anjuran kimia sengaja dibuat umum
  karena dosis harus mengikuti label serta arahan penyuluh.
- Model hanya mengenali 7 kondisi pada foto. Jenis lain di basis pengetahuan
  hanya bisa diakses lewat jalur ciri.

## Lisensi dan kredit

Kode aplikasi ditulis untuk Dinas Pertanian dan Pangan Kabupaten Sumba Timur.
Dataset dan foto acuan memakai lisensi CC BY 4.0, CC BY-SA, CC BY, dan public
domain sesuai keterangan pada `assets/acuan/sumber.txt`. Riwayat perubahan tiap
versi ada di [CHANGELOG.md](CHANGELOG.md).
