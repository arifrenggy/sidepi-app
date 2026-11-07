// Galeri foto acuan: contoh gejala tiap penyakit/hama untuk pembanding di lapangan.
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'model_foto.dart';
import 'tema.dart';

/// Memuat daftar foto acuan per kelas dari assets/acuan.json.
Future<Map<String, List<String>>> muatAcuan() async {
  final teks = await rootBundle.loadString('assets/acuan.json');
  final data = jsonDecode(teks) as Map<String, dynamic>;
  final hasil = <String, List<String>>{};
  data.forEach((k, v) => hasil[k] = (v as List).cast<String>());
  return hasil;
}


/// Foto acuan dengan cadangan: bila aset gagal dimuat, yang tampil penjelasan
/// singkat, bukan kotak putih kosong tanpa keterangan.
class FotoAcuan extends StatelessWidget {
  const FotoAcuan({super.key, required this.path, this.tinggi, this.lebar, this.penuh = false});

  final String path;
  final double? tinggi;
  final double? lebar;
  final bool penuh;

  @override
  Widget build(BuildContext context) {
    final bingkai = Container(
      width: lebar,
      height: tinggi,
      color: W.hijauMuda,
      alignment: Alignment.center,
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.broken_image_outlined, size: 20, color: W.redupMuda),
          SizedBox(height: 4),
          Text('Foto tidak terbaca',
              style: TextStyle(fontFamily: 'Inter', fontSize: 9.5, color: W.redupMuda)),
        ],
      ),
    );
    return Image.asset(
      path,
      width: lebar,
      height: tinggi,
      fit: penuh ? BoxFit.contain : BoxFit.cover,
      errorBuilder: (_, __, ___) => bingkai,
    );
  }
}

/// Deretan kecil foto acuan, dipakai sebagai pelengkap hasil analisis.
class StripAcuan extends StatelessWidget {
  const StripAcuan({super.key, required this.kelas, this.tinggi = 92});

  final String kelas;
  final double tinggi;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, List<String>>>(
      future: muatAcuan(),
      builder: (context, snap) {
        final daftar = snap.data?[kelas] ?? const <String>[];
        if (daftar.isEmpty) return const SizedBox();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Foto acuan lapangan', style: T.mikro),
            const SizedBox(height: 6),
            SizedBox(
              height: tinggi,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: daftar.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (_, i) => GestureDetector(
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => GaleriAcuanScreen(
                      kelas: kelas,
                      judul: namaTampil[kelas] ?? kelas,
                      awal: i,
                    ),
                  )),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: FotoAcuan(path: daftar[i], tinggi: tinggi, lebar: tinggi),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text('Ketuk untuk memperbesar.', style: T.kecil.copyWith(fontSize: 10.5, color: W.redupMuda)),
          ],
        );
      },
    );
  }
}

/// Baris kecil berisi tautan ke catatan sumber dan lisensi foto acuan.
class SumberFoto extends StatelessWidget {
  const SumberFoto({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _buka(context),
      child: Text('Sumber foto',
          style: T.kecil.copyWith(
              fontSize: 10.5, color: W.hijau, decoration: TextDecoration.underline)),
    );
  }

  Future<void> _buka(BuildContext context) async {
    final teks = await rootBundle.loadString('assets/acuan/sumber.txt');
    if (!context.mounted) return;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sumber dan lisensi foto'),
        content: SingleChildScrollView(
          child: Text(teks,
              style: const TextStyle(fontFamily: 'Inter', fontSize: 11.5, height: 1.5)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Tutup')),
        ],
      ),
    );
  }
}

/// Galeri penuh satu penyakit, bisa digeser dan diperbesar.
class GaleriAcuanScreen extends StatefulWidget {
  const GaleriAcuanScreen({super.key, required this.kelas, required this.judul, this.awal = 0});

  final String kelas;
  final String judul;
  final int awal;

  @override
  State<GaleriAcuanScreen> createState() => _GaleriAcuanScreenState();
}

class _GaleriAcuanScreenState extends State<GaleriAcuanScreen> {
  late final PageController _kendali = PageController(initialPage: widget.awal);
  late int _halaman = widget.awal;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: W.kertas,
        foregroundColor: W.tinta,
        title: Text(widget.judul),
      ),
      body: FutureBuilder<Map<String, List<String>>>(
        future: muatAcuan(),
        builder: (context, snap) {
          final daftar = snap.data?[widget.kelas] ?? const <String>[];
          if (daftar.isEmpty) {
            return const Center(child: Text('Foto acuan belum tersedia.'));
          }
          return Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _kendali,
                  itemCount: daftar.length,
                  onPageChanged: (i) => setState(() => _halaman = i),
                  itemBuilder: (_, i) => InteractiveViewer(
                    minScale: 1,
                    maxScale: 5,
                    child: SizedBox.expand(
                      child: Image.asset(
                        daftar[i],
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Center(
                          child: Text('Foto tidak terbaca.',
                              style: TextStyle(fontFamily: 'Inter', fontSize: 12)),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                color: W.permukaan,
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Foto ${_halaman + 1} dari ${daftar.length}', style: T.mikro),
                    const SizedBox(height: 6),
                    Text(
                      'Contoh gejala ${widget.judul}. Kalau ciri pada tanaman tidak sama dengan foto ini, curigai penyakit lain yang mirip.',
                      style: T.kecil.copyWith(fontSize: 12.5, height: 1.45),
                    ),
                    const SizedBox(height: 6),
                    const SumberFoto(),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Daftar semua penyakit/hama yang punya foto acuan.
class DaftarGaleriScreen extends StatelessWidget {
  const DaftarGaleriScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Galeri Contoh Gejala')),
      body: FutureBuilder<Map<String, List<String>>>(
        future: muatAcuan(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final peta = snap.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Text(
                  'Bandingkan tanaman yang diperiksa dengan foto di bawah. Kalau cirinya tidak sama, curigai penyakit lain yang mirip.',
                  style: T.kecil.copyWith(fontSize: 12.5, height: 1.45),
                ),
              ),
              ...peta.keys.map((k) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: W.permukaan,
                      borderRadius: BorderRadius.circular(R.sedang),
                      border: Border.all(color: W.garisTipis),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(namaTampil[k] ?? k, style: T.subjudul.copyWith(fontSize: 14)),
                        const SizedBox(height: 8),
                        StripAcuan(kelas: k, tinggi: 84),
                      ],
                    ),
                  )),
              const SizedBox(height: 4),
              const SumberFoto(),
            ],
          );
        },
      ),
    );
  }
}
