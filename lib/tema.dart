// Token desain SIDEPI.
// Warna diambil dari lanskap sawah Sumba: hijau daun tua, kertas krem, dan kunyit
// sebagai satu-satunya aksen peringatan. Tidak ada gradien, tidak ada bayangan
// tersebar: kedalaman dibangun dari warna bidang dan garis rambut.
import 'package:flutter/material.dart';

class W {
  static const hijau = Color(0xFF0F3D2E);
  static const hijauSedang = Color(0xFF1E6B4F);
  static const hijauMuda = Color(0xFFE4EDE6);
  static const hijauTipis = Color(0xFFF0F5F1);

  static const kertas = Color(0xFFF4F1E9);
  static const permukaan = Color(0xFFFFFFFF);
  static const garis = Color(0xFFD9D4C6);
  static const garisTipis = Color(0xFFE8E4D8);

  static const tinta = Color(0xFF131A16);
  static const redup = Color(0xFF5C6A62);
  static const redupMuda = Color(0xFF8B968E);

  static const kunyit = Color(0xFFA96A15);
  static const kunyitMuda = Color(0xFFFBF1DC);
  static const merah = Color(0xFF97352A);
  static const merahMuda = Color(0xFFF7E5E1);
}

class R {
  static const kecil = 10.0;
  static const sedang = 16.0;
  static const besar = 24.0;
}

class T {
  static const judulBesar = TextStyle(
      fontFamily: 'Inter', fontSize: 27, height: 1.15, fontWeight: FontWeight.w800,
      letterSpacing: -0.7, color: W.tinta);
  static const judul = TextStyle(
      fontFamily: 'Inter', fontSize: 20, height: 1.2, fontWeight: FontWeight.w700,
      letterSpacing: -0.35, color: W.tinta);
  static const subjudul = TextStyle(
      fontFamily: 'Inter', fontSize: 15.5, height: 1.3, fontWeight: FontWeight.w600, color: W.tinta);
  static const badan = TextStyle(
      fontFamily: 'Inter', fontSize: 14, height: 1.5, fontWeight: FontWeight.w400, color: W.tinta);
  static const kecil = TextStyle(
      fontFamily: 'Inter', fontSize: 12.5, height: 1.45, fontWeight: FontWeight.w400, color: W.redup);
  static const mikro = TextStyle(
      fontFamily: 'Inter', fontSize: 10.5, height: 1.2, fontWeight: FontWeight.w600,
      letterSpacing: 1.1, color: W.redup);
}

ThemeData temaSidepi() {
  const skema = ColorScheme.light(
    primary: W.hijau,
    onPrimary: W.kertas,
    secondary: W.kunyit,
    onSecondary: W.permukaan,
    surface: W.permukaan,
    onSurface: W.tinta,
    error: W.merah,
    onError: W.permukaan,
    outline: W.garis,
  );
  return ThemeData(
    useMaterial3: true,
    fontFamily: 'Inter',
    colorScheme: skema,
    scaffoldBackgroundColor: W.kertas,
    splashFactory: InkSparkle.splashFactory,
    appBarTheme: const AppBarTheme(
      backgroundColor: W.kertas,
      foregroundColor: W.tinta,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
          fontFamily: 'Inter', fontSize: 17, fontWeight: FontWeight.w700,
          letterSpacing: -0.3, color: W.tinta),
    ),
    dividerTheme: const DividerThemeData(color: W.garisTipis, thickness: 1, space: 1),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: W.hijau,
        foregroundColor: W.kertas,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(R.sedang - 2)),
        textStyle: const TextStyle(
            fontFamily: 'Inter', fontSize: 14.5, fontWeight: FontWeight.w600, letterSpacing: -0.1),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: W.hijau,
        minimumSize: const Size.fromHeight(52),
        side: const BorderSide(color: W.garis),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(R.sedang - 2)),
        textStyle: const TextStyle(
            fontFamily: 'Inter', fontSize: 14.5, fontWeight: FontWeight.w600, letterSpacing: -0.1),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: W.hijau,
        textStyle: const TextStyle(fontFamily: 'Inter', fontSize: 13.5, fontWeight: FontWeight.w600),
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      side: const BorderSide(color: W.garis, width: 1.6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: W.hijau,
      contentTextStyle: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: W.kertas),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(R.kecil)),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: W.hijauSedang),
  );
}

/// Bidang dasar: putih, garis rambut, sudut sedang. Tanpa bayangan.
class Kartu extends StatelessWidget {
  const Kartu({super.key, required this.child, this.padding, this.warna, this.garisAtas, this.onTap});

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? warna;
  final Color? garisAtas;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isi = Container(
      decoration: BoxDecoration(
        color: warna ?? W.permukaan,
        borderRadius: BorderRadius.circular(R.sedang),
        border: Border.all(color: garisAtas == null ? W.garisTipis : garisAtas!.withValues(alpha: 0.5)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(R.sedang),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(padding: padding ?? const EdgeInsets.all(16), child: child),
          ),
        ),
      ),
    );
    return isi;
  }
}

/// Kartu aksi utama: satu-satunya bidang gelap di layar, jadi perhatian jatuh ke sini.
class KartuUtama extends StatelessWidget {
  const KartuUtama({
    super.key,
    required this.judul,
    required this.keterangan,
    required this.ikon,
    required this.onTap,
    this.labelAksi = 'Mulai',
  });

  final String judul;
  final String keterangan;
  final IconData ikon;
  final VoidCallback onTap;
  final String labelAksi;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(R.besar - 2),
      child: Material(
        color: W.hijau,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: W.kertas.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(R.kecil),
                  ),
                  child: Icon(ikon, color: W.kertas, size: 23),
                ),
                const SizedBox(height: 18),
                Text(judul,
                    style: const TextStyle(
                        fontFamily: 'Inter', fontSize: 21, height: 1.2, fontWeight: FontWeight.w700,
                        letterSpacing: -0.4, color: W.kertas)),
                const SizedBox(height: 6),
                Text(keterangan,
                    style: TextStyle(
                        fontFamily: 'Inter', fontSize: 13, height: 1.45,
                        color: W.kertas.withValues(alpha: 0.78))),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(labelAksi,
                        style: const TextStyle(
                            fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600,
                            color: W.kertas)),
                    const SizedBox(width: 6),
                    Icon(Icons.arrow_forward, size: 16, color: W.kertas.withValues(alpha: 0.9)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Baris menu ringkas untuk aksi pendukung.
class BarisMenu extends StatelessWidget {
  const BarisMenu({super.key, required this.ikon, required this.judul, required this.keterangan, required this.onTap});

  final IconData ikon;
  final String judul;
  final String keterangan;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Kartu(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: Row(
        children: [
          Icon(ikon, size: 20, color: W.hijauSedang),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(judul, style: T.subjudul),
                const SizedBox(height: 2),
                Text(keterangan, style: T.kecil),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, size: 20, color: W.redupMuda),
        ],
      ),
    );
  }
}

/// Label kecil berlatar hijau muda, dipakai untuk status netral.
class Lencana extends StatelessWidget {
  const Lencana({super.key, required this.teks, this.warna, this.latar, this.ikon});

  final String teks;
  final Color? warna;
  final Color? latar;
  final IconData? ikon;

  @override
  Widget build(BuildContext context) {
    final fg = warna ?? W.hijauSedang;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: latar ?? (fg == W.kunyit ? W.kunyitMuda : fg == W.merah ? W.merahMuda : W.hijauMuda),
        borderRadius: BorderRadius.circular(R.kecil - 3),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (ikon != null) ...[
            Icon(ikon, size: 12, color: fg),
            const SizedBox(width: 5),
          ],
          Text(teks,
              style: TextStyle(
                  fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w600,
                  letterSpacing: 0.2, color: fg)),
        ],
      ),
    );
  }
}

/// Judul bagian dengan garis tipis di atasnya, pengganti heading seragam.
class JudulBagian extends StatelessWidget {
  const JudulBagian(this.teks, {super.key, this.aksi});

  final String teks;
  final Widget? aksi;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(teks, style: T.mikro.copyWith(color: W.redup)),
          const SizedBox(width: 10),
          const Expanded(child: Divider(color: W.garisTipis)),
          if (aksi != null) ...[const SizedBox(width: 10), aksi!],
        ],
      ),
    );
  }
}

/// Garis skor tanpa gradien, tebal 4 piksel.
class BilahSkor extends StatelessWidget {
  const BilahSkor({super.key, required this.nilai, this.warna, this.tinggi = 4});

  final double nilai;
  final Color? warna;
  final double tinggi;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(tinggi),
      child: LinearProgressIndicator(
        value: nilai.clamp(0.0, 1.0),
        minHeight: tinggi,
        backgroundColor: W.garisTipis,
        valueColor: AlwaysStoppedAnimation(warna ?? W.hijauSedang),
      ),
    );
  }
}
