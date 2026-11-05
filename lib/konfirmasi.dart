// Jembatan antara model foto dan sistem pakar.
//
// Model foto jarang salah total, tetapi sering ragu: misalnya tungro 62% dan
// blas 31%. Pada kondisi seperti itu aplikasi tidak memaksa memilih. Ia
// mengambil dua atau tiga gejala pembeda dari basis pengetahuan, menanyakannya
// kepada petugas, lalu menghitung ulang.
//
// Rumus gabungan: 0,65 x peluang model + 0,35 x kecocokan gejala.
// Bobot model tetap lebih besar karena model melihat seluruh pola bercak,
// sedangkan jawaban gejala hanya memeriksa ciri yang ditanyakan.
class Tanya {
  final String teks;

  /// Kelas penyakit yang didukung gejala ini.
  final String kelas;

  /// 2 bila gejala khas kelas itu, 1 bila juga muncul pada kelas lain.
  final int bobot;

  const Tanya({required this.teks, required this.kelas, required this.bobot});
}

class HasilUlang {
  final String kelas;
  final double skor;
  final Map<String, double> rincian;
  final String sebelumnya;

  HasilUlang({
    required this.kelas,
    required this.skor,
    required this.rincian,
    required this.sebelumnya,
  });

  bool get berubah => kelas != sebelumnya;
}

/// Menyusun pertanyaan pembeda antara dua kelas yang paling mungkin.
/// Gejala yang hanya dimiliki satu kelas diberi bobot lebih besar karena
/// paling berguna untuk memisahkan.
List<Tanya> susunPertanyaan(
  Map<String, dynamic> detail,
  String utama,
  String kedua, {
  int maks = 3,
}) {
  final semua = <String, List<String>>{};
  detail.forEach((k, v) {
    if (v is Map && v['gejala'] is List) {
      semua[k] = (v['gejala'] as List).cast<String>();
    }
  });

  final gejalaUtama = semua[utama] ?? const <String>[];
  final gejalaKedua = semua[kedua] ?? const <String>[];

  int bobot(String teks, String milik) {
    var munculDi = 0;
    semua.forEach((k, daftar) {
      if (daftar.contains(teks)) munculDi++;
    });
    return munculDi <= 1 ? 2 : 1;
  }

  final hasil = <Tanya>[];
  // dua gejala dari kandidat teratas, satu dari pesaing terdekat
  for (final t in gejalaUtama.take(2)) {
    hasil.add(Tanya(teks: t, kelas: utama, bobot: bobot(t, utama)));
  }
  for (final t in gejalaKedua.take(1)) {
    if (hasil.any((h) => h.teks == t)) continue;
    hasil.add(Tanya(teks: t, kelas: kedua, bobot: bobot(t, kedua)));
  }
  hasil.sort((a, b) => b.bobot.compareTo(a.bobot));
  return hasil.take(maks).toList();
}

/// Menghitung ulang kesimpulan setelah pertanyaan dijawab.
/// [jawaban] berisi true (ya), false (tidak), atau null (belum dijawab).
/// Mengembalikan null selama belum ada jawaban.
HasilUlang? hitungUlang({
  required Map<String, double> peluang,
  required List<Tanya> tanya,
  required List<bool?> jawaban,
  required String sebelumnya,
  double bobotModel = 0.65,
}) {
  if (tanya.isEmpty || jawaban.every((j) => j == null)) return null;

  // ambil tiga kandidat teratas, tanpa kelas penolakan
  final kandidat = peluang.entries
      .where((e) => e.key != 'bukan_padi')
      .toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  final calon = kandidat.take(3).toList();
  if (calon.isEmpty) return null;

  final jumlahPeluang = calon.fold<double>(0, (s, e) => s + e.value);
  final rincian = <String, double>{};
  var terbaik = calon.first.key;
  var skorTerbaik = -1.0;

  for (final c in calon) {
    var bobotTotal = 0;
    var bobotCocok = 0;
    for (var i = 0; i < tanya.length; i++) {
      if (tanya[i].kelas != c.key) continue;
      bobotTotal += tanya[i].bobot;
      if (jawaban[i] == true) bobotCocok += tanya[i].bobot;
    }
    final skorGejala = bobotTotal == 0 ? 0.0 : bobotCocok / bobotTotal;
    final peluangNormal = jumlahPeluang == 0 ? 0.0 : c.value / jumlahPeluang;
    final gabungan = bobotModel * peluangNormal + (1 - bobotModel) * skorGejala;
    rincian[c.key] = gabungan;
    if (gabungan > skorTerbaik) {
      skorTerbaik = gabungan;
      terbaik = c.key;
    }
  }

  return HasilUlang(
    kelas: terbaik,
    skor: skorTerbaik,
    rincian: rincian,
    sebelumnya: sebelumnya,
  );
}
