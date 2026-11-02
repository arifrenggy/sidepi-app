// Uji mesin analisis foto pada contoh foto nyata (hasil kalibrasi Python).
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sidepi/citra.dart';

HasilFoto periksa(String nama) =>
    periksaFotoBytes(File('test/contoh/$nama').readAsBytesSync());

void main() {
  test('foto blas dikenali sebagai indikasi blas', () {
    for (final f in ['blas_001.jpg', 'blas_002.jpg']) {
      final h = periksa(f);
      expect(h.kelas, 'blas', reason: '$f seharusnya blas');
      expect(h.ciri.rasioLesi, greaterThan(0.05), reason: '$f ada bercak berarti');
    }
  });

  test('foto bercak coklat tidak disebut blas', () {
    for (final f in ['bercak_coklat_001.jpg', 'bercak_coklat_002.jpg']) {
      final h = periksa(f);
      expect(h.kelas, 'bercak_coklat', reason: '$f seharusnya bercak coklat');
    }
  });

  test('daun sehat dikenali sehat dan bercaknya sedikit', () {
    for (final f in ['sehat_001.jpg', 'sehat_002.jpg']) {
      final h = periksa(f);
      expect(h.kelas, 'sehat', reason: '$f seharusnya sehat');
      expect(h.ciri.rasioLesi, lessThan(0.08), reason: '$f bercaknya sedikit');
    }
  });

  test('ciri yang dihitung masuk akal', () {
    final h = periksa('blas_001.jpg');
    expect(h.ciri.valLesi, inInclusiveRange(100, 255));
    expect(h.ciri.hueLesi, inInclusiveRange(10, 45));
    expect(h.ciri.pucat, inInclusiveRange(0, 1));
    expect(h.ciri.jumlahBercak, greaterThan(0));
  });

  test('berkas rusak ditolak dengan jelas', () {
    expect(() => periksaFotoBytes([1, 2, 3, 4]), throwsA(isA<FormatException>()));
  });
}
