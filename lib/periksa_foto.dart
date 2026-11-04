// SIDEPI - layar periksa foto: bisa satu atau beberapa foto sekaligus.
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'botani.dart';
import 'citra.dart';
import 'galeri_acuan.dart';
import 'model_foto.dart';
import 'tema.dart';

class PeriksaFotoScreen extends StatefulWidget {
  const PeriksaFotoScreen({super.key});

  @override
  State<PeriksaFotoScreen> createState() => _PeriksaFotoScreenState();
}

class _PeriksaFotoScreenState extends State<PeriksaFotoScreen> {
  final _picker = ImagePicker();
  final _model = ModelFoto();
  bool _modelSiap = false;
  bool _memproses = false;
  String? _galat;
  Map<String, dynamic> _detail = {};
  final Set<int> _ciriDicentang = {};

  final List<File> _berkas = [];
  final List<HasilPotong> _potongan = [];
  final List<HasilFoto> _perFoto = [];
  final List<HasilModel?> _modelPerFoto = [];
  HasilModel? _gabungan;
  int _diterima = 0;
  int _dilewati = 0;
  int _bukanPadi = 0;
  int _sepakat = 0;
  int _utama = 0;

  @override
  void initState() {
    super.initState();
    _muatDetail();
  }

  Future<void> _muatDetail() async {
    try {
      final teks = await rootBundle.loadString('assets/detail_penyakit.json');
      final data = jsonDecode(teks) as Map<String, dynamic>;
      if (mounted) setState(() => _detail = data);
    } catch (_) {
      // tanpa detail, aplikasi tetap bisa dipakai
    }
  }

  static const _ciriKonfirmasi = [
    'Bercak berbentuk belah ketupat atau jorong',
    'Pusat bercak abu-abu dengan tepi coklat',
    'Bercak tersebar di helai daun, bukan hanya tepi',
    'Leher malai menghitam dan mudah patah',
  ];

  Future<void> _ambil(ImageSource sumber) async {
    setState(() {
      _galat = null;
      _memproses = true;
      _berkas.clear();
      _perFoto.clear();
      _modelPerFoto.clear();
      _gabungan = null;
      _diterima = 0;
      _dilewati = 0;
      _sepakat = 0;
      _utama = 0;
      _ciriDicentang.clear();
    });
    try {
      final List<XFile> pilihan = sumber == ImageSource.camera
          ? [await _picker.pickImage(source: sumber, maxWidth: 1600, imageQuality: 92)]
              .whereType<XFile>()
              .toList()
          : (await _picker.pickMultiImage(maxWidth: 1600, imageQuality: 92)).take(6).toList();
      if (pilihan.isEmpty) {
        setState(() => _memproses = false);
        return;
      }
      if (!_modelSiap) {
        try {
          await _model.siapkan();
          _modelSiap = true;
        } catch (_) {
          _modelSiap = false;
        }
      }

      final berkasBaru = <File>[];
      final hasilBaru = <HasilFoto>[];
      final modelBaru = <HasilModel?>[];
      for (final x in pilihan) {
        final f = File(x.path);
        final bytes = await f.readAsBytes();
        // Tahap 0: buang latar belakang, sisakan bagian tanaman saja.
        final potong = potongTanaman(bytes);
        potonganBaru.add(potong);
        hasilBaru.add(periksaFotoBytes(potong.bytes));
        HasilModel? m;
        try {
          m = _modelSiap ? _model.periksa(potong.bytes) : null;
        } catch (_) {
          m = null;
        }
        modelBaru.add(m);
        berkasBaru.add(f);
      }

      final dipakai = <HasilModel>[];
      var utama = 0;
      var yakin = -1.0;
      for (var i = 0; i < hasilBaru.length; i++) {
        final h = hasilBaru[i];
        if (h.status == 'bukan_padi' || h.status == 'terlalu_jauh') continue;
        final m = modelBaru[i];
        if (m == null) continue;
        // model sudah belajar menolak daun tanaman lain, jadi foto yang
        // dinilai bukan padi tidak ikut menentukan kesimpulan
        if (m.kelas == 'bukan_padi') continue;
        dipakai.add(m);
        if (m.teratas > yakin) {
          yakin = m.teratas;
          utama = i;
        }
      }
      HasilModel? gab;
      var sepakat = 0;
      if (dipakai.isNotEmpty) {
        gab = gabungModel(dipakai);
        sepakat = dipakai.where((m) => m.kelas == gab!.kelas).length;
      }

      final ditolakModel =
          modelBaru.where((m) => m != null && m.kelas == 'bukan_padi').length;
      setState(() {
        _bukanPadi = ditolakModel;
        _berkas.addAll(berkasBaru);
        _potongan.addAll(potonganBaru);
        _perFoto.addAll(hasilBaru);
        _modelPerFoto.addAll(modelBaru);
        _gabungan = gab;
        _diterima = dipakai.length;
        _dilewati = hasilBaru.length - dipakai.length;
        _sepakat = sepakat;
        _utama = utama;
        _memproses = false;
      });
    } catch (_) {
      setState(() {
        _galat = 'Foto tidak dapat diperiksa. Coba ambil ulang dengan pencahayaan cukup.';
        _memproses = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Periksa foto')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 30),
          children: [
            if (_perFoto.isEmpty) ..._panduan(),
            if (_memproses) ..._kartuMemproses(),
            if (_galat != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: W.merahMuda,
                  borderRadius: BorderRadius.circular(R.sedang),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.error_outline, size: 18, color: W.merah),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(_galat!,
                          style: T.kecil.copyWith(fontSize: 12.5, color: W.merah)),
                    ),
                  ],
                ),
              ),
            ],
            if (_perFoto.isNotEmpty && !_memproses) ..._isiHasil(),
          ],
        ),
      ),
    );
  }

  List<Widget> _panduan() {
    return [
      const SizedBox(height: 4),
      const Text('Ambil foto yang jelas.', style: T.judulBesar),
      const SizedBox(height: 8),
      Text('Satu foto bisa, tetapi dua sampai tiga bagian tanaman memberi hasil lebih kuat.',
          style: T.kecil.copyWith(fontSize: 13)),
      const SizedBox(height: 20),
      Kartu(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _petunjuk(Icons.straighten_rounded, 'Dekatkan kamera 10 sampai 15 cm dari bagian tanaman.'),
            _petunjuk(Icons.wb_sunny_outlined, 'Ambil di tempat terang, hindari bayangan daun.'),
            _petunjuk(Icons.filter_center_focus, 'Penuhi layar dengan daun atau batang yang sakit.'),
            _petunjuk(Icons.collections_outlined, 'Tambahkan foto leher malai atau pangkal batang bila ada.'),
          ],
        ),
      ),
      const SizedBox(height: 18),
      FilledButton.icon(
        onPressed: _memproses ? null : () => _ambil(ImageSource.camera),
        icon: const Icon(Icons.photo_camera_outlined, size: 19),
        label: const Text('Ambil foto'),
      ),
      const SizedBox(height: 9),
      OutlinedButton.icon(
        onPressed: _memproses ? null : () => _ambil(ImageSource.gallery),
        icon: const Icon(Icons.photo_library_outlined, size: 19),
        label: const Text('Pilih dari galeri'),
      ),
    ];
  }

  Widget _petunjuk(IconData ikon, String teks) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(ikon, size: 17, color: W.hijauSedang),
            const SizedBox(width: 11),
            Expanded(child: Text(teks, style: T.badan.copyWith(fontSize: 13))),
          ],
        ),
      );

  List<Widget> _kartuMemproses() {
    return [
      const SizedBox(height: 22),
      Kartu(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Menganalisis ${_berkas.length} foto', style: T.subjudul),
            const SizedBox(height: 10),
            const BilahSkor(nilai: 0.45, warna: W.hijauSedang),
            const SizedBox(height: 8),
            Text('Model berjalan di dalam ponsel, tanpa mengunggah foto.',
                style: T.kecil.copyWith(fontSize: 11.5)),
          ],
        ),
      ),
    ];
  }

  bool _ditolak(HasilFoto h) => h.status == 'bukan_padi' || h.status == 'terlalu_jauh';

  List<Widget> _isiHasil() {
    final potongan = _potongan.isEmpty
        ? HasilPotong(bytes: Uint8List(0), porsiBingkai: 0, rasioBentuk: 1, kelurusanTepi: 0)
        : _potongan[_utama.clamp(0, _potongan.length - 1)];
    final semuaDitolak = _gabungan == null;
    final kelas = _gabungan?.kelas ?? _perFoto[_utama].kelas;
    final teksKelas = namaTampil[kelas] ?? _perFoto[_utama].nama;
    final yakin = _gabungan?.teratas ?? 0;

    final judul = semuaDitolak
        ? (_bukanPadi > 0
            ? 'Ini bukan daun padi'
            : _perFoto[_utama].status == 'bukan_padi'
                ? 'Foto ini bukan tanaman padi'
                : 'Bagian tanaman terlalu kecil')
        : kelas == 'sehat'
            ? 'Daun tampak sehat'
            : teksKelas;
    final statusWarna = semuaDitolak
        ? W.kunyit
        : kelas == 'sehat'
            ? W.hijauSedang
            : W.merah;
    final statusTeks = semuaDitolak
        ? (_bukanPadi > 0 ? 'Bukan tanaman padi' : 'Pemeriksaan dibatalkan')
        : kelas == 'sehat'
            ? 'Tidak ada indikasi penyakit'
            : 'Indikasi penyakit atau hama';

    var pesan = '';
    if (semuaDitolak) {
      pesan = _bukanPadi > 0
          ? 'Model mengenali foto ini sebagai daun tanaman lain, bukan padi. SIDEPI hanya menilai daun padi, jadi hasil penyakit tidak ditampilkan. Untuk tanaman lain, mintalah pendampingan penyuluh.'
          : _perFoto[_utama].status == 'bukan_padi'
              ? 'Foto tidak memuat bagian tanaman padi yang cukup. Arahkan kamera ke daun padi sampai memenuhi layar, lalu ambil ulang.'
              : 'Bagian tanaman dalam foto terlalu sedikit untuk dinilai. Dekatkan kamera 10 sampai 15 cm dari daun lalu ambil ulang.';
    } else if (_diterima == 1) {
      pesan = kelas == 'sehat'
          ? 'Foto tidak menunjukkan bercak penyakit yang berarti. Tetap periksa bagian lain tanaman.'
          : 'Pola pada foto paling mirip dengan $teksKelas. Tambah satu atau dua foto bagian lain untuk memperkuat hasil.';
    } else if (_sepakat == _diterima) {
      pesan =
          'Kesimpulan dari $_diterima foto dan semuanya sepakat. Hasil seperti ini paling bisa dipercaya.';
    } else {
      pesan =
          'Kesimpulan dari $_diterima foto, $_sepakat sepakat. Foto yang berbeda pendapat biasanya bagian tanaman yang gejalanya belum jelas, jadi cocokkan dengan ciri di bawah.';
    }

    final ciri = _perFoto[_utama].ciri;

    return [
      const SizedBox(height: 18),
      Kartu(
        padding: const EdgeInsets.all(18),
        garisAtas: statusWarna,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Lencana(
                  teks: statusTeks,
                  warna: statusWarna,
                  ikon: semuaDitolak
                      ? Icons.block
                      : kelas == 'sehat'
                          ? Icons.check_circle_outline
                          : Icons.warning_amber_rounded,
                ),
                const Spacer(),
                if (!semuaDitolak)
                  Text('${(yakin * 100).toStringAsFixed(0)}%',
                      style: T.judul.copyWith(fontSize: 24, color: W.hijau)),
              ],
            ),
            const SizedBox(height: 13),
            Text(judul, style: T.judul.copyWith(fontSize: 22)),
            const SizedBox(height: 8),
            Text(pesan, style: T.badan.copyWith(fontSize: 13)),
            if (!semuaDitolak) ...[
              const SizedBox(height: 14),
              BilahSkor(nilai: yakin, warna: kelas == 'sehat' ? W.hijauSedang : W.merah),
            ],
            if (_dilewati > 0) ...[
              const SizedBox(height: 10),
              Text('$_dilewati foto dilewati karena bukan tanaman padi atau terlalu jauh.',
                  style: T.kecil.copyWith(fontSize: 11.5, color: W.kunyit)),
            ],
            const SizedBox(height: 16),
            const Divider(color: W.garisTipis),
            const SizedBox(height: 12),
            _baris('Bagian tanaman pada foto', '${(ciri.rasioTanaman * 100).toStringAsFixed(0)}%'),
            _baris('Tanaman menempati bingkai', '${(potongan.porsiBingkai * 100).toStringAsFixed(0)}%'),
            _baris('Rasio bentuk daun', '${potongan.rasioBentuk.toStringAsFixed(1)} : 1'),
            _baris('Kelurusan tepi daun', '${(potongan.kelurusanTepi * 100).toStringAsFixed(0)}%'),
            if (!semuaDitolak) ...[
              _baris('Luas daun berbercak', '${(ciri.rasioLesi * 100).toStringAsFixed(1)}%'),
              _baris('Jumlah bercak terdeteksi', '${ciri.jumlahBercak}'),
              _baris('Bercak berinti pucat', '${(ciri.pucat * 100).toStringAsFixed(1)}%'),
            ],
          ],
        ),
      ),
      const SizedBox(height: 18),
      const JudulBagian('Foto yang diperiksa'),
      SizedBox(
        height: 132,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _berkas.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final h = _perFoto[i];
            final m = _modelPerFoto[i];
            final nama = _ditolak(h)
                ? 'Dilewati'
                : m == null
                    ? 'Tanpa model'
                    : (namaTampil[m.kelas] ?? m.kelas);
            final nilai = _ditolak(h) || m == null ? '' : '${(m.teratas * 100).toStringAsFixed(0)}%';
            return ClipRRect(
              borderRadius: BorderRadius.circular(R.kecil + 2),
              child: SizedBox(
                width: 108,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(_berkas[i], fit: BoxFit.cover),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(7, 14, 7, 6),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [Color(0xE60B1F17), Color(0x000B1F17)],
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(nama,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontFamily: 'Inter', fontSize: 10, height: 1.2,
                                    fontWeight: FontWeight.w600, color: W.kertas)),
                            if (nilai.isNotEmpty)
                              Text(nilai,
                                  style: TextStyle(
                                      fontFamily: 'Inter', fontSize: 9.5,
                                      color: W.kertas.withValues(alpha: 0.75))),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      if (!semuaDitolak && _detail[kelas] != null) ...[
        const SizedBox(height: 20),
        _kartuCiri(kelas),
        const SizedBox(height: 20),
        const JudulBagian('Bandingkan dengan foto acuan'),
        Kartu(padding: const EdgeInsets.all(13), child: StripAcuan(kelas: kelas)),
        const SizedBox(height: 20),
        const JudulBagian('Pengendalian'),
        _kartuPengendalian(kelas),
        const SizedBox(height: 16),
        _kartuKemungkinanLain(kelas),
      ],
      if (_gabungan != null) ...[
        const SizedBox(height: 20),
        const JudulBagian('Rincian peluang tiap kelas'),
        _kartuModel(_gabungan!),
      ],
      if (!semuaDitolak) ...[
        const SizedBox(height: 20),
        const JudulBagian('Konfirmasi ciri di lapangan'),
        Text('Centang yang benar-benar tampak pada tanaman.', style: T.kecil.copyWith(fontSize: 12)),
        const SizedBox(height: 8),
        ...List.generate(_ciriKonfirmasi.length, (i) {
          final aktif = _ciriDicentang.contains(i);
          return Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: Kartu(
              onTap: () => setState(() {
                if (aktif) {
                  _ciriDicentang.remove(i);
                } else {
                  _ciriDicentang.add(i);
                }
              }),
              warna: aktif ? W.hijauTipis : W.permukaan,
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
              child: Row(
                children: [
                  Icon(aktif ? Icons.check_circle : Icons.circle_outlined,
                      size: 18, color: aktif ? W.hijau : W.garis),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(_ciriKonfirmasi[i],
                        style: T.badan.copyWith(
                            fontSize: 13, color: aktif ? W.hijau : W.tinta)),
                  ),
                ],
              ),
            ),
          );
        }),
        if (_ciriDicentang.isNotEmpty) ...[
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: _ciriDicentang.length >= 2 ? W.hijauTipis : W.kunyitMuda,
              borderRadius: BorderRadius.circular(R.sedang),
            ),
            child: Text(
              _ciriDicentang.length >= 2
                  ? 'Ciri yang dicentang mendukung indikasi $teksKelas. Lanjutkan dengan tindakan pengendalian dan laporkan ke penyuluh.'
                  : 'Satu ciri belum cukup. Periksa ciri lain atau kirim tanaman ke penyuluh.',
              style: T.kecil.copyWith(
                  fontSize: 12.5,
                  height: 1.45,
                  color: _ciriDicentang.length >= 2 ? W.hijau : const Color(0xFF6B4A10)),
            ),
          ),
        ],
      ],
      const SizedBox(height: 20),
      OutlinedButton.icon(
        onPressed: _memproses ? null : () => _ambil(ImageSource.camera),
        icon: const Icon(Icons.replay_rounded, size: 18),
        label: const Text('Periksa foto lain'),
      ),
      const SizedBox(height: 22),
      const Divider(color: W.garisTipis),
      const SizedBox(height: 12),
      Text(
        'Hasil foto adalah alat bantu, bukan diagnosis final. Ketepatan uji model 97,1% pada foto '
        'laboratorium dengan data uji dipisah per foto asli; pada foto lapangan bisa lebih rendah. '
        'Selalu konfirmasi dengan penyuluh.',
        style: T.kecil.copyWith(fontSize: 11, color: W.redupMuda, height: 1.5),
      ),
    ];
  }

  Widget _baris(String label, String nilai) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          Expanded(child: Text(label, style: T.kecil.copyWith(fontSize: 12.5))),
          Text(nilai,
              style: T.kecil.copyWith(
                  fontSize: 12.5, fontWeight: FontWeight.w600, color: W.tinta)),
        ],
      ),
    );
  }

  Widget _kartuCiri(String kelas) {
    final d = _info(kelas)!;
    final gejala = (d['gejala'] as List? ?? []).cast<String>();
    return ClipRRect(
      borderRadius: BorderRadius.circular(R.sedang),
      child: Container(
        decoration: BoxDecoration(
          color: W.permukaan,
          borderRadius: BorderRadius.circular(R.sedang),
          border: Border.all(color: W.garisTipis),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset(d['gambar'] as String, height: 176, width: double.infinity, fit: BoxFit.cover),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(d['nama'] as String? ?? '', style: T.judul.copyWith(fontSize: 19)),
                  const SizedBox(height: 3),
                  Text(d['penyebab'] as String? ?? '',
                      style: T.kecil.copyWith(fontSize: 11.5, fontStyle: FontStyle.italic)),
                  const SizedBox(height: 10),
                  Text(d['deskripsi'] as String? ?? '', style: T.badan.copyWith(fontSize: 13)),
                  if (gejala.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text('Ciri pembeda', style: T.mikro),
                    const SizedBox(height: 7),
                    ...gejala.map((g) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 2, right: 9),
                                child: Icon(Icons.check_rounded, size: 14, color: W.hijauSedang),
                              ),
                              Expanded(child: Text(g, style: T.badan.copyWith(fontSize: 12.5))),
                            ],
                          ),
                        )),
                  ],
                  const SizedBox(height: 6),
                  Text('Contoh foto gejala dari data latih.',
                      style: T.kecil.copyWith(fontSize: 10.5, color: W.redupMuda)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kartuPengendalian(String kelas) {
    final d = _info(kelas);
    if (d == null) return const SizedBox();
    final langkah = (d['pengendalian'] as List? ?? []).cast<String>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...List.generate(langkah.length, (i) => Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${i + 1}'.padLeft(2, '0'),
                      style: T.mikro.copyWith(color: W.hijauSedang)),
                  const SizedBox(width: 11),
                  Expanded(child: Text(langkah[i], style: T.badan.copyWith(fontSize: 13))),
                ],
              ),
            )),
      ],
    );
  }

  Widget _kartuKemungkinanLain(String kelas) {
    final m = _gabungan;
    if (m == null) return const SizedBox();
    final lain = m.peluang.entries.where((e) => e.key != kelas).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    if (lain.isEmpty) return const SizedBox();
    final mirip = (_info(kelas)?['mirip'] as List? ?? []).cast<String>();
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: W.kunyitMuda,
        borderRadius: BorderRadius.circular(R.sedang),
        border: Border.all(color: W.kunyit.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.swap_horiz_rounded, size: 17, color: W.kunyit),
              const SizedBox(width: 8),
              Text('Sering tertukar',
                  style: T.subjudul.copyWith(fontSize: 13, color: const Color(0xFF6B4A10))),
            ],
          ),
          const SizedBox(height: 9),
          ...lain.take(2).map((e) {
            final nama = namaTampil[e.key] ?? e.key;
            final catatan = mirip.contains(e.key) ? 'gejala mirip' : 'kemungkinan kecil';
            return Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(
                children: [
                  Expanded(
                    child: Text(nama,
                        style: T.badan.copyWith(fontSize: 12.5, color: const Color(0xFF6B4A10))),
                  ),
                  Text('${(e.value * 100).toStringAsFixed(0)}% · $catatan',
                      style: T.kecil.copyWith(fontSize: 11, color: const Color(0xFF8A6A2A))),
                ],
              ),
            );
          }),
          const SizedBox(height: 4),
          Text('Bila ciri lapangan tidak cocok dengan hasil utama, periksa kemungkinan ini lebih dulu.',
              style: T.kecil.copyWith(fontSize: 11, height: 1.45, color: const Color(0xFF8A6A2A))),
        ],
      ),
    );
  }

  Widget _kartuModel(HasilModel m) {
    final urut = m.peluang.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return Kartu(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...urut.map((e) {
            final teratas = e.key == m.kelas;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(namaTampil[e.key] ?? e.key,
                            style: T.kecil.copyWith(
                                fontSize: 12,
                                fontWeight: teratas ? FontWeight.w600 : FontWeight.w400,
                                color: teratas ? W.hijau : W.redup)),
                      ),
                      Text('${(e.value * 100).toStringAsFixed(0)}%',
                          style: T.kecil.copyWith(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: teratas ? W.hijau : W.redupMuda)),
                    ],
                  ),
                  const SizedBox(height: 5),
                  BilahSkor(
                    nilai: e.value,
                    tinggi: 3,
                    warna: teratas ? W.hijauSedang : W.garis,
                  ),
                ],
              ),
            );
          }),
          Text('Peluang dirata-rata dari semua foto yang diperiksa.',
              style: T.kecil.copyWith(fontSize: 10.5, color: W.redupMuda)),
        ],
      ),
    );
  }

  Map<String, dynamic>? _info(String kelas) {
    final d = _detail[kelas];
    return d is Map<String, dynamic> ? d : null;
  }
}
