// SIDEPI - analisis foto di perangkat, tanpa internet.
// Ciri yang diukur identik dengan skrip kalibrasi Python.
var PATOKAN = {
  blas:          { rasio_lesi: 0.221, val_lesi: 167.5, sat_lesi: 151, hue_lesi: 27, pucat: 0.014, jumlah_bercak: 32.5 },
  bercak_coklat: { rasio_lesi: 0.188, val_lesi: 141.0, sat_lesi: 133, hue_lesi: 30, pucat: 0.066, jumlah_bercak: 27.0 },
  sehat:         { rasio_lesi: 0.022, val_lesi:  64.0, sat_lesi: 152, hue_lesi: 34, pucat: 0.033, jumlah_bercak: 14.0 }
};
var SIMPANG = { rasio_lesi: 0.12, val_lesi: 45, sat_lesi: 40, hue_lesi: 6, pucat: 0.10, jumlah_bercak: 18 };
var BOBOT = { rasio_lesi: 1.4, val_lesi: 1.2, sat_lesi: 0.8, hue_lesi: 0.6, pucat: 0.5, jumlah_bercak: 0.4 };
var NAMA_KELAS = { blas: 'Blas', bercak_coklat: 'Bercak daun coklat', sehat: 'Daun sehat' };

function rgbKeHsv(r, g, b) {
  r /= 255; g /= 255; b /= 255;
  var max = Math.max(r, g, b), min = Math.min(r, g, b);
  var d = max - min, h = 0;
  if (d !== 0) {
    if (max === r) h = 60 * (((g - b) / d) % 6);
    else if (max === g) h = 60 * ((b - r) / d + 2);
    else h = 60 * ((r - g) / d + 4);
  }
  if (h < 0) h += 360;
  var s = max === 0 ? 0 : d / max;
  return [h / 2, s * 255, max * 255];
}

function analisaPiksel(data, w, h) {
  var totalDaun = 0, totalLesi = 0, totalPucat = 0;
  var hueLesi = [], valLesi = [], satLesi = [];
  var mask = new Uint8Array(w * h);
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      var i = (y * w + x) * 4;
      var hsv = rgbKeHsv(data[i], data[i + 1], data[i + 2]);
      var H = hsv[0], S = hsv[1], V = hsv[2];
      var latar = (V > 232 && S < 30) || V < 26;
      if (latar) continue;
      var hijau = H >= 35 && H <= 95 && S > 45 && V > 45;
      totalDaun++;
      if (!hijau && S > 55 && V > 35) {
        mask[y * w + x] = 1;
        totalLesi++;
        hueLesi.push(H); valLesi.push(V); satLesi.push(S);
        if (V > 150 && S < 120) totalPucat++;
      }
    }
  }
  var jumlahBercak = hitungBercak(mask, w, h, 12);
  function median(a) {
    if (!a.length) return 0;
    var b = a.slice().sort(function (p, q) { return p - q; });
    return b[Math.floor(b.length / 2)];
  }
  return {
    rasio_lesi: totalDaun ? totalLesi / totalDaun : 0,
    val_lesi: median(valLesi),
    sat_lesi: median(satLesi),
    hue_lesi: median(hueLesi),
    pucat: totalLesi ? totalPucat / totalLesi : 0,
    jumlah_bercak: jumlahBercak
  };
}

function hitungBercak(mask, w, h, ambangLuas) {
  var terlihat = new Uint8Array(mask.length), jumlah = 0, tumpuk = [];
  for (var s = 0; s < mask.length; s++) {
    if (!mask[s] || terlihat[s]) continue;
    var luas = 0; tumpuk.push(s); terlihat[s] = 1;
    while (tumpuk.length) {
      var p = tumpuk.pop(); luas++;
      var px = p % w, py = (p - px) / w;
      for (var dy = -1; dy <= 1; dy++) {
        for (var dx = -1; dx <= 1; dx++) {
          var nx = px + dx, ny = py + dy;
          if (nx < 0 || ny < 0 || nx >= w || ny >= h) continue;
          var n = ny * w + nx;
          if (mask[n] && !terlihat[n]) { terlihat[n] = 1; tumpuk.push(n); }
        }
      }
    }
    if (luas >= ambangLuas) jumlah++;
  }
  return jumlah;
}

function periksaFoto(img) {
  var maks = 480;
  var skala = Math.min(1, maks / Math.max(img.width, img.height));
  var w = Math.round(img.width * skala), h = Math.round(img.height * skala);
  var cv = document.createElement('canvas');
  cv.width = w; cv.height = h;
  cv.getContext('2d').drawImage(img, 0, 0, w, h);
  var data = cv.getContext('2d').getImageData(0, 0, w, h).data;
  var ciri = analisaPiksel(data, w, h);
  var hasil = jalankanPohon(ciri, POHON);
  var status;
  if (ciri.rasio_lesi < 0.05) status = 'sehat';
  else if (hasil.yakin < 0.7) status = 'belum_pasti';
  else if (hasil.kelas === 'sehat') status = 'sehat';
  else status = 'ada_indikasi';
  return {
    ciri: ciri,
    kelas: hasil.kelas,
    nama: NAMA_KELAS[hasil.kelas],
    yakin: hasil.yakin,
    status: status
  };
}

if (typeof module !== 'undefined') module.exports = { periksaFoto: periksaFoto, analisaPiksel: analisaPiksel, jalankanPohon: jalankanPohon, rgbKeHsv: rgbKeHsv };
