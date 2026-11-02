// SIDEPI - layar periksa foto (pengolahan citra klasik, tanpa internet).
import 'dart:io';
import 'package:flutter/material.dart';
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
    final judul = h.status == 'sehat'
        ? 'Daun tampak sehat'
        : h.status == 'belum_pasti'
            ? 'Belum dapat dipastikan'
            : 'Indikasi: ${h.nama}';
    final warna = h.status == 'sehat'
        ? _hijau
        : h.status == 'belum_pasti'
            ? const Color(0xFFB8860B)
            : const Color(0xFFA83A2C);
    final pesan = h.status == 'sehat'
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
            Text('HASIL PEMERIKSAAN FOTO',
                style: TextStyle(fontSize: 11, letterSpacing: 0.6, color: warna)),
            const SizedBox(height: 6),
            Text(judul,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: warna)),
            const SizedBox(height: 8),
            Text(pesan, style: const TextStyle(fontSize: 13, color: _hijauTua, height: 1.45)),
            const SizedBox(height: 14),
            _baris('Luas daun berbercak', '${(ciri.rasioLesi * 100).toStringAsFixed(1)}%'),
            _baris('Jumlah bercak terdeteksi', '${ciri.jumlahBercak}'),
            _baris('Kecerahan bercak', ciri.valLesi.toStringAsFixed(0)),
            _baris('Warna dasar bercak', ciri.hueLesi.toStringAsFixed(0)),
            _baris('Bercak berinti pucat', '${(ciri.pucat * 100).toStringAsFixed(1)}%'),
          ],
        ),
      ),
      if (_hasilModel != null) ...[
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
            'Model hanya mengenali blas, bercak daun coklat, dan daun sehat. Penyakit lain seperti tungro belum ada dalam model foto.',
            style: TextStyle(fontSize: 11, color: Color(0xFF7A8A80), height: 1.35),
          ),
        ],
      ),
    );
  }
}
