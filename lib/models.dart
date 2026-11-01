// Model basis pengetahuan SIDEPI (lihat PRD bagian 6)
class Gejala {
  final String id;
  final String nama;
  final String kelompok;
  final String? foto;

  Gejala({required this.id, required this.nama, required this.kelompok, this.foto});

  factory Gejala.fromJson(Map<String, dynamic> j) => Gejala(
        id: j['id'] as String,
        nama: j['nama'] as String,
        kelompok: (j['kelompok'] as String?) ?? 'daun',
        foto: j['foto'] as String?,
      );
}

class Penyakit {
  final String id;
  final String nama;
  final String namaIlmiah;
  final String penyebab;
  final String deskripsi;
  final List<String> gambar;
  final Map<String, int> bobotGejala;
  final Map<String, List<String>> pengendalian;
  final List<String> pencegahan;
  final String sumber;

  Penyakit({
    required this.id,
    required this.nama,
    required this.namaIlmiah,
    required this.penyebab,
    required this.deskripsi,
    required this.gambar,
    required this.bobotGejala,
    required this.pengendalian,
    required this.pencegahan,
    required this.sumber,
  });

  int get totalBobot => bobotGejala.values.fold(0, (a, b) => a + b);

  factory Penyakit.fromJson(Map<String, dynamic> j) {
    final bobot = <String, int>{};
    (j['bobot_gejala'] as Map<String, dynamic>).forEach((k, v) {
      bobot[k] = (v as num).toInt();
    });
    final peng = <String, List<String>>{};
    final pg = j['pengendalian'];
    if (pg is Map) {
      pg.forEach((k, v) {
        if (v is List) peng[k] = v.map((e) => e.toString()).toList();
      });
    }
    return Penyakit(
      id: j['id'] as String,
      nama: j['nama'] as String,
      namaIlmiah: (j['nama_ilmiah'] as String?) ?? '',
      penyebab: (j['penyebab'] as String?) ?? '',
      deskripsi: (j['deskripsi'] as String?) ?? '',
      gambar: ((j['gambar'] as List?) ?? const []).map((e) => e.toString()).toList(),
      bobotGejala: bobot,
      pengendalian: peng,
      pencegahan: ((j['pencegahan'] as List?) ?? const []).map((e) => e.toString()).toList(),
      sumber: (j['sumber'] as String?) ?? '',
    );
  }
}

class BasisPengetahuan {
  final String versi;
  final String tanggalRilis;
  final List<Gejala> gejala;
  final List<Penyakit> penyakit;

  BasisPengetahuan({
    required this.versi,
    required this.tanggalRilis,
    required this.gejala,
    required this.penyakit,
  });

  factory BasisPengetahuan.fromJson(Map<String, dynamic> j) => BasisPengetahuan(
        versi: (j['versi'] as String?) ?? '0',
        tanggalRilis: (j['tanggal_rilis'] as String?) ?? '-',
        gejala: ((j['gejala'] as List?) ?? const [])
            .map((e) => Gejala.fromJson(e as Map<String, dynamic>))
            .toList(),
        penyakit: ((j['penyakit'] as List?) ?? const [])
            .map((e) => Penyakit.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Gejala? gejalaById(String id) {
    for (final g in gejala) {
      if (g.id == id) return g;
    }
    return null;
  }

  /// Validasi wajib sebelum basis dipakai (PRD bagian 6).
  /// Mengembalikan daftar kesalahan; kosong berarti lolos.
  List<String> validasi() {
    final err = <String>[];
    final idGejala = <String>{};
    for (final g in gejala) {
      if (g.id.trim().isEmpty) {
        err.add('Ada ciri tanpa id.');
      } else if (!idGejala.add(g.id)) {
        err.add('Id ciri dobel: ${g.id}.');
      }
    }
    final idPenyakit = <String>{};
    for (final p in penyakit) {
      if (!idPenyakit.add(p.id)) err.add('Id penyakit dobel: ${p.id}.');
      if (p.bobotGejala.isEmpty) {
        err.add('Penyakit ${p.id} tidak punya bobot ciri.');
        continue;
      }
      var adaKunci = false;
      p.bobotGejala.forEach((gid, bobot) {
        if (!idGejala.contains(gid)) {
          err.add('Penyakit ${p.id} merujuk ciri tak dikenal: $gid.');
        }
        if (bobot < 1 || bobot > 3) {
          err.add('Bobot ciri $gid pada ${p.id} di luar 1-3.');
        }
        if (bobot == 3) adaKunci = true;
      });
      if (!adaKunci) {
        err.add('Penyakit ${p.id} tidak punya ciri kunci (bobot 3).');
      }
    }
    return err;
  }
}
