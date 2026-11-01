// Penyimpanan riwayat identifikasi di perangkat (offline, tanpa akun)
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class Riwayat {
  final String waktu;
  final List<String> gejala;
  final String penyakitId;
  final String penyakitNama;
  final int skor;

  Riwayat({
    required this.waktu,
    required this.gejala,
    required this.penyakitId,
    required this.penyakitNama,
    required this.skor,
  });

  Map<String, dynamic> toJson() => {
        'waktu': waktu,
        'gejala': gejala,
        'penyakit_id': penyakitId,
        'penyakit_nama': penyakitNama,
        'skor': skor,
      };

  factory Riwayat.fromJson(Map<String, dynamic> j) => Riwayat(
        waktu: j['waktu'] as String,
        gejala: ((j['gejala'] as List?) ?? const []).map((e) => e.toString()).toList(),
        penyakitId: (j['penyakit_id'] as String?) ?? '',
        penyakitNama: (j['penyakit_nama'] as String?) ?? '',
        skor: ((j['skor'] as num?) ?? 0).toInt(),
      );
}

class Penyimpanan {
  static const String _kunci = 'sidepi_riwayat';
  static const int _maks = 100;

  static Future<List<Riwayat>> muat() async {
    final sp = await SharedPreferences.getInstance();
    final daftar = sp.getStringList(_kunci) ?? const [];
    final hasil = <Riwayat>[];
    for (final s in daftar) {
      try {
        hasil.add(Riwayat.fromJson(jsonDecode(s) as Map<String, dynamic>));
      } catch (_) {
        // entri rusak dilewati, tidak mematikan aplikasi
      }
    }
    return hasil;
  }

  static Future<void> simpan(Riwayat r) async {
    final sp = await SharedPreferences.getInstance();
    final daftar = sp.getStringList(_kunci) ?? <String>[];
    daftar.insert(0, jsonEncode(r.toJson()));
    if (daftar.length > _maks) daftar.removeRange(_maks, daftar.length);
    await sp.setStringList(_kunci, daftar);
  }

  static Future<void> hapusSemua() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_kunci);
  }
}
