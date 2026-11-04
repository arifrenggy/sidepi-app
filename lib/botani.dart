// Pemotongan otomatis: memisahkan tanaman dari latar belakang foto.
//
// Cara kerja:
// 1. Tiap piksel dinilai dengan indeks kelebihan hijau (ExG = 2G - R - B),
//    cara yang lazim dipakai pada citra pertanian untuk memisahkan vegetasi
//    dari tanah, langit, tangan, dan meja.
// 2. Ambang dipilih otomatis dengan metode Otsu, bukan angka tetap, supaya
//    tetap bekerja pada foto gelap maupun terang.
// 3. Bagian hijau terbesar dipertahankan, bercak kecil dibuang.
// 4. Kotak pembatas bagian itu dipotong dengan sedikit ruang, lalu dipakai
//    untuk semua tahap berikutnya. Latar tidak ikut dinilai.
//
// Sekaligus dihitung tiga ukuran yang dipakai sebagai penyaring tambahan:
// porsi bingkai (perkiraan jarak kamera), rasio bentuk, dan kelurusan tepi.
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

class HasilPotong {
  /// Foto yang sudah dipotong, siap dinilai model.
  final Uint8List bytes;

  /// Bagian bingkai yang ditempati tanaman (0..1). Kecil berarti terlalu jauh.
  final double porsiBingkai;

  /// Perbandingan sisi panjang dan pendek kotak tanaman.
  final double rasioBentuk;

  /// Kerapian tepi kiri dan kanan (0..1). Daun padi bertepi hampir lurus.
  final double kelurusanTepi;

  const HasilPotong({
    required this.bytes,
    required this.porsiBingkai,
    required this.rasioBentuk,
    required this.kelurusanTepi,
  });

  /// Perkiraan kasar jarak kamera, dipakai untuk saran ke petugas.
  String get saranJarak {
    if (porsiBingkai < 0.18) return 'Terlalu jauh, dekatkan kamera sampai daun memenuhi layar.';
    if (porsiBingkai > 0.92) return 'Terlalu dekat, jauhkan sedikit agar bentuk daun terlihat.';
    return 'Jarak foto sudah baik.';
  }
}

/// Memotong foto sehingga hanya bagian tanaman yang tersisa.
HasilPotong potongTanaman(Uint8List bytes) {
  final asli = img.decodeImage(bytes);
  if (asli == null) {
    return HasilPotong(
      bytes: bytes,
      porsiBingkai: 0,
      rasioBentuk: 1,
      kelurusanTepi: 0,
    );
  }

  // perkecil supaya cepat, sisi terpanjang 480 piksel
  final sisi = math.max(asli.width, asli.height);
  final skala = sisi > 480 ? 480 / sisi : 1.0;
  final kecil = skala < 1
      ? img.copyResize(asli,
          width: (asli.width * skala).round(),
          height: (asli.height * skala).round(),
          interpolation: img.Interpolation.average)
      : asli;

  final w = kecil.width, h = kecil.height;
  final n = w * h;

  // 1. indeks kelebihan hijau, dipetakan ke 0..255
  final nilai = Uint8List(n);
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final p = kecil.getPixel(x, y);
      final exg = 2 * p.g - p.r - p.b; // rentang -510..510
      nilai[y * w + x] = ((exg + 510) / 1020 * 255).round().clamp(0, 255);
    }
  }

  // 2. ambang Otsu
  final hist = List<int>.filled(256, 0);
  for (var i = 0; i < n; i++) {
    hist[nilai[i]]++;
  }
  final ambang = _otsu(hist, n);

  final mask = Uint8List(n);
  for (var i = 0; i < n; i++) {
    mask[i] = nilai[i] > ambang ? 1 : 0;
  }

  // 3. bagian hijau terbesar
  final kotak = _komponenTerbesar(mask, w, h);
  if (kotak == null) {
    return HasilPotong(
      bytes: bytes,
      porsiBingkai: 0,
      rasioBentuk: 1,
      kelurusanTepi: 0,
    );
  }

  // 4. potong dengan sedikit ruang
  final padX = (kotak.lebar * 0.06).round();
  final padY = (kotak.tinggi * 0.06).round();
  final kiri = (kotak.kiri - padX).clamp(0, w - 1);
  final atas = (kotak.atas - padY).clamp(0, h - 1);
  final kanan = (kotak.kanan + padX).clamp(kiri + 8, w - 1);
  final bawah = (kotak.bawah + padY).clamp(atas + 8, h - 1);

  final potong = img.copyCrop(kecil,
      x: kiri, y: atas, width: kanan - kiri + 1, height: bawah - atas + 1);

  final luasBingkai = (kanan - kiri + 1) * (bawah - atas + 1);
  final porsi = luasBingkai / n;
  final rasio = math.max(potong.width, potong.height) /
      math.max(1, math.min(potong.width, potong.height));
  final lurus = _kelurusan(mask, w, kotak);

  return HasilPotong(
    bytes: Uint8List.fromList(img.encodeJpg(potong, quality: 92)),
    porsiBingkai: porsi,
    rasioBentuk: rasio,
    kelurusanTepi: lurus,
  );
}

int _otsu(List<int> hist, int total) {
  var jumlah = 0.0, bobotLatar = 0.0, momenLatar = 0.0;
  for (var i = 0; i < 256; i++) {
    jumlah += i * hist[i];
  }
  var terbaik = 0.0, ambang = 128;
  for (var t = 0; t < 256; t++) {
    bobotLatar += hist[t];
    if (bobotLatar == 0) continue;
    final bobotDepan = total - bobotLatar;
    if (bobotDepan == 0) break;
    momenLatar += t * hist[t];
    final rataLatar = momenLatar / bobotLatar;
    final rataDepan = (jumlah - momenLatar) / bobotDepan;
    final beda = rataLatar - rataDepan;
    final variansi = bobotLatar * bobotDepan * beda * beda;
    if (variansi > terbaik) {
      terbaik = variansi;
      ambang = t;
    }
  }
  return ambang;
}

class _Kotak {
  final int kiri, atas, kanan, bawah;
  const _Kotak(this.kiri, this.atas, this.kanan, this.bawah);
  int get lebar => kanan - kiri + 1;
  int get tinggi => bawah - atas + 1;
}

/// Menelusuri bagian hijau paling luas dan mengembalikan kotak pembatasnya.
_Kotak? _komponenTerbesar(Uint8List mask, int w, int h) {
  final dikunjungi = Uint8List(w * h);
  var terbaikLuas = 0;
  _Kotak? terbaik;
  final tumpukan = Int32List(w * h);

  for (var awal = 0; awal < mask.length; awal++) {
    if (mask[awal] == 0 || dikunjungi[awal] == 1) continue;
    var atas = tumpukan.length;
    tumpukan[--atas] = awal;
    dikunjungi[awal] = 1;
    var luas = 0;
    var kiri = w, kanan = 0, atasK = h, bawahK = 0;
    while (atas < tumpukan.length) {
      final i = tumpukan[atas++];
      luas++;
      final x = i % w, y = i ~/ w;
      if (x < kiri) kiri = x;
      if (x > kanan) kanan = x;
      if (y < atasK) atasK = y;
      if (y > bawahK) bawahK = y;
      // empat tetangga
      if (x > 0) {
        final j = i - 1;
        if (mask[j] == 1 && dikunjungi[j] == 0) {
          dikunjungi[j] = 1;
          tumpukan[--atas] = j;
        }
      }
      if (x < w - 1) {
        final j = i + 1;
        if (mask[j] == 1 && dikunjungi[j] == 0) {
          dikunjungi[j] = 1;
          tumpukan[--atas] = j;
        }
      }
      if (y > 0) {
        final j = i - w;
        if (mask[j] == 1 && dikunjungi[j] == 0) {
          dikunjungi[j] = 1;
          tumpukan[--atas] = j;
        }
      }
      if (y < h - 1) {
        final j = i + w;
        if (mask[j] == 1 && dikunjungi[j] == 0) {
          dikunjungi[j] = 1;
          tumpukan[--atas] = j;
        }
      }
    }
    if (luas > terbaikLuas) {
      terbaikLuas = luas;
      terbaik = _Kotak(kiri, atasK, kanan, bawahK);
    }
  }
  return terbaik;
}

/// Mengukur kelurusan tepi kiri-kanan bagian tanaman (0..1).
double _kelurusan(Uint8List mask, int w, _Kotak kotak) {
  final kiri = <double>[], kanan = <double>[];
  final langkah = math.max(1, kotak.tinggi ~/ 40);
  for (var y = kotak.atas; y <= kotak.bawah; y += langkah) {
    var xk = -1, xn = -1;
    for (var x = kotak.kiri; x <= kotak.kanan; x++) {
      if (mask[y * w + x] == 1) {
        if (xk < 0) xk = x;
        xn = x;
      }
    }
    if (xk >= 0 && xn > xk) {
      kiri.add(xk.toDouble());
      kanan.add(xn.toDouble());
    }
  }
  if (kiri.length < 6) return 0;
  return (_r2(kiri) + _r2(kanan)) / 2;
}

double _r2(List<double> v) {
  final n = v.length;
  var sx = 0.0, sy = 0.0, sxy = 0.0, sxx = 0.0;
  for (var i = 0; i < n; i++) {
    sx += i;
    sy += v[i];
    sxy += i * v[i];
    sxx += i * i;
  }
  final b = (n * sxy - sx * sy) / (n * sxx - sx * sx);
  final a = (sy - b * sx) / n;
  var ss = 0.0, total = 0.0;
  final rata = sy / n;
  for (var i = 0; i < n; i++) {
    final pr = a + b * i;
    ss += (v[i] - pr) * (v[i] - pr);
    total += (v[i] - rata) * (v[i] - rata);
  }
  return total <= 0 ? 0 : (1 - ss / total).clamp(0.0, 1.0);
}
