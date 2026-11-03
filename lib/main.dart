// SIDEPI - Sistem Identifikasi Penyakit Padi
// Aplikasi pendamping petugas lapangan, bekerja tanpa internet.
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'galeri_acuan.dart';
import 'logika.dart';
import 'models.dart';
import 'penyimpanan.dart';
import 'periksa_foto.dart';
import 'tema.dart';

/// Padanan id basis pengetahuan ke kelas galeri foto acuan.
const Map<String, String> kelasAcuan = {
  'P01': 'blas',
  'P02': 'kresek',
  'P03': 'tungro',
};

// Kunci mengikuti kolom "kelompok" pada basis pengetahuan.
const Map<String, IconData> ikonBagian = {
  'daun': Icons.eco_outlined,
  'pelepah': Icons.grass_outlined,
  'malai': Icons.grain_outlined,
  'tanaman': Icons.spa_outlined,
};

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
      theme: temaSidepi(),
      home: const LayarMuat(),
    );
  }
}

/// Layar muat: memvalidasi basis pengetahuan sebelum aplikasi dipakai.
/// Warnanya sama dengan latar peluncur Android, jadi peralihan terasa menyambung.
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
    setState(() => galat = null);
    final mulai = DateTime.now();
    try {
      final teks = await rootBundle.loadString('assets/basis-pengetahuan.json');
      final kb = BasisPengetahuan.fromJson(jsonDecode(teks) as Map<String, dynamic>);
      final masalah = kb.validasi();
      if (masalah.isNotEmpty) {
        setState(() => galat = 'Basis pengetahuan tidak lolos validasi:\n${masalah.take(4).join('\n')}');
        return;
      }
      // beri jeda singkat supaya lambang sempat terlihat, bukan berkedip
      final lewat = DateTime.now().difference(mulai).inMilliseconds;
      if (lewat < 1400) await Future.delayed(Duration(milliseconds: 1400 - lewat));
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 420),
          pageBuilder: (_, __, ___) => BerandaScreen(kb: kb),
          transitionsBuilder: (_, anim, __, anak) => FadeTransition(opacity: anim, child: anak),
        ),
      );
    } catch (_) {
      if (mounted) setState(() => galat = 'Berkas basis pengetahuan tidak terbaca.');
    }
  }

  @override
  Widget build(BuildContext context) {
    const krim = W.kertas;
    return Scaffold(
      backgroundColor: W.hijau,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(flex: 5),
              Image.asset('assets/brand/logo_terang.png', width: 92, height: 92),
              const SizedBox(height: 24),
              const Text('SIDEPI',
                  style: TextStyle(
                      fontFamily: 'Inter', fontSize: 26, fontWeight: FontWeight.w800,
                      letterSpacing: 5, color: krim)),
              const SizedBox(height: 10),
              Text('Identifikasi penyakit dan hama tanaman padi',
                  style: TextStyle(
                      fontFamily: 'Inter', fontSize: 13.5, height: 1.5,
                      color: krim.withValues(alpha: 0.72))),
              const Spacer(flex: 6),
              if (galat == null) ...[
                const SizedBox(
                  width: 96,
                  child: LinearProgressIndicator(
                    minHeight: 2,
                    backgroundColor: Color(0x33F5F0E2),
                    valueColor: AlwaysStoppedAnimation(krim),
                  ),
                ),
                const SizedBox(height: 14),
                Text('Menyiapkan basis pengetahuan',
                    style: TextStyle(
                        fontFamily: 'Inter', fontSize: 11.5, letterSpacing: 0.3,
                        color: krim.withValues(alpha: 0.6))),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: krim,
                    borderRadius: BorderRadius.circular(R.sedang),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Aplikasi gagal disiapkan', style: T.subjudul),
                      const SizedBox(height: 6),
                      Text(galat!, style: T.kecil),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: FilledButton(
                          onPressed: _muat,
                          style: FilledButton.styleFrom(
                            backgroundColor: W.hijau,
                            minimumSize: const Size(120, 44),
                          ),
                          child: const Text('Coba lagi'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 22),
              Text('Dinas Pertanian dan Pangan\nKabupaten Sumba Timur',
                  style: TextStyle(
                      fontFamily: 'Inter', fontSize: 10.5, height: 1.5,
                      letterSpacing: 0.2, color: krim.withValues(alpha: 0.45))),
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
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          children: [
            Row(
              children: [
                Image.asset('assets/brand/logo_gelap.png', width: 26, height: 26),
                const SizedBox(width: 9),
                const Text('SIDEPI',
                    style: TextStyle(
                        fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w800,
                        letterSpacing: 3.4, color: W.hijau)),
                const Spacer(),
                const Lencana(teks: 'Luring', ikon: Icons.wifi_off_rounded),
              ],
            ),
            const SizedBox(height: 28),
            const Text('Periksa tanaman\npadi di lapangan.', style: T.judulBesar),
            const SizedBox(height: 10),
            Text('Dua cara pemeriksaan, keduanya berjalan di dalam ponsel tanpa sinyal.',
                style: T.kecil.copyWith(fontSize: 13)),
            const SizedBox(height: 22),
            KartuUtama(
              judul: 'Periksa lewat foto',
              keterangan: 'Ambil 1 sampai 3 foto bagian tanaman. Model mengenali tujuh kondisi penyakit dan hama.',
              ikon: Icons.camera_alt_outlined,
              labelAksi: 'Buka kamera',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PeriksaFotoScreen()),
              ),
            ),
            const SizedBox(height: 12),
            Kartu(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => PilihBagianScreen(kb: kb)),
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: W.hijauMuda,
                      borderRadius: BorderRadius.circular(R.kecil),
                    ),
                    child: const Icon(Icons.checklist_rounded, size: 21, color: W.hijauSedang),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Identifikasi lewat ciri', style: T.subjudul),
                        const SizedBox(height: 3),
                        Text('Centang gejala yang terlihat pada tanaman.', style: T.kecil),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, size: 20, color: W.redupMuda),
                ],
              ),
            ),
            const SizedBox(height: 26),
            const JudulBagian('Rujukan lapangan'),
            BarisMenu(
              ikon: Icons.photo_library_outlined,
              judul: 'Galeri contoh gejala',
              keterangan: '42 foto acuan, tujuh kondisi',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DaftarGaleriScreen()),
              ),
            ),
            const SizedBox(height: 9),
            BarisMenu(
              ikon: Icons.history_rounded,
              judul: 'Riwayat pemeriksaan',
              keterangan: 'Tersimpan di perangkat ini',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => RiwayatScreen(kb: kb)),
              ),
            ),
            const SizedBox(height: 9),
            BarisMenu(
              ikon: Icons.menu_book_outlined,
              judul: 'Panduan dan tentang',
              keterangan: 'Cara pakai, model, dan batasan',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => TentangScreen(kb: kb)),
              ),
            ),
            const SizedBox(height: 26),
            const Divider(color: W.garisTipis),
            const SizedBox(height: 14),
            Wrap(
              spacing: 14,
              runSpacing: 6,
              children: [
                _catatan('7 kelas'),
                _catatan('Akurasi uji 97,1%'),
                _catatan('Basis v${kb.versi}'),
              ],
            ),
            const SizedBox(height: 6),
            Text('Model uji pada foto laboratorium. Hasil lapangan bisa berbeda.',
                style: T.kecil.copyWith(fontSize: 11, color: W.redupMuda, height: 1.45)),
          ],
        ),
      ),
    );
  }

  Widget _catatan(String teks) => Text(teks,
      style: const TextStyle(
          fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w600, color: W.redup));
}

class PilihBagianScreen extends StatefulWidget {
  final BasisPengetahuan kb;
  const PilihBagianScreen({super.key, required this.kb});

  @override
  State<PilihBagianScreen> createState() => _PilihBagianScreenState();
}

class _PilihBagianScreenState extends State<PilihBagianScreen> {
  final Set<String> dipilih = {};

  @override
  Widget build(BuildContext context) {
    final bagian = <String, int>{};
    for (final g in widget.kb.gejala) {
      bagian[g.kelompok] = (bagian[g.kelompok] ?? 0) + 1;
    }
    final daftar = bagian.entries.toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Identifikasi lewat ciri')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 20),
              children: [
                const Text('Bagian mana yang\nmenunjukkan gejala?', style: T.judulBesar),
                const SizedBox(height: 10),
                Text('Boleh pilih lebih dari satu bagian.', style: T.kecil.copyWith(fontSize: 13)),
                const SizedBox(height: 22),
                ...daftar.map((e) {
                  final aktif = dipilih.contains(e.key);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Kartu(
                      onTap: () => setState(() {
                        if (aktif) {
                          dipilih.remove(e.key);
                        } else {
                          dipilih.add(e.key);
                        }
                      }),
                      warna: aktif ? W.hijauMuda : W.permukaan,
                      garisAtas: aktif ? W.hijauSedang : null,
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
                      child: Row(
                        children: [
                          Icon(ikonBagian[e.key] ?? Icons.eco_outlined,
                              size: 22, color: aktif ? W.hijau : W.redup),
                          const SizedBox(width: 13),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_namaBagian(e.key),
                                    style: T.subjudul.copyWith(color: aktif ? W.hijau : W.tinta)),
                                const SizedBox(height: 2),
                                Text('${e.value} ciri diamati', style: T.kecil),
                              ],
                            ),
                          ),
                          Icon(aktif ? Icons.check_circle : Icons.circle_outlined,
                              size: 20, color: aktif ? W.hijauSedang : W.garis),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
              decoration: const BoxDecoration(
                color: W.kertas,
                border: Border(top: BorderSide(color: W.garisTipis)),
              ),
              child: FilledButton(
                onPressed: dipilih.isEmpty
                    ? null
                    : () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => GejalaScreen(kb: widget.kb, bagian: dipilih.toList()),
                          ),
                        ),
                child: Text(dipilih.isEmpty
                    ? 'Pilih bagian tanaman'
                    : 'Lanjut, pilih ${dipilih.length} bagian'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _namaBagian(String k) => switch (k) {
        'daun' => 'Daun',
        'pelepah' => 'Batang dan pelepah',
        'malai' => 'Malai dan bulir',
        'tanaman' => 'Pertumbuhan tanaman',
        _ => k,
      };
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
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              children: [
                Text('Centang ciri yang benar-benar terlihat. Minimal dua ciri supaya penilaian berarti.',
                    style: T.kecil.copyWith(fontSize: 13)),
                const SizedBox(height: 14),
                ...daftar.map((g) {
                  final aktif = terpilih.contains(g.id);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Kartu(
                      onTap: () => setState(() {
                        if (aktif) {
                          terpilih.remove(g.id);
                        } else {
                          terpilih.add(g.id);
                        }
                      }),
                      warna: aktif ? W.hijauTipis : W.permukaan,
                      garisAtas: aktif ? W.hijauSedang : null,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 1),
                            child: Icon(aktif ? Icons.check_circle : Icons.circle_outlined,
                                size: 19, color: aktif ? W.hijau : W.garis),
                          ),
                          const SizedBox(width: 11),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(g.nama,
                                    style: T.badan.copyWith(
                                        fontSize: 13.5,
                                        fontWeight: aktif ? FontWeight.w600 : FontWeight.w400,
                                        color: aktif ? W.hijau : W.tinta)),
                                const SizedBox(height: 3),
                                Text('${g.id} · ${g.kelompok}',
                                    style: T.kecil.copyWith(fontSize: 11, color: W.redupMuda)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
              decoration: const BoxDecoration(
                color: W.kertas,
                border: Border(top: BorderSide(color: W.garisTipis)),
              ),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${terpilih.length}',
                          style: T.judul.copyWith(fontSize: 22, color: W.hijau)),
                      Text('ciri dipilih', style: T.kecil.copyWith(fontSize: 11)),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FilledButton(
                      onPressed: terpilih.length < 2
                          ? null
                          : () {
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
    final teratas = a.kemungkinan.isEmpty ? null : a.kemungkinan.first;
    final kelas = teratas == null ? null : kelasAcuan[teratas.penyakit.id];

    return Scaffold(
      appBar: AppBar(title: const Text('Hasil identifikasi')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 30),
        children: [
          if (teratas != null) _kartuHasil(teratas, utama != null),
          if (teratas == null) _kartuKosong(),
          const SizedBox(height: 16),
          _kartuPesan(a.pesan, utama != null),
          if (kelas != null) ...[
            const SizedBox(height: 20),
            const JudulBagian('Foto acuan lapangan'),
            Kartu(
              padding: const EdgeInsets.all(13),
              child: StripAcuan(kelas: kelas),
            ),
          ],
          if (teratas != null) ...[
            const SizedBox(height: 20),
            const JudulBagian('Pengendalian'),
            _bagianPengendalian(teratas.penyakit),
            if (teratas.penyakit.pencegahan.isNotEmpty) ...[
              const SizedBox(height: 16),
              const JudulBagian('Pencegahan'),
              ...teratas.penyakit.pencegahan.map((t) => _poin(t)),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: tersimpan ? null : _simpan,
                icon: Icon(tersimpan ? Icons.check : Icons.bookmark_border, size: 18),
                label: Text(tersimpan ? 'Tersimpan di riwayat' : 'Simpan ke riwayat'),
              ),
            ),
          ],
          if (a.kemungkinan.length > 1) ...[
            const SizedBox(height: 22),
            const JudulBagian('Kemungkinan lain'),
            ...a.kemungkinan.skip(1).map((h) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Kartu(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(h.penyakit.nama, style: T.subjudul.copyWith(fontSize: 14)),
                              const SizedBox(height: 2),
                              Text('keyakinan ${h.label.toLowerCase()}', style: T.kecil.copyWith(fontSize: 11.5)),
                            ],
                          ),
                        ),
                        Text('${h.skor}%',
                            style: T.subjudul.copyWith(fontSize: 15, color: W.redup)),
                      ],
                    ),
                  ),
                )),
          ],
          const SizedBox(height: 22),
          const Divider(color: W.garisTipis),
          const SizedBox(height: 12),
          Text(penafian, style: T.kecil.copyWith(fontSize: 11, color: W.redupMuda, height: 1.5)),
        ],
      ),
    );
  }

  Widget _kartuHasil(Hasil h, bool kuat) {
    final kunci = widget.terpilih
        .where((id) => (h.penyakit.bobotGejala[id] ?? 0) >= 3)
        .map((id) => widget.kb.gejalaById(id)?.nama ?? id)
        .toList();
    return Kartu(
      padding: const EdgeInsets.all(18),
      garisAtas: kuat ? W.hijauSedang : W.kunyit,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Lencana(
                teks: kuat ? 'Kecocokan ${h.label.toLowerCase()}' : 'Perlu verifikasi',
                warna: kuat ? W.hijauSedang : W.kunyit,
                ikon: kuat ? Icons.verified_outlined : Icons.error_outline,
              ),
              const Spacer(),
              Text('${h.skor}%',
                  style: T.judul.copyWith(fontSize: 26, color: W.hijau)),
            ],
          ),
          const SizedBox(height: 14),
          Text(h.penyakit.nama, style: T.judul.copyWith(fontSize: 23)),
          if (h.penyakit.namaIlmiah.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(h.penyakit.namaIlmiah,
                style: T.kecil.copyWith(fontStyle: FontStyle.italic, fontSize: 12)),
          ],
          const SizedBox(height: 14),
          BilahSkor(nilai: h.skor / 100, warna: kuat ? W.hijauSedang : W.kunyit),
          const SizedBox(height: 16),
          if (kunci.isNotEmpty) ...[
            Text('Ciri kunci yang cocok', style: T.mikro),
            const SizedBox(height: 7),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: kunci.map((t) => Lencana(teks: t, ikon: Icons.check)).toList(),
            ),
            const SizedBox(height: 14),
          ],
          Text(h.penyakit.deskripsi, style: T.badan.copyWith(fontSize: 13.5)),
          if (h.penyakit.penyebab.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Penyebab',
                    style: TextStyle(
                        fontFamily: 'Inter', fontSize: 11.5, color: W.redupMuda, height: 1.5)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(h.penyakit.penyebab,
                      style: T.kecil.copyWith(fontSize: 12, color: W.tinta)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _bagianPengendalian(Penyakit p) {
    final urutan = ['kultur', 'hayati', 'kimia'];
    final kunci = [
      ...urutan.where((k) => p.pengendalian.containsKey(k)),
      ...p.pengendalian.keys.where((k) => !urutan.contains(k)),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < kunci.length; i++) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Text('${i + 1}'.padLeft(2, '0'),
                    style: T.mikro.copyWith(color: W.hijauSedang)),
                const SizedBox(width: 8),
                Text(_judulPengendalian(kunci[i]), style: T.subjudul.copyWith(fontSize: 13.5)),
              ],
            ),
          ),
          ...p.pengendalian[kunci[i]]!.map((t) => _poin(t, menjorok: true)),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  String _judulPengendalian(String k) => switch (k) {
        'kultur' => 'Budidaya dan kultur teknis',
        'hayati' => 'Pengendalian hayati',
        'kimia' => 'Pengendalian kimia (pilihan terakhir)',
        _ => k,
      };

  Widget _poin(String teks, {bool menjorok = false}) {
    return Padding(
      padding: EdgeInsets.only(left: menjorok ? 26 : 0, bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 7, right: 8),
            child: Container(
              width: 4,
              height: 4,
              decoration: const BoxDecoration(color: W.redupMuda, shape: BoxShape.circle),
            ),
          ),
          Expanded(child: Text(teks, style: T.badan.copyWith(fontSize: 13))),
        ],
      ),
    );
  }

  Widget _kartuPesan(String pesan, bool kuat) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kuat ? W.hijauTipis : W.kunyitMuda,
        borderRadius: BorderRadius.circular(R.sedang),
        border: Border.all(color: kuat ? W.hijauMuda : W.kunyit.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(kuat ? Icons.info_outline : Icons.warning_amber_rounded,
              size: 18, color: kuat ? W.hijauSedang : W.kunyit),
          const SizedBox(width: 10),
          Expanded(
            child: Text(pesan,
                style: T.kecil.copyWith(
                    fontSize: 12.5, height: 1.45, color: kuat ? W.hijau : const Color(0xFF6B4A10))),
          ),
        ],
      ),
    );
  }

  Widget _kartuKosong() => Kartu(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.search_off_rounded, size: 32, color: W.redupMuda),
            const SizedBox(height: 10),
            Text('Belum ada penyakit yang cocok', style: T.subjudul),
            const SizedBox(height: 5),
            Text('Tambahkan ciri lain yang terlihat, atau konsultasikan dengan penyuluh pertanian.',
                textAlign: TextAlign.center, style: T.kecil),
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
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 30),
        children: [
          Text(penyakit.nama, style: T.judul),
          if (penyakit.namaIlmiah.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(penyakit.namaIlmiah,
                style: T.kecil.copyWith(fontStyle: FontStyle.italic, fontSize: 12.5)),
          ],
          const SizedBox(height: 16),
          Kartu(
            padding: const EdgeInsets.all(16),
            child: Text(penyakit.deskripsi, style: T.badan.copyWith(fontSize: 13.5)),
          ),
          if (penyakit.pengendalian.isNotEmpty) ...[
            const SizedBox(height: 22),
            const JudulBagian('Rekomendasi pengendalian'),
            ...penyakit.pengendalian.entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(e.key, style: T.subjudul.copyWith(fontSize: 13.5)),
                      const SizedBox(height: 5),
                      ...e.value.map((t) => Text('· $t',
                          style: T.badan.copyWith(fontSize: 13))),
                    ],
                  ),
                )),
          ],
          if (penyakit.sumber.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text('Sumber: ${penyakit.sumber}',
                style: T.kecil.copyWith(fontSize: 11, color: W.redupMuda)),
          ],
          const SizedBox(height: 10),
          Text(penafian, style: T.kecil.copyWith(fontSize: 11, color: W.redupMuda, height: 1.5)),
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

  Future<void> _hapusSemua() async {
    final ya = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: W.permukaan,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(R.sedang)),
        title: const Text('Hapus semua riwayat?', style: T.subjudul),
        content: Text('Catatan pemeriksaan yang tersimpan di perangkat ini akan hilang.',
            style: T.kecil.copyWith(fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus', style: TextStyle(color: W.merah)),
          ),
        ],
      ),
    );
    if (ya != true) return;
    await Penyimpanan.hapusSemua();
    await _muat();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat pemeriksaan'),
        actions: [
          if (daftar.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 21),
              tooltip: 'Hapus semua',
              onPressed: _hapusSemua,
            ),
        ],
      ),
      body: memuat
          ? const Center(child: CircularProgressIndicator())
          : daftar.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(36),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.history_rounded, size: 34, color: W.redupMuda),
                        const SizedBox(height: 12),
                        Text('Belum ada riwayat', style: T.subjudul),
                        const SizedBox(height: 6),
                        Text('Hasil pemeriksaan yang disimpan akan muncul di sini.',
                            textAlign: TextAlign.center, style: T.kecil),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  itemCount: daftar.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final r = daftar[i];
                    return Kartu(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(r.penyakitNama.isEmpty ? 'Tidak teridentifikasi' : r.penyakitNama,
                                    style: T.subjudul.copyWith(fontSize: 14)),
                                const SizedBox(height: 3),
                                Text('${_tanggal(r.waktu)} · ${r.gejala.length} ciri',
                                    style: T.kecil.copyWith(fontSize: 11.5)),
                              ],
                            ),
                          ),
                          Text('${r.skor}%',
                              style: T.subjudul.copyWith(fontSize: 14, color: W.hijauSedang)),
                        ],
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
    return Scaffold(
      appBar: AppBar(title: const Text('Panduan dan tentang')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 30),
        children: [
          const JudulBagian('Cara pakai'),
          _langkah('1', 'Amati tanaman yang menunjukkan gejala di lapangan.'),
          _langkah('2', 'Pilih bagian tanaman, lalu centang ciri yang benar-benar terlihat.'),
          _langkah('3', 'Baca hasil, bandingkan dengan foto acuan, lalu tentukan tindakan.'),
          _langkah('4', 'Bila keyakinan sedang atau lemah, konsultasikan dengan penyuluh.'),
          const SizedBox(height: 22),
          const JudulBagian('Model pengenalan foto'),
          Kartu(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _barisData('Kelas dikenali', '7 kondisi'),
                _barisData('Foto latih', '9.226 foto'),
                _barisData('Foto sumber asli', '1.652 foto'),
                _barisData('Akurasi uji', '97,1% (dengan pencerminan)'),
                _barisData('Ukuran model', '1,9 MB, jalan di perangkat'),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text('Angka akurasi berasal dari foto laboratorium dan internet, dibagi per foto asli '
              'supaya tidak ada foto kembar antara data latih dan uji. Pada foto lapangan, '
              'ketepatan bisa lebih rendah.',
              style: T.kecil.copyWith(fontSize: 11.5, height: 1.5)),
          const SizedBox(height: 22),
          const JudulBagian('Basis pengetahuan ciri'),
          Kartu(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _barisData('Versi', kb.versi),
                _barisData('Tanggal', kb.tanggalRilis),
                _barisData('Penyakit', '${kb.penyakit.length}'),
                _barisData('Ciri', '${kb.gejala.length}'),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text('Basis ciri masih berisi data contoh dan perlu diverifikasi penyuluh sebelum '
              'dipakai sebagai dasar penyemprotan.',
              style: T.kecil.copyWith(fontSize: 11.5, height: 1.5)),
          const SizedBox(height: 22),
          const JudulBagian('Batasan'),
          _poin('Hasil merupakan peringkat kemungkinan, bukan diagnosis pasti.'),
          _poin('Hama di luar penggerek batang dan putih palsu belum dikenali.'),
          _poin('Foto buram, terlalu jauh, atau bukan padi akan ditolak aplikasi.'),
          const SizedBox(height: 22),
          const JudulBagian('Tentang'),
          Text('SIDEPI dikembangkan untuk Dinas Pertanian dan Pangan Kabupaten Sumba Timur '
              'oleh Kurniawan Arif Renggi. Seluruh proses berjalan tanpa internet, tanpa akun, '
              'dan tanpa mengirim foto ke mana pun.',
              style: T.badan.copyWith(fontSize: 13)),
          const SizedBox(height: 18),
          Center(
            child: Column(
              children: [
                Image.asset('assets/brand/logo_gelap.png', width: 42, height: 42),
                const SizedBox(height: 8),
                Text('SIDEPI · v0.7.2', style: T.mikro),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _langkah(String n, String teks) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: W.hijauMuda,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(n,
                  style: const TextStyle(
                      fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w700, color: W.hijau)),
            ),
            const SizedBox(width: 11),
            Expanded(child: Text(teks, style: T.badan.copyWith(fontSize: 13))),
          ],
        ),
      );

  Widget _barisData(String label, String nilai) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: Text(label, style: T.kecil.copyWith(fontSize: 12.5))),
            const SizedBox(width: 12),
            Text(nilai,
                style: T.kecil.copyWith(
                    fontSize: 12.5, fontWeight: FontWeight.w600, color: W.tinta)),
          ],
        ),
      );

  Widget _poin(String teks) => Padding(
        padding: const EdgeInsets.only(bottom: 7),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 7, right: 8),
              child: Container(
                width: 4,
                height: 4,
                decoration: const BoxDecoration(color: W.redupMuda, shape: BoxShape.circle),
              ),
            ),
            Expanded(child: Text(teks, style: T.badan.copyWith(fontSize: 13))),
          ],
        ),
      );
}
