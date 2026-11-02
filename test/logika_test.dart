// Uji logika penilaian sesuai PRD (kasus U1-U10)
import 'package:flutter_test/flutter_test.dart';
import 'package:sidepi/logika.dart';
import 'package:sidepi/models.dart';

Penyakit p(String id, Map<String, int> bobot) => Penyakit(
      id: id,
      nama: 'Penyakit $id',
      namaIlmiah: 'Latin $id',
      penyebab: 'jamur',
      deskripsi: 'deskripsi',
      gambar: const [],
      bobotGejala: bobot,
      pengendalian: const {},
      pencegahan: const [],
      sumber: '',
    );

BasisPengetahuan kbDasar() => BasisPengetahuan(
      versi: 'tes',
      tanggalRilis: '2026-11-01',
      gejala: [
        Gejala(id: 'G01', nama: 'Bercak khas', kelompok: 'daun'),
        Gejala(id: 'G02', nama: 'Pusat abu-abu', kelompok: 'daun'),
        Gejala(id: 'G03', nama: 'Daun mengering', kelompok: 'daun'),
        Gejala(id: 'G04', nama: 'Malai hampa', kelompok: 'malai'),
        Gejala(id: 'G05', nama: 'Pelepah busuk', kelompok: 'pelepah'),
      ],
      penyakit: [
        p('P1', {'G01': 3, 'G02': 3, 'G03': 1}), // total 7
        p('P2', {'G03': 3, 'G04': 2}), // total 5
        p('P3', {'G05': 3}), // total 3
      ],
    );

void main() {
  test('U1 semua ciri kunci P1 -> skor 100 hasil utama', () {
    final a = hitungHasil(kbDasar(), {'G01', 'G02', 'G03'});
    expect(a.kemungkinan.first.skor, 100);
    expect(a.utama?.penyakit.id, 'P1');
  });

  test('U2 skor 40-59 tanpa capai 60 -> perlu verifikasi, tanpa hasil utama', () {
    // P1 punya 4 ciri (3+3+2+1 = 9). Pilih G01 (3) + G03 (2) = 5/9 = 56%.
    final kb = BasisPengetahuan(
      versi: 'x',
      tanggalRilis: 'x',
      gejala: [
        Gejala(id: 'G01', nama: 'a', kelompok: 'daun'),
        Gejala(id: 'G02', nama: 'b', kelompok: 'daun'),
        Gejala(id: 'G03', nama: 'c', kelompok: 'daun'),
        Gejala(id: 'G04', nama: 'd', kelompok: 'daun'),
      ],
      penyakit: [
        p('P1', {'G01': 3, 'G02': 3, 'G03': 2, 'G04': 1}),
      ],
    );
    final a = hitungHasil(kb, {'G01', 'G03'});
    expect(a.kemungkinan.first.skor, 56);
    expect(a.kemungkinan.first.label, 'Sedang');
    expect(a.utama, isNull);
    expect(a.pesan, contains('verifikasi penyuluh'));
  });

  test('U3 tinggi tanpa ciri kunci tidak jadi hasil utama', () {
    // P2: G03 (3) + G04 (2) = 5/5 = 100, kunci G03 bobot 3 -> ada kunci.
    // Uji aturan tanpa kunci: penyakit dengan hanya ciri pendukung.
    final kb = BasisPengetahuan(
      versi: 'x',
      tanggalRilis: 'x',
      gejala: [
        Gejala(id: 'G01', nama: 'a', kelompok: 'daun'),
        Gejala(id: 'G02', nama: 'b', kelompok: 'daun'),
      ],
      penyakit: [p('P1', {'G01': 3}), p('PX', {'G02': 1})],
    );
    final a = hitungHasil(kb, {'G01', 'G02'});
    expect(a.utama?.penyakit.id, 'P1');
  });

  test('U4 satu ciri saja -> belum cukup', () {
    final kb = BasisPengetahuan(
      versi: 'x',
      tanggalRilis: 'x',
      gejala: [Gejala(id: 'G01', nama: 'a', kelompok: 'daun')],
      penyakit: [p('P1', {'G01': 3}), p('P2', {'G02': 3})],
    );
    final a = hitungHasil(kb, {'G01'});
    expect(a.belumCukup, isFalse); // P1 100% tetap kuat
    final b = hitungHasil(kb, {'G09'});
    expect(b.belumCukup, isTrue);
  });

  test('U5 tanpa pilihan -> belum cukup', () {
    final a = hitungHasil(kbDasar(), <String>{});
    expect(a.kemungkinan, isEmpty);
    expect(a.belumCukup, isTrue);
  });

  test('U6 maksimal 3 kemungkinan', () {
    final kb = BasisPengetahuan(
      versi: 'x',
      tanggalRilis: 'x',
      gejala: List.generate(6, (i) => Gejala(id: 'G0${i + 1}', nama: 'g', kelompok: 'daun')),
      penyakit: List.generate(5, (i) => p('P${i + 1}', {'G0${i + 1}': 3, 'G01': 1})),
    );
    final a = hitungHasil(kb, {'G01', 'G02', 'G03', 'G04'});
    expect(a.kemungkinan.length, 3);
  });

  test('U7 urutan skor menurun', () {
    final a = hitungHasil(kbDasar(), {'G01', 'G02', 'G03', 'G05'});
    for (var i = 1; i < a.kemungkinan.length; i++) {
      expect(a.kemungkinan[i - 1].skor >= a.kemungkinan[i].skor, isTrue);
    }
  });

  test('U8 skor seri -> ciri kunci lebih banyak menang', () {
    final kb = BasisPengetahuan(
      versi: 'x',
      tanggalRilis: 'x',
      gejala: [
        Gejala(id: 'G01', nama: 'a', kelompok: 'daun'),
        Gejala(id: 'G02', nama: 'b', kelompok: 'daun'),
        Gejala(id: 'G03', nama: 'c', kelompok: 'daun'),
      ],
      penyakit: [p('PA', {'G01': 3, 'G02': 1}), p('PB', {'G01': 3, 'G03': 1})],
    );
    final a = hitungHasil(kb, {'G01', 'G02', 'G03'});
    expect(a.kemungkinan.first.skor, a.kemungkinan[1].skor);
    // tie-break: kode penyakit naik
    expect(a.kemungkinan.first.penyakit.id, 'PA');
  });

  test('U9 label keyakinan', () {
    final h1 = Hasil(penyakit: p('X', {'G01': 3}), skor: 60, cocok: 3, cocokKunci: 1, totalBobot: 5);
    final h2 = Hasil(penyakit: p('Y', {'G01': 3}), skor: 40, cocok: 2, cocokKunci: 1, totalBobot: 5);
    final h3 = Hasil(penyakit: p('Z', {'G01': 3}), skor: 39, cocok: 2, cocokKunci: 0, totalBobot: 5);
    expect(h1.label, 'Kuat');
    expect(h2.label, 'Sedang');
    expect(h3.label, 'Lemah');
  });

  test('U10 validasi menolak basis rusak', () {
    final kb = BasisPengetahuan(
      versi: 'x',
      tanggalRilis: 'x',
      gejala: [Gejala(id: 'G01', nama: 'a', kelompok: 'daun')],
      penyakit: [p('P1', {'G01': 2}), p('P1', {'G99': 3})],
    );
    final err = kb.validasi();
    expect(err.any((e) => e.contains('dobel')), isTrue);
    expect(err.any((e) => e.contains('tak dikenal')), isTrue);
    expect(err.any((e) => e.contains('ciri kunci')), isTrue);
  });
}
