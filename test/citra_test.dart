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
      expect(h.ciri.valLesi, greaterThan(140), reason: '$f bercaknya pucat khas blas');
    }
  });

  test('foto bercak coklat tidak disebut blas', () {
    for (final f in ['bercak_coklat_001.jpg', 'bercak_coklat_002.jpg']) {
      final h = periksa(f);
      expect(h.kelas, 'bercak_coklat', reason: '$f seharusnya bercak coklat');
    }
  });

  test('daun sehat dikenali sehat', () {
    for (final f in ['sehat_001.jpg', 'sehat_002.jpg']) {
      final h = periksa(f);
      expect(h.kelas, 'sehat', reason: '$f seharusnya sehat');
      // daun sehat: bercak gelap, bukan bercak pucat seperti blas
      expect(h.ciri.valLesi, lessThan(120), reason: '$f bercaknya gelap');
    }
    expect(periksa('sehat_001.jpg').ciri.rasioLesi, lessThan(0.08),
        reason: 'foto sehat dengan sedikit bercak harus berasio kecil');
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

  test('foto bukan tanaman padi tidak dianalisis', () {
    final h = periksa('bukan_padi.jpg');
    expect(h.status, anyOf('bukan_padi', 'terlalu_jauh'),
        reason: 'foto kucing tidak boleh diproses sebagai penyakit padi');
    expect(h.ciri.rasioTanaman, lessThan(0.5),
        reason: 'bagian tanaman pada foto kucing sangat sedikit');
  });
}
