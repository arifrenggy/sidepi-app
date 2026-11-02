// SIDEPI - Sistem Identifikasi Penyakit Padi
// Aplikasi pendamping petugas lapangan, bekerja tanpa internet.
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'logika.dart';
import 'models.dart';
import 'penyimpanan.dart';
import 'periksa_foto.dart';

const Color hijau = Color(0xFF1F6F43);
const Color hijauMuda = Color(0xFFE8F3EC);
const Color hijauTua = Color(0xFF14432A);

void main() {
  runApp(const SidepiApp());
}

class SidepiApp extends StatelessWidget {
  const SidepiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SIDEPI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: hijau),
        scaffoldBackgroundColor: const Color(0xFFF7F9F7),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: hijau,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      home: const LayarMuat(),
    );
  }
}

/// Memuat dan memvalidasi basis pengetahuan sebelum aplikasi dipakai.
class LayarMuat extends StatefulWidget {
  const LayarMuat({super.key});

  @override
  State<LayarMuat> createState() => _LayarMuatState();
}

class _LayarMuatState extends State<LayarMuat> {
  String? galat;

  @override
  void initState() {
    super.initState();
    _muat();
  }

  Future<void> _muat() async {
    try {
      final teks = await rootBundle.loadString('assets/basis-pengetahuan.json');
      final kb = BasisPengetahuan.fromJson(jsonDecode(teks) as Map<String, dynamic>);
      final masalah = kb.validasi();
      if (masalah.isNotEmpty) {
        setState(() => galat = 'Basis pengetahuan tidak lolos validasi:\n${masalah.take(4).join('\n')}');
        return;
      }
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => BerandaScreen(kb: kb)),
      );
    } catch (e) {
      setState(() => galat = 'Gagal memuat basis pengetahuan: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: galat == null
              ? const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 42,
                      height: 42,
                      child: CircularProgressIndicator(color: hijau),
                    ),
                    SizedBox(height: 18),
                    Text('Menyiapkan basis pengetahuan...'),
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.redAccent, size: 44),
                    const SizedBox(height: 14),
                    Text(galat!, textAlign: TextAlign.center),
                  ],
                ),
        ),
      ),
    );
  }
}

class BerandaScreen extends StatelessWidget {
  final BasisPengetahuan kb;
  const BerandaScreen({super.key, required this.kb});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('SIDEPI',
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: hijauTua)),
              const SizedBox(height: 6),
              const Text('Identifikasi penyakit tanaman padi',
                  style: TextStyle(fontSize: 15, color: Color(0xFF5A6B60))),
              const SizedBox(height: 24),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: hijauMuda,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.eco, color: hijau, size: 22),
                          SizedBox(width: 8),
                          Text('Cara pakai',
                              style: TextStyle(fontWeight: FontWeight.bold, color: hijauTua)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _langkah('1', 'Amati tanaman yang sakit di lapangan.'),
                      _langkah('2', 'Centang ciri-ciri yang benar-benar terlihat.'),
                      _langkah('3', 'Baca hasil, lalu konsultasikan dengan penyuluh.'),
                      const Spacer(),
                      Text('Basis pengetahuan versi ${kb.versi}',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF5A6B60))),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => PilihBagianScreen(kb: kb)),
                ),
                icon: const Icon(Icons.search),
                label: const Text('Mulai Identifikasi'),
                style: FilledButton.styleFrom(
                  backgroundColor: hijau,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PeriksaFotoScreen()),
                ),
                icon: const Icon(Icons.photo_camera),
                label: const Text('Periksa Foto Daun'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  foregroundColor: hijauTua,
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => RiwayatScreen(kb: kb)),
                ),
                icon: const Icon(Icons.history),
                label: const Text('Riwayat Identifikasi'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  foregroundColor: hijauTua,
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => TentangScreen(kb: kb)),
                ),
                child: const Text('Panduan dan tentang aplikasi'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _langkah(String n, String teks) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: hijau, shape: BoxShape.circle),
            child: Text(n,
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(teks, style: const TextStyle(fontSize: 14, color: hijauTua))),
        ],
      ),
    );
  }
}

class PilihBagianScreen extends StatefulWidget {
  final BasisPengetahuan kb;
  const PilihBagianScreen({super.key, required this.kb});

  @override
  State<PilihBagianScreen> createState() => _PilihBagianScreenState();
}

class _PilihBagianScreenState extends State<PilihBagianScreen> {
  final Set<String> dipilih = {};

  static const bagian = {
    'daun': 'Daun',
    'pelepah': 'Batang / Pelepah',
    'malai': 'Malai / Bulir',
    'tanaman': 'Tanaman utuh',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bagian tanaman')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Bagian tanaman mana yang menunjukkan gejala?',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            const Text('Boleh pilih lebih dari satu.',
                style: TextStyle(fontSize: 13, color: Color(0xFF5A6B60))),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.35,
                children: bagian.entries.map((e) {
                  final aktif = dipilih.contains(e.key);
                  return InkWell(
                    onTap: () => setState(() {
                      if (aktif) {
                        dipilih.remove(e.key);
                      } else {
                        dipilih.add(e.key);
                      }
                    }),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      decoration: BoxDecoration(
                        color: aktif ? hijauMuda : Colors.white,
                        border: Border.all(color: aktif ? hijau : const Color(0xFFE2E6E3), width: aktif ? 2 : 1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            e.key == 'daun'
                                ? Icons.eco
                                : e.key == 'pelepah'
                                    ? Icons.grass
                                    : e.key == 'malai'
                                        ? Icons.spa
                                        : Icons.local_florist,
                            color: aktif ? hijau : const Color(0xFF8A9A90),
                            size: 30,
                          ),
                          const SizedBox(height: 8),
                          Text(e.value,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: aktif ? hijauTua : const Color(0xFF5A6B60),
                                fontWeight: aktif ? FontWeight.bold : FontWeight.normal,
                              )),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            FilledButton(
              onPressed: dipilih.isEmpty
                  ? null
                  : () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => GejalaScreen(kb: widget.kb, bagian: dipilih.toList()),
                        ),
                      ),
              style: FilledButton.styleFrom(
                backgroundColor: hijau,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Lanjut pilih ciri'),
            ),
          ],
        ),
      ),
    );
  }
}

class GejalaScreen extends StatefulWidget {
  final BasisPengetahuan kb;
  final List<String> bagian;
  const GejalaScreen({super.key, required this.kb, required this.bagian});

  @override
  State<GejalaScreen> createState() => _GejalaScreenState();
}

class _GejalaScreenState extends State<GejalaScreen> {
  final Set<String> terpilih = {};

  @override
  Widget build(BuildContext context) {
    final daftar = widget.kb.gejala.where((g) => widget.bagian.contains(g.kelompok)).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Pilih ciri yang terlihat')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 18, color: Color(0xFF5A6B60)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Centang ciri yang benar-benar ada di tanaman. Minimal 2 ciri.',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              itemCount: daftar.length,
              itemBuilder: (context, i) {
                final g = daftar[i];
                final aktif = terpilih.contains(g.id);
                return Card(
                  elevation: 0,
                  color: aktif ? hijauMuda : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: aktif ? hijau : const Color(0xFFE2E6E3)),
                  ),
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: CheckboxListTile(
                    value: aktif,
                    onChanged: (v) => setState(() {
                      if (v == true) {
                        terpilih.add(g.id);
                      } else {
                        terpilih.remove(g.id);
                      }
                    }),
                    activeColor: hijau,
                    title: Text(g.nama, style: const TextStyle(fontSize: 14.5)),
                    subtitle: Text(g.id, style: const TextStyle(fontSize: 11)),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Column(
                children: [
                  Text('${terpilih.length} ciri dipilih',
                      style: const TextStyle(fontSize: 13, color: Color(0xFF5A6B60))),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: terpilih.length < 2
                          ? null
                          : () async {
                              final analisis = hitungHasil(widget.kb, terpilih);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => HasilScreen(
                                    kb: widget.kb,
                                    analisis: analisis,
                                    terpilih: Set.of(terpilih),
                                  ),
                                ),
                              );
                            },
                      style: FilledButton.styleFrom(
                        backgroundColor: hijau,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Lihat hasil'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HasilScreen extends StatefulWidget {
  final BasisPengetahuan kb;
  final Analisis analisis;
  final Set<String> terpilih;
  const HasilScreen({super.key, required this.kb, required this.analisis, required this.terpilih});

  @override
  State<HasilScreen> createState() => _HasilScreenState();
}

class _HasilScreenState extends State<HasilScreen> {
  bool tersimpan = false;

  Future<void> _simpan() async {
    final h = widget.analisis.kemungkinan.isEmpty ? null : widget.analisis.kemungkinan.first;
    if (h == null) return;
    await Penyimpanan.simpan(Riwayat(
      waktu: DateTime.now().toIso8601String(),
      gejala: widget.terpilih.toList(),
      penyakitId: h.penyakit.id,
      penyakitNama: h.penyakit.nama,
      skor: h.skor,
    ));
    if (!mounted) return;
    setState(() => tersimpan = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Hasil disimpan ke riwayat')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.analisis;
    final utama = a.utama;
    return Scaffold(
      appBar: AppBar(title: const Text('Hasil identifikasi')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          if (utama != null) _kartuUtama(utama),
          if (utama == null && a.kemungkinan.isNotEmpty) _kartuDugaan(a.kemungkinan.first),
          if (a.kemungkinan.isEmpty) _kartuKosong(),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE8D9AE)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.warning_amber_rounded, size: 20, color: Color(0xFF9A7B1A)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(a.pesan, style: const TextStyle(fontSize: 13.5, color: Color(0xFF6B5510))),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (a.kemungkinan.length > 1) ...[
            const Text('Kemungkinan lain',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ...a.kemungkinan.skip(1).map((h) => Card(
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Color(0xFFE2E6E3)),
                  ),
                  child: ListTile(
                    title: Text(h.penyakit.nama),
                    subtitle: Text('${h.penyakit.namaIlmiah} • keyakinan ${h.label}'),
                    trailing: Text('${h.skor}%',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: hijau)),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => DetailScreen(penyakit: h.penyakit)),
                    ),
                  ),
                )),
          ],
          const SizedBox(height: 8),
          if (a.kemungkinan.isNotEmpty)
            OutlinedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => DetailScreen(penyakit: a.kemungkinan.first.penyakit)),
              ),
              icon: const Icon(Icons.menu_book),
              label: const Text('Lihat gambar dan pengendalian'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                foregroundColor: hijauTua,
              ),
            ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: tersimpan || a.kemungkinan.isEmpty ? null : _simpan,
            icon: Icon(tersimpan ? Icons.check : Icons.save_alt),
            label: Text(tersimpan ? 'Tersimpan di riwayat' : 'Simpan ke riwayat'),
            style: FilledButton.styleFrom(
              backgroundColor: hijau,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
          const SizedBox(height: 14),
          const Text(penafian,
              style: TextStyle(fontSize: 11.5, color: Color(0xFF7A8A80), height: 1.4)),
        ],
      ),
    );
  }

  Widget _kartuUtama(Hasil h) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: hijauMuda,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: hijau, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Hasil utama', style: TextStyle(fontSize: 12, color: Color(0xFF5A6B60))),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(h.penyakit.nama,
                          style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold, color: hijauTua)),
                      Text(h.penyakit.namaIlmiah,
                          style: const TextStyle(fontSize: 12.5, fontStyle: FontStyle.italic, color: Color(0xFF5A6B60))),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: hijau, borderRadius: BorderRadius.circular(10)),
                  child: Text('${h.skor}%',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: hijauTua, borderRadius: BorderRadius.circular(20)),
                  child: Text('Keyakinan: ${h.label}',
                      style: const TextStyle(color: Colors.white, fontSize: 11.5)),
                ),
                const SizedBox(width: 8),
                Text('${h.cocokKunci} ciri kunci cocok',
                    style: const TextStyle(fontSize: 11.5, color: Color(0xFF5A6B60))),
              ],
            ),
            const SizedBox(height: 10),
            Text(h.penyakit.deskripsi,
                style: const TextStyle(fontSize: 13.5, height: 1.45)),
          ],
        ),
      );

  Widget _kartuDugaan(Hasil h) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E6E3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Dugaan teratas (perlu verifikasi)',
                style: TextStyle(fontSize: 12, color: Color(0xFF5A6B60))),
            const SizedBox(height: 4),
            Text(h.penyakit.nama,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: hijauTua)),
            Text(h.penyakit.namaIlmiah,
                style: const TextStyle(fontSize: 12.5, fontStyle: FontStyle.italic, color: Color(0xFF5A6B60))),
            const SizedBox(height: 10),
            Text('Skor ${h.skor}% • keyakinan ${h.label}',
                style: const TextStyle(fontSize: 13.5)),
            const SizedBox(height: 8),
            Text(h.penyakit.deskripsi, style: const TextStyle(fontSize: 13.5, height: 1.45)),
          ],
        ),
      );

  Widget _kartuKosong() => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E6E3)),
        ),
        child: const Column(
          children: [
            Icon(Icons.search_off, size: 36, color: Color(0xFF8A9A90)),
            SizedBox(height: 10),
            Text('Belum ada penyakit yang cocok', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 6),
            Text('Tambahkan ciri lain yang terlihat, atau hubungi penyuluh pertanian.',
                textAlign: TextAlign.center, style: TextStyle(fontSize: 13)),
          ],
        ),
      );
}

class DetailScreen extends StatelessWidget {
  final Penyakit penyakit;
  const DetailScreen({super.key, required this.penyakit});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(penyakit.nama)),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            height: 150,
            decoration: BoxDecoration(
              color: hijauMuda,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFD5E6DA)),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.image_outlined, size: 34, color: Color(0xFF8A9A90)),
                  SizedBox(height: 6),
                  Text('Foto tanaman terserang\n(melengkapi dari dinas)',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11.5, color: Color(0xFF7A8A80))),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(penyakit.namaIlmiah,
              style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: Color(0xFF5A6B60))),
          const SizedBox(height: 4),
          Text('Penyebab: ${penyakit.penyebab}', style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 12),
          Text(penyakit.deskripsi, style: const TextStyle(fontSize: 14, height: 1.5)),
          const SizedBox(height: 18),
          const Text('Rekomendasi pengendalian',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: hijauTua)),
          const SizedBox(height: 8),
          ...penyakit.pengendalian.entries.map((e) {
            final judul = switch (e.key) {
              'kultur' => '1. Budidaya dan kultur teknis',
              'hayati' => '2. Pengendalian hayati',
              'kimia' => '3. Pengendalian kimia (pilihan terakhir)',
              _ => e.key,
            };
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(judul, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  ...e.value.map((t) => Padding(
                        padding: const EdgeInsets.only(bottom: 3, left: 4),
                        child: Text('• $t', style: const TextStyle(fontSize: 13, height: 1.4)),
                      )),
                ],
              ),
            );
          }),
          if (penyakit.pencegahan.isNotEmpty) ...[
            const Text('Pencegahan',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: hijauTua)),
            const SizedBox(height: 8),
            ...penyakit.pencegahan.map((t) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('• $t', style: const TextStyle(fontSize: 13, height: 1.4)),
                )),
          ],
          const SizedBox(height: 18),
          if (penyakit.sumber.isNotEmpty)
            Text('Sumber: ${penyakit.sumber}',
                style: const TextStyle(fontSize: 11.5, color: Color(0xFF7A8A80))),
          const SizedBox(height: 10),
          const Text(penafian, style: TextStyle(fontSize: 11.5, color: Color(0xFF7A8A80), height: 1.4)),
        ],
      ),
    );
  }
}

class RiwayatScreen extends StatefulWidget {
  final BasisPengetahuan kb;
  const RiwayatScreen({super.key, required this.kb});

  @override
  State<RiwayatScreen> createState() => _RiwayatScreenState();
}

class _RiwayatScreenState extends State<RiwayatScreen> {
  List<Riwayat> daftar = [];
  bool memuat = true;

  @override
  void initState() {
    super.initState();
    _muat();
  }

  Future<void> _muat() async {
    final d = await Penyimpanan.muat();
    if (!mounted) return;
    setState(() {
      daftar = d;
      memuat = false;
    });
  }

  String _tanggal(String iso) {
    try {
      final d = DateTime.parse(iso).toLocal();
      String dua(int n) => n.toString().padLeft(2, '0');
      return '${dua(d.day)}/${dua(d.month)}/${d.year} ${dua(d.hour)}:${dua(d.minute)}';
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat identifikasi'),
        actions: [
          if (daftar.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Hapus semua',
              onPressed: () async {
                await Penyimpanan.hapusSemua();
                await _muat();
              },
            ),
        ],
      ),
      body: memuat
          ? const Center(child: CircularProgressIndicator(color: hijau))
          : daftar.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(28),
                    child: Text('Belum ada riwayat. Hasil identifikasi yang disimpan akan muncul di sini.',
                        textAlign: TextAlign.center),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(14),
                  itemCount: daftar.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final r = daftar[i];
                    return Card(
                      elevation: 0,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Color(0xFFE2E6E3)),
                      ),
                      child: ListTile(
                        title: Text(r.penyakitNama.isEmpty ? 'Tidak teridentifikasi' : r.penyakitNama),
                        subtitle: Text('${_tanggal(r.waktu)} • ${r.gejala.length} ciri dipilih'),
                        trailing: Text('${r.skor}%',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: hijau)),
                      ),
                    );
                  },
                ),
    );
  }
}

class TentangScreen extends StatelessWidget {
  final BasisPengetahuan kb;
  const TentangScreen({super.key, required this.kb});

  @override
  Widget build(BuildContext context) {
    final jumlahGejala = kb.gejala.length;
    final jumlahPenyakit = kb.penyakit.length;
    return Scaffold(
      appBar: AppBar(title: const Text('Panduan dan tentang')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const Text('Cara pakai', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text(
            '1. Amati tanaman yang menunjukkan gejala di lapangan.\n'
            '2. Pilih bagian tanaman yang sakit, lalu centang ciri yang benar-benar terlihat.\n'
            '3. Baca hasil: nama penyakit, tingkat keyakinan, gambar, dan rekomendasi pengendalian.\n'
            '4. Bila keyakinan sedang atau lemah, konsultasikan dengan penyuluh sebelum bertindak.',
            style: TextStyle(fontSize: 13.5, height: 1.6),
          ),
          const SizedBox(height: 20),
          const Text('Tentang aplikasi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            'SIDEPI membantu petugas lapangan mengenali penyakit tanaman padi dengan '
            'mencentang ciri yang terlihat. Aplikasi bekerja tanpa internet dan tidak '
            'memotret tanaman.\n\n'
            'Versi aplikasi: 0.1.0\n'
            'Basis pengetahuan: ${kb.versi} (${kb.tanggalRilis})\n'
            'Isi: $jumlahGejala ciri, $jumlahPenyakit penyakit',
            style: const TextStyle(fontSize: 13.5, height: 1.6),
          ),
          const SizedBox(height: 20),
          const Text('Penafian', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text(
            'Hasil identifikasi bersifat alat bantu, bukan diagnosis final. '
            'Keputusan pengendalian, terutama penggunaan pestisida, tetap mengikuti '
            'arahan penyuluh dan label produk.',
            style: TextStyle(fontSize: 13.5, height: 1.6),
          ),
          const SizedBox(height: 20),
          const Text('Pengembang', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text(
            'Kurniawan Arif Renggi (2123036) — mahasiswa magang, Teknik Informatika UKWMS Waingapu.\n'
            'Untuk: Dinas Pertanian dan Pangan Kabupaten Sumba Timur.',
            style: TextStyle(fontSize: 13.5, height: 1.6),
          ),
        ],
      ),
    );
  }
}
