// SIDEPI - layar periksa foto
var CIRI_BLAS = [
  { id: 'g01', teks: 'Bercak berbentuk belah ketupat atau jorong' },
  { id: 'g02', teks: 'Pusat bercak abu-abu dengan tepi coklat' },
  { id: 'g07', teks: 'Leher malai membusuk coklat kehitaman, malai rebah' },
  { id: 'g09', teks: 'Daun mengering seperti terbakar' }
];
var NAMA_BERSAHABAT = { blas: 'Blas', bercak_coklat: 'Bercak daun coklat', sehat: 'Daun sehat' };
var TINGKAT = {
  blas: { tepat: '64 dari 100 foto blas dikenali benar' },
  bercak_coklat: { tepat: '83 dari 100 foto bercak coklat dikenali benar' },
  sehat: { tepat: '77 dari 100 foto daun sehat dikenali benar' }
};

var el = function (id) { return document.getElementById(id); };
var hasilTerakhir = null;

el('tombol-kamera').onclick = function () { el('input-foto').click(); };
el('tombol-galeri').onclick = function () { el('input-foto').removeAttribute('capture'); el('input-foto').click(); };

el('input-foto').onchange = function (e) {
  var berkas = e.target.files && e.target.files[0];
  if (!berkas) return;
  var pembaca = new FileReader();
  pembaca.onload = function () { mulai(berkas.name, pembaca.result); };
  pembaca.readAsDataURL(berkas);
};

function mulai(namaBerkas, dataUrl) {
  el('layar-awal').hidden = true;
  el('layar-hasil').hidden = true;
  el('layar-proses').hidden = false;
  var img = new Image();
  img.onload = function () {
    setTimeout(function () {
      hasilTerakhir = periksaFoto(img);
      hasilTerakhir.namaBerkas = namaBerkas;
      tampilkan(hasilTerakhir);
      el('layar-proses').hidden = true;
      el('layar-hasil').hidden = false;
      window.scrollTo(0, 0);
    }, 120);
  };
  img.onerror = function () {
    el('layar-proses').hidden = true;
    el('layar-awal').hidden = false;
    alert('Foto tidak dapat dibaca. Coba foto lain.');
  };
  img.src = dataUrl;
}

function tampilkan(h) {
  var kartu = el('kartu-utama');
  kartu.className = 'kartu ' + (h.status === 'sehat' ? 'aman' : 'hati-hati');
  var judul, angka, isi;
  if (h.status === 'bukan_padi') {
    judul = 'Ini bukan foto tanaman padi';
    angka = 'Tidak diproses';
    isi = 'Foto ini tidak memuat bagian tanaman yang cukup, jadi tidak dianalisis. Arahkan kamera ke daun, batang, atau malai padi, isi layar dengan bagian tanaman tersebut, lalu ambil ulang.';
    kartu.innerHTML = '<div class="label">Pemeriksaan dibatalkan</div><h2>' + judul + '</h2><div class="angka">' + angka + '</div><p>' + isi + '</p>';
    el('tabel-ukur').innerHTML = '<tr><td>Bagian tanaman terlihat</td><td>' + Math.round(h.ciri.rasio_tanaman * 100) + '%</td></tr>';
    el('daftar-ciri').innerHTML = '';
    el('kesimpulan-ciri').hidden = true;
    el('penafian').textContent = 'Untuk hasil yang bisa dipakai, foto harus memuat bagian tanaman padi dengan jelas.';
    return;
  }
  if (h.status === 'terlalu_jauh') {
    judul = 'Bagian tanaman terlalu kecil';
    angka = Math.round(h.ciri.rasio_tanaman * 100) + '% tanaman';
    isi = 'Bagian tanaman dalam foto terlalu sedikit untuk dinilai. Kalau ini memang tanaman padi, dekatkan kamera sampai daun memenuhi layar lalu ambil ulang. Kalau bukan tanaman, tidak perlu dilanjutkan.';
    kartu.innerHTML = '<div class="label">Perlu foto ulang</div><h2>' + judul + '</h2><div class="angka">' + angka + '</div><p>' + isi + '</p>';
    el('tabel-ukur').innerHTML = '<tr><td>Bagian tanaman terlihat</td><td>' + Math.round(h.ciri.rasio_tanaman * 100) + '%</td></tr>';
    el('daftar-ciri').innerHTML = '';
    el('kesimpulan-ciri').hidden = true;
    el('penafian').textContent = 'Petunjuk: jarak 10-15 cm dari daun, latar sederhana, cahaya cukup.';
    return;
  }
  if (h.status === 'sehat') {
    judul = 'Daun tampak sehat';
    angka = Math.round(h.ciri.rasio_lesi * 100) + '% bercak';
    isi = 'Foto ini tidak menunjukkan bercak penyakit yang berarti. Tetap periksa bagian lain tanaman, terutama leher malai dan pelepah bawah.';
  } else if (h.status === 'belum_pasti') {
    judul = 'Belum dapat dipastikan';
    angka = NAMA_BERSAHABAT[h.kelas] + ' (dugaan lemah)';
    isi = 'Ciri pada foto belum cukup khas. Tambahkan konfirmasi di bawah, atau foto ulang lebih dekat pada bagian yang paling jelas bergejala.';
  } else {
    judul = 'Indikasi: ' + NAMA_BERSAHABAT[h.kelas];
    angka = Math.round(h.ciri.rasio_lesi * 100) + '% luas daun berbercak';
    isi = 'Foto menunjukkan pola bercak yang paling mirip dengan ' + NAMA_BERSAHABAT[h.kelas].toLowerCase() + '. ' +
          (TINGKAT[h.kelas] ? TINGKAT[h.kelas].tepat + ' pada uji laboratorium.' : '') +
          ' Konfirmasi dengan ciri di bawah sebelum mengambil tindakan.';
  }
  kartu.innerHTML = '<div class="label">Hasil pemeriksaan foto</div><h2>' + judul + '</h2><div class="angka">' + angka + '</div><p>' + isi + '</p>';

  var baris = [
    ['Bagian tanaman dalam foto', Math.round(h.ciri.rasio_tanaman * 100) + '%'],
    ['Luas daun berbercak', Math.round(h.ciri.rasio_lesi * 100) + '%'],
    ['Jumlah bercak terpisah', h.ciri.jumlah_bercak + ' titik'],
    ['Kecerahan bercak', Math.round(h.ciri.val_lesi) + ' dari 255'],
    ['Warna dasar bercak', Math.round(h.ciri.hue_lesi) + ' derajat'],
    ['Bercak berinti pucat', Math.round(h.ciri.pucat * 100) + '%']
  ];
  el('tabel-ukur').innerHTML = baris.map(function (r) {
    return '<tr><td>' + r[0] + '</td><td>' + r[1] + '</td></tr>';
  }).join('');

  el('daftar-ciri').innerHTML = CIRI_BLAS.map(function (c) {
    return '<label class="ciri"><input type="checkbox" data-ciri="' + c.id + '"> <span>' + c.teks + '</span></label>';
  }).join('');
  el('daftar-ciri').querySelectorAll('input').forEach(function (inp) {
    inp.onchange = hitungCiri;
  });
  el('kesimpulan-ciri').hidden = true;
  el('penafian').textContent = 'Hasil ini alat bantu, bukan diagnosis final. Ketepatan uji 73% pada 130 foto laboratorium; pada foto lapangan bisa lebih rendah. Untuk keputusan pengendalian, cocokkan dengan penyuluh atau POPT.';
}

function hitungCiri() {
  var dicentang = el('daftar-ciri').querySelectorAll('input:checked').length;
  var kotak = el('kesimpulan-ciri');
  kotak.hidden = false;
  var kelas = hasilTerakhir.kelas;
  if (dicentang === 0) {
    kotak.className = 'kartu kecil';
    kotak.innerHTML = '<p>Belum ada ciri tambahan yang dicentang.</p>';
    return;
  }
  if (dicentang >= 2 && kelas === 'blas') {
    kotak.className = 'kartu kecil aman';
    kotak.innerHTML = '<p><strong>Mendukung indikasi blas.</strong> Ciri yang dicentang sesuai dengan pola foto. Lanjutkan dengan tindakan pengendalian pada panduan, dan catat temuan ini untuk laporan lapangan.</p>';
  } else if (dicentang >= 2 && kelas !== 'blas') {
    kotak.className = 'kartu kecil hati-hati';
    kotak.innerHTML = '<p><strong>Perlu diperiksa ulang.</strong> Ciri yang dicentang mengarah ke blas, tetapi foto terbaca sebagai ' + NAMA_BERSAHABAT[kelas].toLowerCase() + '. Foto ulang dari dekat dan konsultasikan dengan penyuluh.</p>';
  } else {
    kotak.className = 'kartu kecil';
    kotak.innerHTML = '<p>Ciri baru ' + dicentang + ' yang dicentang. Periksa bagian lain tanaman untuk memastikan.</p>';
  }
}

el('tombol-ulang').onclick = function () {
  el('layar-hasil').hidden = true;
  el('layar-awal').hidden = false;
  el('pratinjau').hidden = true;
  el('teks-kosong').hidden = false;
  el('input-foto').value = '';
  el('input-foto').setAttribute('capture', 'environment');
};
