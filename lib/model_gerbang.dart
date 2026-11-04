// Gerbang tanaman: memastikan foto benar-benar daun padi sebelum dinilai penyakitnya.
// Model biner MobileNetV3-Large (224x224) yang dilatih membedakan padi dari
// 38 jenis tanaman lain, gulma sawah, dan daun teh.
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class ModelGerbang {
  static const int ukuran = 224;

  /// Ambang peluang padi. Di bawah nilai ini foto dianggap bukan tanaman padi.
  /// Nilai diambil dari pengujian pada spesies tanaman yang tidak pernah
  /// dilihat model saat latihan.
  static const double ambang = 0.60;

  /// Di antara ambang dan nilai ini, foto dianggap meragukan: model penyakit
  /// tetap dijalankan, tetapi hasilnya harus meyakinkan untuk dipakai.
  static const double ambangRagu = 0.42;

  Interpreter? _mesin;

  bool get siap => _mesin != null;

  Future<void> muat() async {
    final data = await rootBundle.load('assets/models/sidepi_gate.tflite');
    _mesin = Interpreter.fromBuffer(data.buffer.asUint8List());
  }

  /// Peluang foto ini daun padi (0..1). Mengembalikan null bila model belum siap.
  double? peluangPadi(Uint8List bytes) {
    if (_mesin == null) return null;
    final gambar = img.decodeImage(bytes);
    if (gambar == null) return null;

    final kecil = img.copyResize(gambar,
        width: ukuran, height: ukuran, interpolation: img.Interpolation.linear);
    final masukan = List.generate(
      1,
      (_) => List.generate(
        ukuran,
        (y) => List.generate(ukuran, (x) {
          final p = kecil.getPixel(x, y);
          // MobileNetV3 dilatih dengan skala -1..1
          return [p.r / 127.5 - 1, p.g / 127.5 - 1, p.b / 127.5 - 1];
        }),
      ),
    );
    final keluaran = List.generate(1, (_) => List.filled(2, 0.0));
    _mesin!.run(masukan, keluaran);

    // gabungkan foto asli dan cermin supaya penilaian lebih stabil
    final masukanBalik = List.generate(
      1,
      (_) => List.generate(
        ukuran,
        (y) => List.generate(ukuran, (x) => masukan[0][y][ukuran - 1 - x]),
      ),
    );
    final keluaranBalik = List.generate(1, (_) => List.filled(2, 0.0));
    _mesin!.run(masukanBalik, keluaranBalik);

    final padi = ((keluaran.first[1] as num).toDouble() +
            (keluaranBalik.first[1] as num).toDouble()) /
        2;
    return padi;
  }
}
