// Pemindaian foto di peramban memakai model TensorFlow Lite yang sama dengan
// aplikasi. Alurnya: gerbang tanaman (224 px) -> potong latar -> model penyakit
// (256 px, cermin ganda).

var LABEL = ['Bercak coklat', 'Blas', 'Bukan padi', 'Kresek', 'Penggerek', 'Penggulung', 'Daun sehat', 'Tungro'];
var KUNCI = ['bercak_coklat', 'blas', 'bukan_padi', 'kresek', 'penggerek', 'penggulung', 'sehat', 'tungro'];

var gerbang = null;
var model = null;
var sedangMuat = false;

function el(id) { return document.getElementById(id); }

function status(teks) { el('status').textContent = teks; }

function mulaiMuat() {
  if (gerbang && model) return Promise.resolve();
  if (sedangMuat) {
    return new Promise(function (selesai) {
      var cek = setInterval(function () {
        if (gerbang && model) { clearInterval(cek); selesai(); }
      }, 200);
    });
  }
  sedangMuat = true;
  status('Memuat model…');
  tf.tflite.setWasmPath('https://cdn.jsdelivr.net/npm/@tensorflow/tfjs-tflite@0.0.1-alpha.10/wasm/');
  return Promise.all([
    tf.tflite.loadTFLiteModel('models/sidepi_gate.tflite'),
    tf.tflite.loadTFLiteModel('models/sidepi_model.tflite')
  ]).then(function (hasil) {
    gerbang = hasil[0];
    model = hasil[1];
    sedangMuat = false;
    status('Model siap. Pilih foto atau pakai contoh.');
  }).catch(function (galat) {
    sedangMuat = false;
    status('Model gagal dimuat: ' + galat.message);
  });
}

function gambarKeCanvas(gambar) {
  var kanvas = document.createElement('canvas');
  kanvas.width = gambar.naturalWidth || gambar.width;
  kanvas.height = gambar.naturalHeight || gambar.height;
  kanvas.getContext('2d').drawImage(gambar, 0, 0);
  return kanvas;
}

// Pemotongan latar: indeks kelebihan hijau + ambang Otsu pada citra kecil.
function potongLatar(kanvas) {
  var kecil = document.createElement('canvas');
  var sisi = 200;
  var skala = sisi / Math.max(kanvas.width, kanvas.height);
  kecil.width = Math.max(1, Math.round(kanvas.width * skala));
  kecil.height = Math.max(1, Math.round(kanvas.height * skala));
  var ktx = kecil.getContext('2d');
  ktx.drawImage(kanvas, 0, 0, kecil.width, kecil.height);
  var data = ktx.getImageData(0, 0, kecil.width, kecil.height).data;

  var n = kecil.width * kecil.height;
  var exg = new Float32Array(n);
  var hist = new Float32Array(256);
  for (var i = 0; i < n; i++) {
    var r = data[i * 4], g = data[i * 4 + 1], b = data[i * 4 + 2];
    var v = (2 * g - r - b + 510) / 1020 * 255;
    exg[i] = v;
    hist[Math.max(0, Math.min(255, Math.round(v)))] += 1;
  }

  var total = 0, jumlah = 0, b0 = 0, m0 = 0, terbaik = -1, ambang = 0;
  for (var t = 0; t < 256; t++) total += t * hist[t];
  for (var t2 = 0; t2 < 256; t2++) {
    b0 += hist[t2];
    if (b0 === 0) continue;
    var b1 = n - b0;
    if (b1 === 0) break;
    m0 += t2 * hist[t2];
    var m1 = (total - m0) / b1;
    var antara = b0 * b1 * Math.pow(m0 / b0 - m1, 2);
    if (antara > terbaik) { terbaik = antara; ambang = t2; }
  }

  var kiri = kecil.width, atas = kecil.height, kanan = 0, bawah = 0, hitung = 0;
  for (var y = 0; y < kecil.height; y++) {
    for (var x = 0; x < kecil.width; x++) {
      if (exg[y * kecil.width + x] > ambang) {
        hitung++;
        if (x < kiri) kiri = x;
        if (x > kanan) kanan = x;
        if (y < atas) atas = y;
        if (y > bawah) bawah = y;
      }
    }
  }

  var porsi = hitung / n;
  if (hitung < 40 || porsi >= 0.55 || porsi < 0.02) {
    return { kanvas: kanvas, porsi: porsi };
  }

  var f = 1 / skala;
  var pad = 0.05;
  var w = kanan - kiri, h = bawah - atas;
  var kx = Math.max(0, Math.round((kiri - w * pad) * f));
  var ky = Math.max(0, Math.round((atas - h * pad) * f));
  var kw = Math.min(kanvas.width - kx, Math.round(w * (1 + pad * 2) * f));
  var kh = Math.min(kanvas.height - ky, Math.round(h * (1 + pad * 2) * f));

  var hasil = document.createElement('canvas');
  hasil.width = kw;
  hasil.height = kh;
  hasil.getContext('2d').drawImage(kanvas, kx, ky, kw, kh, 0, 0, kw, kh);
  return { kanvas: hasil, porsi: porsi };
}

function tensorDari(kanvas, ukuran, normal) {
  return tf.tidy(function () {
    var t = tf.browser.fromPixels(kanvas);
    var ubah = tf.image.resizeBilinear(t, [ukuran, ukuran]);
    var f = ubah.toFloat();
    var siap = normal === 'pm1' ? f.div(127.5).sub(1) : f.div(255);
    return siap.expandDims(0);
  });
}

function peluangGerbang(kanvas) {
  return tf.tidy(function () {
    var keluaran = gerbang.predict(tensorDari(kanvas, 224, 'pm1'));
    var data = keluaran.dataSync();
    return { padi: data[1], mentah: Array.prototype.slice.call(data) };
  });
}

function peluangPenyakit(kanvas) {
  return tf.tidy(function () {
    var masukan = tensorDari(kanvas, 256, 'nol');
    var kiri = model.predict(masukan);
    var kanan = model.predict(tf.reverse(masukan, [2]));
    var gabung = kiri.add(kanan).div(2);
    return Array.prototype.slice.call(gabung.dataSync());
  });
}

function tampilkanHasil(gambar, kanvasAsli) {
  var potong = potongLatar(kanvasAsli);
  var gerbangHasil = peluangGerbang(potong.kanvas);
  var kartu = el('kartu');
  el('hasil').hidden = false;
  kartu.textContent = '';

  if (gerbangHasil.padi < 0.35) {
    kartu.innerHTML = '<div class="hasil-utama"><div class="skor">Bukan tanaman padi</div>' +
      '<div style="font-size:14px">Gerbang tanaman menilai foto ini bukan daun padi ' +
      '(keyakinan padi ' + (gerbangHasil.padi * 100).toFixed(0) + '%). Coba foto ulang lebih dekat pada daun.</div></div>';
    status('Selesai.');
    return;
  }

  var mentah = peluangPenyakit(potong.kanvas);
  var urut = mentah.map(function (nilai, i) { return { i: i, nilai: nilai }; })
    .sort(function (a, b) { return b.nilai - a.nilai; });

  var atas = urut[0];
  var kedua = urut[1];

  var isi = '';
  isi += '<div class="hasil-utama">';
  isi += '<div style="font-size:14px">Perkiraan teratas</div>';
  isi += '<div class="skor">' + LABEL[atas.i] + '</div>';
  isi += '<div style="font-size:14px">' + (atas.nilai * 100).toFixed(1) + '% peluang, ' +
    'keyakinan tanaman padi ' + (gerbangHasil.padi * 100).toFixed(0) + '%</div>';
  isi += '</div>';

  isi += '<div class="panel"><h3>Peluang tiap kelas</h3>';
  urut.forEach(function (u) {
    var persen = (u.nilai * 100).toFixed(1);
    isi += '<div class="baris-hasil"><div style="flex:1">' + LABEL[u.i] + '</div>' +
      '<div style="text-align:right;min-width:64px">' + persen + '%</div></div>' +
      '<div class="batang"><span style="width:' + Math.max(1, u.nilai * 100) + '%"></span></div>';
  });
  isi += '</div>';

  if (atas.nilai < 0.5) {
    isi += '<div class="catatan">Model belum yakin pada foto ini. Model lapangan masih lemah, ' +
      'jadi bandingkan dengan galeri acuan atau gunakan jalur ciri.</div>';
  } else if (kedua && atas.nilai - kedua.nilai < 0.15) {
    isi += '<div class="catatan">Selisih dua kandidat teratas kecil. Bandingkan ciri pada foto ' +
      'dengan galeri acuan sebelum menyimpulkan.</div>';
  }

  isi += '<div class="panel"><h3>Terukur dari foto</h3>' +
    '<div class="baris-hasil"><div style="flex:1">Bagian tanaman menempati bingkai</div>' +
    '<div>' + (potong.porsi * 100).toFixed(0) + '%</div></div>' +
    '<div class="baris-hasil"><div style="flex:1">Foto dipotong otomatis</div>' +
    '<div>' + (potong.kanvas === kanvasAsli ? 'tidak' : 'ya') + '</div></div>' +
    '<div class="baris-hasil"><div style="flex:1">Ukuran kerja</div>' +
    '<div>' + potong.kanvas.width + ' x ' + potong.kanvas.height + '</div></div></div>';

  kartu.innerHTML = isi;
  status('Selesai.');
}

function pakaiGambar(sumber, gambar) {
  el('kosong').hidden = true;
  var pratinjau = el('pratinjau');
  pratinjau.src = sumber;
  pratinjau.hidden = false;
  status('Menyiapkan model…');
  mulaiMuat().then(function () {
    if (!gerbang || !model) return;
    status('Menganalisis foto…');
    setTimeout(function () {
      var kanvas = gambarKeCanvas(gambar);
      tampilkanHasil(gambar, kanvas);
    }, 30);
  });
}

el('tombol-pilih').onclick = function () { el('berkas').click(); };

el('berkas').onchange = function (e) {
  var berkas = e.target.files && e.target.files[0];
  if (!berkas) return;
  var pembaca = new FileReader();
  pembaca.onload = function () {
    var gambar = new Image();
    gambar.onload = function () { pakaiGambar(pembaca.result, gambar); };
    gambar.src = pembaca.result;
  };
  pembaca.readAsDataURL(berkas);
};

var CONTOH = ['contoh/blas.jpg', 'contoh/penggulung.jpg', 'contoh/sehat.jpg'];
var urutanContoh = 0;

el('tombol-contoh').onclick = function () {
  var jalur = CONTOH[urutanContoh % CONTOH.length];
  urutanContoh += 1;
  status('Memuat contoh ' + jalur.split('/').pop());
  var gambar = new Image();
  gambar.onload = function () { pakaiGambar(jalur, gambar); };
  gambar.onerror = function () { status('Contoh gagal dimuat.'); };
  gambar.src = jalur;
  el('tombol-contoh').textContent = 'Pakai contoh lain';
};
