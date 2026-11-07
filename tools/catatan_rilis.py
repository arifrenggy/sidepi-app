"""Menyusun catatan rilis GitHub dari CHANGELOG.md.

Setiap rilis memuat dua bagian: perubahan pada versi itu sendiri, lalu seluruh
riwayat perubahan versi sebelumnya. Dipakai oleh alur kerja build-apk.yml.
"""
import re
import sys

CHANGELOG = "CHANGELOG.md"


def baca_bagian(teks):
    """Pecah CHANGELOG menjadi daftar (versi, isi) sesuai judul '## v...'."""
    potongan = re.split(r"^## (v[0-9][^\n]*)$", teks, flags=re.MULTILINE)
    hasil = []
    for i in range(1, len(potongan), 2):
        hasil.append((potongan[i].strip(), potongan[i + 1].strip()))
    return hasil


def susun(versi, hanya_versi_lama=False):
    """hanya_versi_lama dipakai saat menyunting catatan rilis lama, agar tidak
    memuat versi yang terbit setelahnya."""
    teks = open(CHANGELOG, encoding="utf-8").read()
    bagian = baca_bagian(teks)
    sekarang = [b for v, b in bagian if v == f"v{versi}"]
    if hanya_versi_lama:
        posisi = next((i for i, (v, _) in enumerate(bagian) if v == f"v{versi}"), len(bagian))
        sebelumnya = bagian[posisi + 1:]
    else:
        sebelumnya = [(v, b) for v, b in bagian if v != f"v{versi}"]

    baris = [
        f"Rilis SIDEPI versi {versi}.",
        "",
        "Aplikasi alat bantu lapangan untuk petugas dan penyuluh, bukan pengganti "
        "pemeriksaan penyuluh.",
        "",
        "## Perubahan di versi ini",
        "",
    ]
    baris.append(sekarang[0] if sekarang else "Rincian versi ini belum dicatat.")
    baris += [
        "",
        "## Riwayat perubahan sebelumnya",
        "",
        "Bagian ini ikut disertakan di setiap rilis agar pengguna yang baru memasang "
        "aplikasi tetap tahu apa yang sudah berubah.",
        "",
    ]
    for v, b in sebelumnya:
        baris.append(f"### {v}")
        baris.append("")
        baris.append(b)
        baris.append("")

    return "\n".join(baris).rstrip() + "\n"


if __name__ == "__main__":
    versi = sys.argv[1] if len(sys.argv) > 1 else ""
    if not versi:
        sys.exit("pemakaian: python3 tools/catatan_rilis.py 0.13.1 [--hanya-versi-lama]")
    lama = "--hanya-versi-lama" in sys.argv
    teks = susun(versi, hanya_versi_lama=lama)
    open("RELEASE_BODY.md", "w", encoding="utf-8").write(teks)
    print(teks)
