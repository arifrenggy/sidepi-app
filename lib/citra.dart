// SIDEPI - analisis foto di perangkat (pengolahan citra klasik).
import 'dart:typed_data';
// Port dari skrip kalibrasi Python; ambang dan aturan identik.
import 'package:image/image.dart' as img;

class CiriFoto {
  final double cakupan;
  final double rasioTanaman;
  final double rasioLesi;
  final double valLesi;
  final double satLesi;
  final double hueLesi;
  final double pucat;
  final int jumlahBercak;

  CiriFoto(this.cakupan, this.rasioTanaman, this.rasioLesi, this.valLesi, this.satLesi,
      this.hueLesi, this.pucat, this.jumlahBercak);

  Map<String, double> get peta => {
        'rasio_lesi': rasioLesi,
        'val_lesi': valLesi,
        'sat_lesi': satLesi,
        'hue_lesi': hueLesi,
        'pucat': pucat,
      };
}

class HasilFoto {
  final CiriFoto ciri;
  final String kelas;
  final double yakin;

  HasilFoto(this.ciri, this.kelas, this.yakin);

  String get nama => kelas == 'blas'
      ? 'Blas'
      : kelas == 'bercak_coklat'
          ? 'Bercak daun coklat'
          : 'Daun sehat';

  String get status {
    if (ciri.cakupan < 0.12) return 'bukan_padi';
    if (ciri.rasioTanaman < 0.25) return 'bukan_padi';
    if (ciri.rasioTanaman < 0.45) return 'terlalu_jauh';
    if (ciri.rasioLesi < 0.05) return 'sehat';
    if (yakin < 0.7) return 'belum_pasti';
    if (kelas == 'sehat') return 'sehat';
    return 'ada_indikasi';
  }
}

// Pohon keputusan hasil latihan pada 129 foto (akurasi validasi silang 72,9%).
const Map<String, dynamic> _pohon = {
  'fitur': 'val_lesi',
  'ambang': 82.5,
  'kiri':     {
      'fitur': 'val_lesi',
      'ambang': 37.5,
      'kiri':         {'kelas': 'sehat', 'yakin': 0.7143},
      'kanan':         {'kelas': 'sehat', 'yakin': 1.0},
    },
  'kanan':     {
      'fitur': 'hue_lesi',
      'ambang': 29.5,
      'kiri':         {
          'fitur': 'val_lesi',
          'ambang': 147.0,
          'kiri':             {
              'fitur': 'val_lesi',
              'ambang': 125.0,
              'kiri':                 {'kelas': 'blas', 'yakin': 1.0},
              'kanan':                 {'kelas': 'bercak_coklat', 'yakin': 0.5833},
            },
          'kanan':             {
              'fitur': 'pucat',
              'ambang': 0.0274,
              'kiri':                 {'kelas': 'blas', 'yakin': 1.0},
              'kanan':                 {'kelas': 'blas', 'yakin': 0.8889},
            },
        },
      'kanan':         {
          'fitur': 'pucat',
          'ambang': 0.0186,
          'kiri':             {
              'fitur': 'pucat',
              'ambang': 0.0036,
              'kiri':                 {'kelas': 'bercak_coklat', 'yakin': 0.5},
              'kanan':                 {'kelas': 'blas', 'yakin': 0.8889},
            },
          'kanan':             {
              'fitur': 'rasio_lesi',
              'ambang': 0.0273,
              'kiri':                 {'kelas': 'sehat', 'yakin': 0.5714},
              'kanan':                 {'kelas': 'bercak_coklat', 'yakin': 0.7368},
            },
        },
    },
};

Map<String, dynamic> jalankanPohon(Map<String, double> ciri) {
  var s = _pohon;
  while (s['kelas'] == null) {
    final v = ciri[s['fitur'] as String] ?? 0;
    s = (v <= (s['ambang'] as num)) ? s['kiri'] : s['kanan'];
  }
  return {'kelas': s['kelas'], 'yakin': s['yakin']};
}

List<double> _rgbKeHsv(int r, int g, int b) {
  final rd = r / 255.0, gd = g / 255.0, bd = b / 255.0;
  final max = [rd, gd, bd].reduce((a, c) => a > c ? a : c);
  final min = [rd, gd, bd].reduce((a, c) => a < c ? a : c);
  final d = max - min;
  double h = 0;
  if (d != 0) {
    if (max == rd) {
      h = 60 * (((gd - bd) / d) % 6);
    } else if (max == gd) {
      h = 60 * ((bd - rd) / d + 2);
    } else {
      h = 60 * ((rd - gd) / d + 4);
    }
  }
  if (h < 0) h += 360;
  final s = max == 0 ? 0.0 : d / max;
  return [h / 2, s * 255, max * 255];
}

double _median(List<double> a) {
  if (a.isEmpty) return 0;
  final b = List<double>.from(a)..sort();
  return b[b.length ~/ 2];
}

int _hitungBercak(List<bool> mask, int w, int h, int ambangLuas) {
  final terlihat = List<bool>.filled(mask.length, false);
  var jumlah = 0;
  for (var s = 0; s < mask.length; s++) {
    if (!mask[s] || terlihat[s]) continue;
    var luas = 0;
    final tumpuk = <int>[s];
    terlihat[s] = true;
    while (tumpuk.isNotEmpty) {
      final p = tumpuk.removeLast();
      luas++;
      final px = p % w, py = p ~/ w;
      for (var dy = -1; dy <= 1; dy++) {
        for (var dx = -1; dx <= 1; dx++) {
          final nx = px + dx, ny = py + dy;
          if (nx < 0 || ny < 0 || nx >= w || ny >= h) continue;
          final n = ny * w + nx;
          if (mask[n] && !terlihat[n]) {
            terlihat[n] = true;
            tumpuk.add(n);
          }
        }
      }
    }
    if (luas >= ambangLuas) jumlah++;
  }
  return jumlah;
}

CiriFoto analisaPiksel(img.Image gambar) {
  final w = gambar.width, h = gambar.height;
  final mask = List<bool>.filled(w * h, false);
  var totalDaun = 0, totalLesi = 0, totalPucat = 0, totalTanaman = 0;
  final hueLesi = <double>[], valLesi = <double>[], satLesi = <double>[];

  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final p = gambar.getPixel(x, y);
      final hsv = _rgbKeHsv(p.r.toInt(), p.g.toInt(), p.b.toInt());
      final H = hsv[0], S = hsv[1], V = hsv[2];
      final latar = (V > 232 && S < 30) || V < 26;
      if (latar) continue;
      final hijau = H >= 35 && H <= 95 && S > 45 && V > 45;
      final warnaTanaman = H >= 20 && H <= 100 && S > 50 && V > 35;
      if (warnaTanaman) totalTanaman++;
      totalDaun++;
      if (!hijau && S > 55 && V > 35) {
        mask[y * w + x] = true;
        totalLesi++;
        hueLesi.add(H);
        valLesi.add(V);
        satLesi.add(S);
        if (V > 150 && S < 120) totalPucat++;
      }
    }
  }

  return CiriFoto(
    totalDaun / (w * h),
    totalDaun == 0 ? 0 : totalTanaman / totalDaun,
    totalDaun == 0 ? 0 : totalLesi / totalDaun,
    _median(valLesi),
    _median(satLesi),
    _median(hueLesi),
    totalLesi == 0 ? 0 : totalPucat / totalLesi,
    _hitungBercak(mask, w, h, 12),
  );
}

HasilFoto periksaFotoBytes(List<int> bytes) {
  final asli = img.decodeImage(Uint8List.fromList(bytes));
  if (asli == null) throw const FormatException('Foto tidak dapat dibaca');
  final skala = asli.width >= asli.height ? 480 / asli.width : 480 / asli.height;
  final kecil = skala < 1
      ? img.copyResize(asli,
          width: (asli.width * skala).round(), height: (asli.height * skala).round())
      : asli;
  final ciri = analisaPiksel(kecil);
  final hasil = jalankanPohon(ciri.peta);
  return HasilFoto(ciri, hasil['kelas'] as String, (hasil['yakin'] as num).toDouble());
}
