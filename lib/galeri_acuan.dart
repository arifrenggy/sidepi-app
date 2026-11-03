// Galeri foto acuan: contoh gejala tiap penyakit/hama untuk pembanding di lapangan.
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'model_foto.dart';

const _hijau = Color(0xFF1F6F43);
const _hijauTua = Color(0xFF14432A);
const _hijauMuda = Color(0xFFE8F3EC);

/// Memuat daftar foto acuan per kelas dari assets/acuan.json.
Future<Map<String, List<String>>> muatAcuan() async {
  final teks = await rootBundle.loadString('assets/acuan.json');
  final data = jsonDecode(teks) as Map<String, dynamic>;
  final hasil = <String, List<String>>{};
  data.forEach((k, v) => hasil[k] = (v as List).cast<String>());
  return hasil;
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
            const Text('Foto acuan dari lapangan',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: _hijauTua)),
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
                    child: Image.asset(daftar[i], width: tinggi, height: tinggi, fit: BoxFit.cover),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text('Ketuk foto untuk melihat lebih besar.',
                style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600)),
          ],
        );
      },
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
  final _kendali = PageController();
  int _halaman = 0;

  @override
  void initState() {
    super.initState();
    _halaman = widget.awal;
    _kendali.jumpToPage(widget.awal);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _hijau,
        foregroundColor: Colors.white,
        title: Text(widget.judul, style: const TextStyle(fontSize: 16)),
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
                    maxScale: 4,
                    child: Center(
                      child: Image.asset(daftar[i], fit: BoxFit.contain),
                    ),
                  ),
                ),
              ),
              Container(
                color: _hijauMuda,
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Foto ${_halaman + 1} dari ${daftar.length}',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: _hijauTua)),
                    const SizedBox(height: 4),
                    Text(
                      'Contoh gejala ${widget.judul}. Bandingkan dengan tanaman yang diperiksa; kalau cirinya tidak sama, curigai penyakit lain yang mirip.',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF3C4C42), height: 1.4),
                    ),
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
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text(
                  'Bandingkan tanaman yang diperiksa dengan foto di bawah. Kalau cirinya tidak sama, curigai penyakit lain yang mirip.',
                  style: TextStyle(fontSize: 12.5, color: Color(0xFF5A6B60), height: 1.45),
                ),
              ),
              ...peta.keys.map((k) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFD8E6DC)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(namaTampil[k] ?? k,
                            style: const TextStyle(fontWeight: FontWeight.bold, color: _hijauTua)),
                        const SizedBox(height: 8),
                        StripAcuan(kelas: k, tinggi: 84),
                      ],
                    ),
                  )),
            ],
          );
        },
      ),
    );
  }
}
