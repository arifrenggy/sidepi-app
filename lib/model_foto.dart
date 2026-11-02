// SIDEPI - model foto TFLite (transfer learning MobileNetV3, metode paper IJCS)
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

const List<String> labelModel = ['bercak_coklat', 'blas', 'sehat'];
const Map<String, String> namaTampil = {
  'bercak_coklat': 'Bercak daun coklat',
  'blas': 'Blas',
  'sehat': 'Daun sehat',
};

class HasilModel {
  final String kelas;
  final Map<String, double> peluang;
  HasilModel(this.kelas, this.peluang);
  double get teratas => peluang[kelas] ?? 0;
}

class ModelFoto {
  static const int ukuran = 224;
  Interpreter? _mesin;

  Future<void> siapkan() async {
    final data = await rootBundle.load('assets/models/sidepi_blas.tflite');
    _mesin = Interpreter.fromBuffer(data.buffer.asUint8List());
  }

  HasilModel periksa(Uint8List bytes) {
    if (_mesin == null) throw StateError('model belum disiapkan');
    final gambar = img.decodeImage(bytes);
    if (gambar == null) throw StateError('gambar tidak terbaca');
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

    final baris = keluaran.first;
    final peluang = <String, double>{};
    for (var i = 0; i < labelModel.length; i++) {
      peluang[labelModel[i]] = (baris[i] as num).toDouble();
    }
    var kelas = labelModel.first;
    var tertinggi = -1.0;
    peluang.forEach((k, v) {
      if (v > tertinggi) {
        tertinggi = v;
        kelas = k;
      }
    });
    return HasilModel(kelas, peluang);
  }

  void tutup() => _mesin?.close();
}
