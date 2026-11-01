// Mesin penilaian SIDEPI (PRD bagian 5)
import 'models.dart';

class Hasil {
  final Penyakit penyakit;
  final int skor;
  final int cocok;
  final int cocokKunci;
  final int totalBobot;

  Hasil({
    required this.penyakit,
    required this.skor,
    required this.cocok,
    required this.cocokKunci,
    required this.totalBobot,
  });

  String get label {
    if (skor >= 60) return 'Kuat';
    if (skor >= 40) return 'Sedang';
    return 'Lemah';
  }
}

class Analisis {
  final List<Hasil> kemungkinan;
  final Hasil? utama;
  final String pesan;

  Analisis({required this.kemungkinan, this.utama, required this.pesan});

  bool get belumCukup => kemungkinan.isEmpty || kemungkinan.first.skor < 40;
}

const String penafian =
    'Hasil ini adalah alat bantu identifikasi, bukan diagnosis final. '
    'Untuk keputusan pengendalian, konsultasikan dengan penyuluh pertanian.';

Analisis hitungHasil(BasisPengetahuan kb, Set<String> terpilih) {
  final hasil = <Hasil>[];

  for (final p in kb.penyakit) {
    var cocok = 0;
    var cocokKunci = 0;
    p.bobotGejala.forEach((gid, bobot) {
      if (terpilih.contains(gid)) {
        cocok += bobot;
        if (bobot == 3) cocokKunci += 1;
      }
    });
    if (cocok == 0) continue; // aturan 1
    final total = p.totalBobot;
    final skor = total == 0 ? 0 : ((cocok / total) * 100).round();
    hasil.add(Hasil(
      penyakit: p,
      skor: skor,
      cocok: cocok,
      cocokKunci: cocokKunci,
      totalBobot: total,
    ));
  }

  hasil.sort((a, b) {
    if (b.skor != a.skor) return b.skor.compareTo(a.skor);
    if (b.cocokKunci != a.cocokKunci) return b.cocokKunci.compareTo(a.cocokKunci);
    if (b.totalBobot != a.totalBobot) return b.totalBobot.compareTo(a.totalBobot);
    return a.penyakit.id.compareTo(b.penyakit.id);
  });

  final tampil = hasil.take(3).toList(); // aturan 5
  if (tampil.isEmpty) {
    return Analisis(
      kemungkinan: tampil,
      pesan: 'Ciri yang dipilih belum cocok dengan penyakit mana pun pada basis '
          'pengetahuan. Tambahkan ciri lain atau hubungi penyuluh.',
    );
  }

  final teratas = tampil.first;
  if (teratas.skor >= 60 && teratas.cocokKunci >= 1) {
    return Analisis(kemungkinan: tampil, utama: teratas, pesan: 'Kecocokan kuat dengan ciri yang dipilih.');
  }
  if (teratas.skor >= 60 && teratas.cocokKunci == 0) {
    return Analisis(
      kemungkinan: tampil,
      pesan: 'Skor cukup tinggi, tetapi tidak ada ciri kunci yang dipilih. '
          'Periksa kembali ciri di lapangan sebelum mengambil tindakan.',
    );
  }
  if (teratas.skor >= 40) {
    return Analisis(
      kemungkinan: tampil,
      pesan: 'Dugaan teratas baru pada tingkat sedang. Sebaiknya perlu verifikasi '
          'penyuluh sebelum mengambil tindakan pengendalian.',
    );
  }
  return Analisis(
    kemungkinan: tampil,
    pesan: 'Ciri yang dipilih belum cukup mewakili penyakit mana pun. '
        'Tambahkan ciri yang terlihat dan konsultasikan dengan penyuluh.',
  );
}
