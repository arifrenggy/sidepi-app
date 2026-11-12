# Catatan perubahan SIDEPI

Setiap rilis GitHub memuat seluruh riwayat perubahan di bawah ini, supaya
pengguna yang baru memasang aplikasi tetap tahu apa saja yang sudah berubah
sejak versi pertama.

## v0.13.2

- Kelas hama putih palsu (penggulung daun) ditutup pada keluaran model. Seluruh
  455 foto latih dan ujinya ternyata foto hama, bukan foto daun tergulung di
  sawah, sehingga keluarannya tidak bisa dipercaya. Model tetap delapan kelas,
  peluang kelas itu dibuang lalu sisanya dinormalkan ulang agar angka yang
  tampil tetap seratus persen. Identifikasi hama putih palsu sementara lewat
  menu Ciri.
- Enam foto acuan kelas penggulung dicabut dari galeri contoh gejala. Setelah
  diperiksa, keenamnya foto ngengat, bukan gejala daun, sehingga justru
  menyesatkan petugas yang membandingkan.
- Catatan sumber foto acuan diperbarui: alasan pencabutan dan rencana
  penggantian dengan foto daun tergulung hasil pengambilan di sawah.
- Ketepatan diagnosis kelas lain tidak berubah. Pada foto lapangan yang diuji
  ulang, peluang tungro bergeser dari 83 menjadi 85 persen karena peluang kelas
  yang ditutup dibuang, bukan karena model dinilai ulang.

## v0.13.1

- Foto acuan lapangan diganti dengan foto resolusi lebih tinggi: dari 256-300
  piksel menjadi 480-900 piksel, diambil dari dataset lapangan berlabel dan
  Wikimedia Commons berlisensi bebas.
- Catatan sumber dan lisensi foto ditambahkan di aplikasi, bisa dibuka dari
  galeri contoh gejala.
- Bug ketuk untuk memperbesar diperbaiki: galeri sekarang dibuka tepat pada foto
  yang diketuk dan gambar mengisi layar, tidak lagi berupa halaman putih kosong.
- Foto gejala penggulung daun (hama putih palsu) berupa daun terlipat berwarna
  putih ditambahkan ke galeri.
- README ditulis ulang: alur kerja, model, data, hasil uji, dan basis
  pengetahuan. Bagian yang tidak penting dihapus.

## v0.13.0

- Bagian "Konfirmasi ciri di lapangan" dihapus dari layar hasil.
- Basis pengetahuan diperluas menjadi 20 jenis penyakit dan hama dengan 42 ciri,
  lengkap dengan nama ilmiah, penyebab, pengendalian, dan pencegahan.
- Kelompok ciri baru "Batang" agar gejala penggerek dan busuk batang tidak
  tercampur dengan pelepah.

## v0.12.0

- Model penyakit dilatih ulang memakai kotak berlabel Roboflow dan data Zenodo.
  Ketepatan pada data uji Zenodo 95,8% dan pada data uji Roboflow 83,9%.
- Duplikat foto antar dataset dibersihkan sebelum pelatihan.

## v0.11.0

- Rasio daun dihitung dari kotak bagian hijau, bukan dari bingkai foto.
- Ambang bercak pucat disesuaikan agar bercak kecil tetap terdeteksi.
- Pertanyaan konfirmasi selalu muncul untuk pasangan penyakit yang sering
  tertukar, dan hasil menampilkan banding dua foto acuan.

## v0.10.0

- Hasil model disambungkan ke sistem pakar memakai Certainty Factor.
- Pertanyaan konfirmasi muncul saat model ragu pada rentang 55-80%.

## v0.9.1

- Gerbang tanaman dilatih ulang dengan 5.250 foto daun jarak dekat. Foto jarak
  dekat tidak lagi dipotong latarnya.

## v0.9.0

- Alur dua tahap: gerbang tanaman MobileNetV3-Large, lalu pemotongan latar
  otomatis dan pengukuran bentuk daun yang ditampilkan di hasil.

## v0.8.0

- Model delapan kelas berukuran masukan 256 piksel. Blas 95% pada data uji,
  penolakan foto bukan padi 98%.

## v0.7.2

- Nama dan ikon bagian tanaman disesuaikan dengan kolom kelompok pada basis
  pengetahuan.

## v0.7.1

- Perbaikan galeri kosong: subfolder foto acuan didaftarkan sebagai aset,
  ditambah cadangan gambar dan uji aset.

## v0.7.0

- Tampilan baru dengan sistem desain Inter, layar muat bermerek, logo aplikasi,
  ikon peluncur, dan kartu hasil yang dirapikan.
- README ditulis ulang: arsitektur, fitur, tabel akurasi, panduan pasang,
  batasan, dan peta jalan.

## v0.6.0

- Galeri foto acuan berisi enam foto tiap penyakit, tersedia di hasil foto,
  hasil checklist, dan beranda.

## v0.5.0

- Model tujuh kelas dengan pengujian perbesaran ganda, ketepatan 97,1%.
- Periksa banyak foto: hasil beberapa foto digabung menjadi satu kesimpulan.

## v0.3.1

- Model lima kelas dari dataset Kaggle, ketepatan 92,3% pada data uji.
- Gerbang menolak foto bukan padi sebelum analisis.
- Layar hasil memuat gambar gejala, deskripsi, kemungkinan lain, dan
  rekomendasi pengendalian.
- APK universal dan arm64, CI menerbitkan rilis GitHub otomatis.

## v0.1.0

- Rilis pertama aplikasi Flutter: logika sesuai PRD, delapan layar, validasi
  basis pengetahuan, uji unit, dan CI yang membangun APK.
