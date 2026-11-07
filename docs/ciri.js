// Identifikasi lewat ciri, memakai basis pengetahuan yang sama dengan aplikasi.
// Aturan: skor = bobot ciri cocok / total bobot, hasil utama butuh skor >= 60
// dan minimal satu ciri kunci (bobot 3).

var BASIS = null;
var NAMA_KELOMPOK = {
  daun: 'Daun',
  pelepah: 'Pelepah daun',
  batang: 'Batang',
  malai: 'Malai dan bulir',
  tanaman: 'Pertumbuhan tanaman'
};

function el(id) { return document.getElementById(id); }

function gagal(pesan) {
  el('daftar-ciri').textContent = pesan;
}

fetch('data/basis-pengetahuan.json')
  .then(function (r) {
    if (!r.ok) throw new Error('basis tidak ditemukan');
    return r.json();
  })
  .then(function (d) {
    BASIS = d;
    el('versi-basis').textContent = d.versi || '-';
    gambarCiri();
  })
  .catch(function () {
    gagal('Basis pengetahuan gagal dimuat. Buka halaman ini lewat server, bukan dari berkas lokal.');
  });

function gambarCiri() {
  var wadah = el('daftar-ciri');
  wadah.textContent = '';
  wadah.className = '';

  var kelompok = {};
  BASIS.gejala.forEach(function (g) {
    var k = g.kelompok || 'daun';
    if (!kelompok[k]) kelompok[k] = [];
    kelompok[k].push(g);
  });

  Object.keys(NAMA_KELOMPOK).forEach(function (k) {
    if (!kelompok[k]) return;
    var judul = document.createElement('div');
    judul.className = 'kelompok';
    judul.textContent = NAMA_KELOMPOK[k];
    wadah.appendChild(judul);

    kelompok[k].forEach(function (g) {
      var label = document.createElement('label');
      label.className = 'ciri';
      var kotak = document.createElement('input');
      kotak.type = 'checkbox';
      kotak.value = g.id;
      var teks = document.createElement('span');
      teks.textContent = g.nama;
      label.appendChild(kotak);
      label.appendChild(teks);
      wadah.appendChild(label);
    });
  });
}

function terpilih() {
  var hasil = [];
  document.querySelectorAll('#daftar-ciri input:checked').forEach(function (k) {
    hasil.push(k.value);
  });
  return hasil;
}

function hitung(pilihan) {
  var daftar = [];
  BASIS.penyakit.forEach(function (p) {
    var cocok = 0, kunci = 0, total = 0;
    Object.keys(p.bobot_gejala).forEach(function (gid) {
      var bobot = p.bobot_gejala[gid];
      total += bobot;
      if (pilihan.indexOf(gid) !== -1) {
        cocok += bobot;
        if (bobot === 3) kunci += 1;
      }
    });
    if (cocok === 0 || total === 0) return;
    daftar.push({
      jenis: p,
      skor: Math.round(cocok / total * 100),
      kunci: kunci
    });
  });

  daftar.sort(function (a, b) {
    if (b.skor !== a.skor) return b.skor - a.skor;
    if (b.kunci !== a.kunci) return b.kunci - a.kunci;
    return a.jenis.id.localeCompare(b.jenis.id);
  });

  return daftar.slice(0, 3);
}

function tampilkan() {
  var pilihan = terpilih();
  var wadah = el('kartu-hasil');
  el('hasil').hidden = false;
  wadah.textContent = '';

  if (pilihan.length === 0) {
    wadah.innerHTML = '<p class="kosong">Belum ada ciri yang dicentang.</p>';
    return;
  }

  var hasil = hitung(pilihan);
  if (hasil.length === 0) {
    wadah.innerHTML = '<p class="kosong">Ciri yang dipilih belum cocok dengan jenis mana pun pada basis pengetahuan. Tambahkan ciri lain atau hubungi penyuluh.</p>';
    return;
  }

  var atas = hasil[0];
  var utama = atas.skor >= 60 && atas.kunci >= 1;

  var kartu = document.createElement('div');
  kartu.className = 'hasil-utama';
  var judul = document.createElement('div');
  judul.innerHTML = (utama ? 'Kecocokan kuat: ' : 'Belum cukup kuat: ') +
    '<strong>' + atas.jenis.nama + '</strong>';
  var skor = document.createElement('div');
  skor.className = 'skor';
  skor.textContent = atas.skor + '%';
  var ket = document.createElement('div');
  ket.style.fontSize = '14px';
  ket.textContent = atas.kunci > 0
    ? atas.kunci + ' ciri kunci cocok'
    : 'Tidak ada ciri kunci yang dipilih, jadi hasil ini perlu diverifikasi di lapangan.';
  kartu.appendChild(judul);
  kartu.appendChild(skor);
  kartu.appendChild(ket);
  wadah.appendChild(kartu);

  hasil.forEach(function (h) {
    var baris = document.createElement('div');
    baris.className = 'baris-hasil';
    var kiri = document.createElement('div');
    kiri.style.flex = '1';
    kiri.innerHTML = '<strong>' + h.jenis.nama + '</strong><br><span style="font-size:13px;color:#5d6b62">' +
      h.jenis.nama_ilmiah + ' &middot; ' + h.jenis.penyebab + '</span>';
    var kanan = document.createElement('div');
    kanan.style.textAlign = 'right';
    kanan.style.minWidth = '56px';
    kanan.textContent = h.skor + '%';
    baris.appendChild(kiri);
    baris.appendChild(kanan);
    wadah.appendChild(baris);
  });

  var rincian = document.createElement('div');
  rincian.className = 'panel';
  var isi = '<h3>' + atas.jenis.nama + '</h3>' +
    '<p>' + (atas.jenis.deskripsi || '') + '</p>';
  var peng = atas.jenis.pengendalian || {};
  ['kultur', 'hayati', 'kimia'].forEach(function (k) {
    if (!peng[k] || peng[k].length === 0) return;
    isi += '<p style="margin-bottom:4px"><strong>Pengendalian ' + k + '</strong></p><ul>';
    peng[k].forEach(function (b) { isi += '<li>' + b + '</li>'; });
    isi += '</ul>';
  });
  if (atas.jenis.pencegahan && atas.jenis.pencegahan.length) {
    isi += '<p style="margin-bottom:4px"><strong>Pencegahan</strong></p><ul>';
    atas.jenis.pencegahan.forEach(function (b) { isi += '<li>' + b + '</li>'; });
    isi += '</ul>';
  }
  rincian.innerHTML = isi;
  wadah.appendChild(rincian);
}

el('tombol-hitung').addEventListener('click', tampilkan);
el('tombol-bersih').addEventListener('click', function () {
  document.querySelectorAll('#daftar-ciri input:checked').forEach(function (k) {
    k.checked = false;
  });
  el('hasil').hidden = true;
});
