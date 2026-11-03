// SIDEPI - layar periksa foto (pengolahan citra klasik, tanpa internet).
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'citra.dart';
import 'model_foto.dart';

const _hijau = Color(0xFF1F6F43);
const _hijauTua = Color(0xFF14432A);
const _hijauMuda = Color(0xFFE8F3EC);

class PeriksaFotoScreen extends StatefulWidget {
  const PeriksaFotoScreen({super.key});

  @override
  State<PeriksaFotoScreen> createState() => _PeriksaFotoScreenState();
}

class _PeriksaFotoScreenState extends State<PeriksaFotoScreen> {
  final _picker = ImagePicker();
  File? _foto;
  HasilFoto? _hasil;
  HasilModel? _hasilModel;
  final _model = ModelFoto();
  bool _modelSiap = false;
  bool _memproses = false;
  String? _galat;
  final Set<int> _ciriDicentang = {};
  Map<String, dynamic> _detail = {};

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
      _hasil = null;
      _ciriDicentang.clear();
    });
    try {
      final x = await _picker.pickImage(source: sumber, maxWidth: 1600, imageQuality: 92);
      if (x == null) {
        setState(() => _memproses = false);
        return;
      }
      final berkas = File(x.path);
      final bytes = await berkas.readAsBytes();
      final hasil = periksaFotoBytes(bytes);
      HasilModel? hasilModel;
      try {
        if (!_modelSiap) {
          await _model.siapkan();
          _modelSiap = true;
        }
        hasilModel = _model.periksa(bytes);
      } catch (_) {
        hasilModel = null;
      }
      setState(() {
        _foto = berkas;
        _hasil = hasil;
        _hasilModel = hasilModel;
        _memproses = false;
      });
    } catch (e) {
      setState(() {
        _galat = 'Foto tidak dapat diperiksa. Coba ambil ulang dengan pencahayaan cukup.';
        _memproses = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _hijau,
        foregroundColor: Colors.white,
        title: const Text('Periksa Foto'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            if (_foto != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(_foto!, height: 240, fit: BoxFit.cover),
              ),
            if (_foto == null)
              Container(
                height: 160,
                decoration: BoxDecoration(
                  color: _hijauMuda,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Foto satu helai daun dari jarak dekat, dengan cahaya cukup dan latar sederhana.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: _hijauTua, fontSize: 13),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _memproses ? null : () => _ambil(ImageSource.camera),
                    icon: const Icon(Icons.photo_camera),
                    label: const Text('Ambil Foto'),
                    style: FilledButton.styleFrom(
                      backgroundColor: _hijau,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _memproses ? null : () => _ambil(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Galeri'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      foregroundColor: _hijauTua,
                    ),
                  ),
                ),
              ],
            ),
            if (_memproses) ...[
              const SizedBox(height: 20),
              const Center(child: CircularProgressIndicator(color: _hijau)),
            ],
            if (_galat != null) ...[
              const SizedBox(height: 16),
              Text(_galat!, style: const TextStyle(color: Color(0xFFA83A2C))),
            ],
            if (_hasil != null) ..._isiHasil(_hasil!),
          ],
        ),
      ),
    );
  }

  List<Widget> _isiHasil(HasilFoto h) {
    final ciri = h.ciri;
    final ditolak = h.status == 'bukan_padi' || h.status == 'terlalu_jauh';
    final judul = h.status == 'bukan_padi'
        ? 'Ini bukan foto tanaman padi'
        : h.status == 'terlalu_jauh'
            ? 'Bagian tanaman terlalu kecil'
            : h.status == 'sehat'
                ? 'Daun tampak sehat'
                : h.status == 'belum_pasti'
                    ? 'Belum dapat dipastikan'
                    : 'Indikasi: ${h.nama}';
    final warna = h.status == 'bukan_padi' || h.status == 'terlalu_jauh'
        ? const Color(0xFF5A6B60)
        : h.status == 'sehat'
            ? _hijau
            : h.status == 'belum_pasti'
                ? const Color(0xFFB8860B)
                : const Color(0xFFA83A2C);
    final pesan = h.status == 'bukan_padi'
        ? 'Foto ini tidak memuat bagian tanaman padi yang cukup, jadi tidak dianalisis. Arahkan kamera ke daun, batang, atau malai padi sampai memenuhi layar, lalu ambil ulang.'
        : h.status == 'terlalu_jauh'
            ? 'Bagian tanaman dalam foto terlalu sedikit untuk dinilai. Dekatkan kamera 10-15 cm dari daun, lalu ambil ulang.'
            : h.status == 'sehat'
                ? 'Foto tidak menunjukkan bercak penyakit yang berarti. Tetap periksa bagian lain tanaman.'
                : h.status == 'belum_pasti'
                    ? 'Pola foto belum cukup khas. Centang ciri di bawah atau periksa tanaman lain.'
                    : 'Pola bercak pada foto paling mirip dengan ${h.nama}. Konfirmasi dengan ciri di bawah.';

    return [
      const SizedBox(height: 18),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: warna.withValues(alpha: 0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(h.status == 'bukan_padi' || h.status == 'terlalu_jauh'
                    ? 'PEMERIKSAAN DIBATALKAN'
                    : 'HASIL PEMERIKSAAN FOTO',
                style: TextStyle(fontSize: 11, letterSpacing: 0.6, color: warna)),
            const SizedBox(height: 6),
            Text(judul,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: warna)),
            const SizedBox(height: 8),
            Text(pesan, style: const TextStyle(fontSize: 13, color: _hijauTua, height: 1.45)),
            const SizedBox(height: 14),
            _baris('Bagian tanaman dalam foto', '${(ciri.rasioTanaman * 100).toStringAsFixed(0)}%'),
            if (!ditolak) _baris('Luas daun berbercak', '${(ciri.rasioLesi * 100).toStringAsFixed(1)}%'),
            if (!ditolak) ...[
              _baris('Jumlah bercak terdeteksi', '${ciri.jumlahBercak}'),
              _baris('Kecerahan bercak', ciri.valLesi.toStringAsFixed(0)),
              _baris('Warna dasar bercak', ciri.hueLesi.toStringAsFixed(0)),
              _baris('Bercak berinti pucat', '${(ciri.pucat * 100).toStringAsFixed(1)}%'),
            ],
          ],
        ),
      ),
      if (!ditolak && _detail[h.kelas] != null) ...[
        const SizedBox(height: 14),
        _kartuPenyakit(h.kelas),
        const SizedBox(height: 14),
        _kartuKemungkinanLain(h.kelas),
        const SizedBox(height: 14),
        _kartuPengendalian(h.kelas),
      ],
      if (_hasilModel != null && !ditolak) ...[
        const SizedBox(height: 14),
        _kartuModel(_hasilModel!),
      ],
      const SizedBox(height: 16),
      const Text('Konfirmasi ciri yang terlihat',
          style: TextStyle(fontWeight: FontWeight.bold, color: _hijauTua)),
      const SizedBox(height: 4),
      const Text('Centang yang benar-benar tampak di tanaman.',
          style: TextStyle(fontSize: 12, color: Color(0xFF5A6B60))),
      ...List.generate(_ciriKonfirmasi.length, (i) {
        return CheckboxListTile(
          value: _ciriDicentang.contains(i),
          onChanged: (v) => setState(() {
            if (v == true) {
              _ciriDicentang.add(i);
            } else {
              _ciriDicentang.remove(i);
            }
          }),
          title: Text(_ciriKonfirmasi[i], style: const TextStyle(fontSize: 13)),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          dense: true,
          activeColor: _hijau,
        );
      }),
      if (_ciriDicentang.isNotEmpty)
        Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _hijauMuda,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            _ciriDicentang.length >= 2
                ? 'Ciri yang dicentang mendukung indikasi blas. Lanjutkan dengan tindakan pengendalian dan laporkan ke penyuluh.'
                : 'Satu ciri belum cukup. Periksa ciri lain atau kirim tanaman ke penyuluh.',
            style: const TextStyle(fontSize: 13, color: _hijauTua, height: 1.4),
          ),
        ),
      const SizedBox(height: 18),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F5F3),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Text(
          'Hasil foto adalah alat bantu, bukan diagnosis final. Ketepatan uji versi ini 71,5% pada 130 foto laboratorium; pada foto lapangan bisa lebih rendah. Selalu konfirmasi dengan penyuluh.',
          style: TextStyle(fontSize: 11, color: Color(0xFF5A6B60), height: 1.45),
        ),
      ),
    ];
  }

  Widget _baris(String label, String nilai) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 12.5, color: Color(0xFF5A6B60)))),
          Text(nilai, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _hijauTua)),
        ],
      ),
    );
  }

  Widget _kartuModel(HasilModel m) {
    final urut = m.peluang.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final yakin = m.teratas >= 0.6;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _hijau.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('MODEL FOTO (TFLITE, OFFLINE)',
              style: TextStyle(fontSize: 11, letterSpacing: 0.6, color: _hijauTua)),
          const SizedBox(height: 6),
          Text('${namaTampil[m.kelas]} — ${(m.teratas * 100).toStringAsFixed(0)}%',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: _hijauTua)),
          const SizedBox(height: 10),
          ...urut.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    SizedBox(
                      width: 130,
                      child: Text(namaTampil[e.key] ?? e.key,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF3C4C42))),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: e.value,
                          minHeight: 7,
                          backgroundColor: _hijauMuda,
                          valueColor: const AlwaysStoppedAnimation<Color>(_hijau),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 38,
                      child: Text('${(e.value * 100).toStringAsFixed(0)}%',
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF3C4C42))),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 4),
          Text(
            yakin
                ? 'Model cukup yakin. Tetap cocokkan dengan ciri yang terlihat di lapangan.'
                : 'Model belum yakin. Utamakan hasil pengukuran dan ciri yang kamu lihat langsung.',
            style: const TextStyle(fontSize: 11.5, color: Color(0xFF5A6B60), height: 1.4),
          ),
          const SizedBox(height: 6),
          const Text(
            'Model mengenali lima hal: blas, bercak daun coklat, hawar daun bakteri, tungro, dan daun sehat. Penyakit di luar itu belum dikenali.',
            style: TextStyle(fontSize: 11, color: Color(0xFF7A8A80), height: 1.35),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic>? _info(String kelas) {
    final d = _detail[kelas];
    return d is Map<String, dynamic> ? d : null;
  }

  Widget _kartuPenyakit(String kelas) {
    final d = _info(kelas);
    if (d == null) return const SizedBox();
    final gejala = (d['gejala'] as List? ?? []).cast<String>();
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _hijau.withValues(alpha: 0.2)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset(d['gambar'] as String, height: 180, width: double.infinity, fit: BoxFit.cover),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(d['nama'] as String? ?? '',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _hijauTua)),
                const SizedBox(height: 2),
                Text(d['penyebab'] as String? ?? '',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF5A6B60))),
                const SizedBox(height: 8),
                Text(d['deskripsi'] as String? ?? '',
                    style: const TextStyle(fontSize: 13, height: 1.5, color: _hijauTua)),
                if (gejala.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  const Text('Ciri yang perlu dicocokkan',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: _hijauTua)),
                  const SizedBox(height: 4),
                  ...gejala.map((g) => Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Text('• $g',
                            style: const TextStyle(fontSize: 12.5, height: 1.4, color: Color(0xFF3C4C42))),
                      )),
                ],
                const SizedBox(height: 6),
                const Text('Contoh foto gejala dari dataset latih.',
                    style: TextStyle(fontSize: 10, color: Color(0xFF8A9A90))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _kartuKemungkinanLain(String kelas) {
    final m = _hasilModel;
    if (m == null) return const SizedBox();
    final lain = m.peluang.entries.where((e) => e.key != kelas).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    if (lain.isEmpty) return const SizedBox();
    final d = _info(kelas);
    final mirip = (d?['mirip'] as List? ?? []).cast<String>();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _hijauMuda,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Kemungkinan lain yang gejalanya mirip',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _hijauTua)),
          const SizedBox(height: 6),
          ...lain.take(2).map((e) {
            final nama = namaTampil[e.key] ?? e.key;
            final catatan = mirip.contains(e.key) ? 'sering tertukar dengan hasil di atas' : 'kemungkinan kecil';
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('• $nama ${(e.value * 100).toStringAsFixed(0)}% — $catatan',
                  style: const TextStyle(fontSize: 12.5, height: 1.4, color: _hijauTua)),
            );
          }),
          const SizedBox(height: 4),
          const Text('Kalau ciri di lapangan tidak cocok dengan hasil utama, periksa kemungkinan ini lebih dulu.',
              style: TextStyle(fontSize: 11, color: Color(0xFF5A6B60), height: 1.4)),
        ],
      ),
    );
  }

  Widget _kartuPengendalian(String kelas) {
    final d = _info(kelas);
    if (d == null) return const SizedBox();
    final langkah = (d['pengendalian'] as List? ?? []).cast<String>();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD8E6DC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Rekomendasi pengendalian',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _hijauTua)),
          const SizedBox(height: 8),
          ...List.generate(langkah.length, (i) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(color: _hijau, shape: BoxShape.circle),
                      child: Text('${i + 1}',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(langkah[i],
                          style: const TextStyle(fontSize: 12.5, height: 1.45, color: _hijauTua)),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 4),
          const Text('Sebutkan nama bahan aktif saat membeli obat, dan ikuti dosis pada label atau anjuran penyuluh.',
              style: TextStyle(fontSize: 11, color: Color(0xFF5A6B60), height: 1.4)),
        ],
      ),
    );
  }
}
