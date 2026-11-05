// Uji jembatan model foto dengan sistem pakar.
import 'package:flutter_test/flutter_test.dart';
import 'package:sidepi/konfirmasi.dart';

void main() {
  final detail = <String, dynamic>{
    'blas': {
      'gejala': [
        'Bercak berbentuk belah ketupat atau jorong',
        'Pusat bercak abu-abu dengan tepi coklat',
        'Leher malai menghitam lalu patah',
      ],
    },
    'tungro': {
      'gejala': [
        'Daun menguning mulai dari ujung',
        'Tanaman kerdil dan anakan sedikit',
      ],
    },
    'sehat': {
      'gejala': ['Daun hijau merata tanpa bercak'],
    },
  };

  test('pertanyaan diambil dari kedua kandidat dan bobot khas lebih tinggi', () {
    final t = susunPertanyaan(detail, 'blas', 'tungro');
    expect(t, isNotEmpty);
    expect(t.length, lessThanOrEqualTo(3));
    expect(t.any((x) => x.kelas == 'blas'), isTrue);
    expect(t.first.bobot, 2);
  });

  test('belum dijawab berarti belum ada kesimpulan', () {
    final t = susunPertanyaan(detail, 'blas', 'tungro');
    final hasil = hitungUlang(
      peluang: {'blas': 0.62, 'tungro': 0.31, 'sehat': 0.07},
      tanya: t,
      jawaban: List<bool?>.filled(t.length, null),
      sebelumnya: 'blas',
    );
    expect(hasil, isNull);
  });

  test('jawaban gejala menggeser kesimpulan ke kandidat kedua', () {
    final t = susunPertanyaan(detail, 'blas', 'tungro');
    // jawab ya hanya untuk gejala milik tungro
    final jawaban = List<bool?>.generate(t.length, (i) => t[i].kelas == 'tungro');
    final hasil = hitungUlang(
      peluang: {'blas': 0.58, 'tungro': 0.27, 'sehat': 0.15},
      tanya: t,
      jawaban: jawaban,
      sebelumnya: 'blas',
    );
    expect(hasil, isNotNull);
    expect(hasil!.kelas, 'tungro');
    expect(hasil.berubah, isTrue);
  });

  test('jawaban yang cocok dengan model memperkuat kesimpulan semula', () {
    final t = susunPertanyaan(detail, 'blas', 'tungro');
    final jawaban = List<bool?>.generate(t.length, (i) => t[i].kelas == 'blas');
    final hasil = hitungUlang(
      peluang: {'blas': 0.58, 'tungro': 0.27, 'sehat': 0.15},
      tanya: t,
      jawaban: jawaban,
      sebelumnya: 'blas',
    );
    expect(hasil!.kelas, 'blas');
    expect(hasil.berubah, isFalse);
    expect(hasil.skor, greaterThan(0.5));
  });
}
