// Pengujian aset: memastikan setiap berkas yang dirujuk benar-benar ikut terbundel.
// Kasus yang pernah lolos: subfolder assets/acuan/<kelas>/ tidak didaftarkan di
// pubspec, sehingga galeri tampil kosong walau kode dan fotonya ada di repo.
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('setiap foto acuan pada indeks benar-benar terbundel', () async {
    final teks = await rootBundle.loadString('assets/acuan.json');
    final peta = jsonDecode(teks) as Map<String, dynamic>;
    expect(peta.keys.length, 7);

    var jumlah = 0;
    for (final entri in peta.entries) {
      final daftar = (entri.value as List).cast<String>();
      expect(daftar, isNotEmpty, reason: 'kelas ${entri.key} tidak punya foto acuan');
      for (final jalur in daftar) {
        final data = await rootBundle.load(jalur);
        expect(data.lengthInBytes, greaterThan(1000), reason: '$jalur kosong atau rusak');
        jumlah++;
      }
    }
    expect(jumlah, 42);
  });

  test('aset merek, model, dan detail penyakit terbundel', () async {
    for (final jalur in [
      'assets/brand/logo_terang.png',
      'assets/brand/logo_gelap.png',
      'assets/models/sidepi_model.tflite',
      'assets/detail_penyakit.json',
      'assets/basis-pengetahuan.json',
    ]) {
      final data = await rootBundle.load(jalur);
      expect(data.lengthInBytes, greaterThan(100), reason: '$jalur tidak terbundel');
    }
  });

  test('kelas pada indeks acuan sama dengan kelas pada model', () async {
    final teks = await rootBundle.loadString('assets/acuan.json');
    final peta = jsonDecode(teks) as Map<String, dynamic>;
    final detail = jsonDecode(await rootBundle.loadString('assets/detail_penyakit.json'))
        as Map<String, dynamic>;
    for (final kelas in peta.keys) {
      expect(detail.containsKey(kelas), isTrue, reason: 'detail penyakit tidak punya $kelas');
    }
  });
}
