// SIDEPI - model foto TFLite (transfer learning MobileNetV3, metode paper IJCS)
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

import 'model_gerbang.dart';

const List<String> labelModel = [
  'bercak_coklat',
  'blas',
  'bukan_padi',
  'kresek',
  'penggerek',
  'penggulung',
  'sehat',
  'tungro',
];
const Map<String, String> namaTampil = {
  'bercak_coklat': 'Bercak daun coklat',
  'blas': 'Blas',
  'bukan_padi': 'Bukan daun padi',
  'kresek': 'Kresek (hawar daun bakteri)',
  'penggerek': 'Hama penggerek batang',
  'penggulung': 'Hama putih palsu (penggulung daun)',
  'sehat': 'Daun sehat',
  'tungro': 'Tungro',
};

/// Kelas yang ditampilkan di keluaran aplikasi.
///
/// Sejak 12 November 2026 kelas `penggulung` ditutup: seluruh 455 foto latih
/// dan ujinya ternyata foto hama, bukan foto daun tergulung di sawah, sehingga
/// keluarannya tidak bisa dipercaya. Model tetap delapan kelas, peluang kelas
/// ini dibuang lalu sisanya dinormalkan ulang. Identifikasi hama putih palsu
/// sementara lewat menu Ciri.
const List<String> labelKeluaran = [
  'bercak_coklat',
  'blas',
  'bukan_padi',
  'kresek',
  'penggerek',
  'sehat',
  'tungro',
];

class HasilModel {
  final String kelas;
  final Map<String, double> peluang;
  HasilModel(this.kelas, this.peluang);
  double get teratas => peluang[kelas] ?? 0;
}

HasilModel gabungModel(List<HasilModel> daftar) {
  final jumlah = <String, double>{};
  for (final m in daftar) {
    m.peluang.forEach((k, v) => jumlah[k] = (jumlah[k] ?? 0) + v);
  }
  final rata = <String, double>{};
  jumlah.forEach((k, v) => rata[k] = v / daftar.length);
  var kelas = labelKeluaran.first;
  var tertinggi = -1.0;
  rata.forEach((k, v) {
    if (v > tertinggi) {
      tertinggi = v;
      kelas = k;
    }
  });
  return HasilModel(kelas, rata);
}

class ModelFoto {
  static const int ukuran = 256;
  Interpreter? _mesin;
  final ModelGerbang gerbang = ModelGerbang();

  Future<void> siapkan() async {
    final data = await rootBundle.load('assets/models/sidepi_model.tflite');
    _mesin = Interpreter.fromBuffer(data.buffer.asUint8List());
    // gerbang tanaman: dipakai lebih dulu untuk menolak foto bukan padi
    try {
      await gerbang.muat();
    } catch (_) {
      // bila gerbang gagal dimuat, aplikasi tetap memakai model penyakit
    }
  }

  HasilModel periksa(Uint8List bytes,
      {double porsiTanaman = 0, double rasioBentuk = 1}) {
    if (_mesin == null) throw StateError('model belum disiapkan');
    final gambar = img.decodeImage(bytes);
    if (gambar == null) throw StateError('gambar tidak terbaca');

    // Tahap 1: gerbang tanaman. Foto yang bukan daun padi ditolak di sini,
    // tidak diteruskan ke model penyakit sama sekali.
    final padi = gerbang.peluangPadi(bytes);

    // Foto jarak dekat: tanaman memenuhi bingkai dan bentuknya memanjang
    // seperti daun padi. Gerbang yang meragukan tidak boleh langsung menolak
    // foto seperti ini, karena justru inilah foto yang paling jelas.
    final dekatDanMemanjang = porsiTanaman >= 0.5 && rasioBentuk >= 2.0;
    if (padi != null && padi < ModelGerbang.ambangRagu && !dekatDanMemanjang) {
      final peluang = <String, double>{};
      for (final k in labelKeluaran) {
        peluang[k] = 0;
      }
      peluang['bukan_padi'] = 1 - padi;
      return HasilModel('bukan_padi', peluang);
    }

    final kecil = img.copyResize(gambar, width: ukuran, height: ukuran, interpolation: img.Interpolation.linear);

    final masukan = List.generate(
      1,
      (_) => List.generate(
        ukuran,
        (y) => List.generate(
          ukuran,
          (x) {
            final p = kecil.getPixel(x, y);
            return <double>[p.r / 255.0, p.g / 255.0, p.b / 255.0];
          },
        ),
      ),
    );
    final keluaran = List.generate(1, (_) => List.filled(labelModel.length, 0.0));
    _mesin!.run(masukan, keluaran);

    // cermin kiri-kanan: prediksi kedua dirata-rata supaya hasil lebih stabil
    final masukanBalik = List.generate(
      1,
      (_) => List.generate(
        ukuran,
        (y) => List.generate(ukuran, (x) => masukan[0][y][ukuran - 1 - x]),
      ),
    );
    final keluaranBalik = List.generate(1, (_) => List.filled(labelModel.length, 0.0));
    _mesin!.run(masukanBalik, keluaranBalik);

    final baris = List<double>.generate(
      labelModel.length,
      (i) => ((keluaran.first[i] as num).toDouble() + (keluaranBalik.first[i] as num).toDouble()) / 2,
    );
    final peluang = <String, double>{};
    for (var i = 0; i < labelModel.length; i++) {
      final k = labelModel[i];
      if (!labelKeluaran.contains(k)) continue;
      peluang[k] = (baris[i] as num).toDouble();
    }
    // Normalkan ulang setelah kelas yang ditutup dibuang, supaya jumlah
    // peluang yang tampil tetap seratus persen.
    final jumlahPeluang = peluang.values.fold(0.0, (a, b) => a + b);
    if (jumlahPeluang > 0) {
      for (final k in peluang.keys.toList()) {
        peluang[k] = peluang[k]! / jumlahPeluang;
      }
    }
    var kelas = labelKeluaran.first;
    var tertinggi = -1.0;
    peluang.forEach((k, v) {
      if (v > tertinggi) {
        tertinggi = v;
        kelas = k;
      }
    });

    // Tahap 2: bila gerbang ragu dan model penyakit juga tidak yakin,
    // foto ditolak daripada ditebak.
    if (padi != null &&
        padi < ModelGerbang.ambang &&
        !dekatDanMemanjang &&
        tertinggi < 0.55) {
      final ragu = <String, double>{};
      for (final k in labelKeluaran) {
        ragu[k] = 0;
      }
      ragu['bukan_padi'] = 1 - padi;
      return HasilModel('bukan_padi', ragu);
    }
    return HasilModel(kelas, peluang);
  }

  void tutup() => _mesin?.close();
}
