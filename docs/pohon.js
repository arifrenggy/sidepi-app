// Pohon keputusan hasil latihan pada 129 foto (akurasi validasi silang 72,9%).
// Diekspor dari scikit-learn agar aplikasi memakai aturan yang sama.
var POHON = {
 "fitur": "val_lesi",
 "ambang": 82.5,
 "paling_banyak": "blas",
 "kiri": {
  "fitur": "val_lesi",
  "ambang": 37.5,
  "paling_banyak": "sehat",
  "kiri": {
   "kelas": "sehat",
   "yakin": 0.7142857142857143
  },
  "kanan": {
   "kelas": "sehat",
   "yakin": 1.0
  }
 },
 "kanan": {
  "fitur": "hue_lesi",
  "ambang": 29.5,
  "paling_banyak": "blas",
  "kiri": {
   "fitur": "val_lesi",
   "ambang": 147.0,
   "paling_banyak": "blas",
   "kiri": {
    "fitur": "val_lesi",
    "ambang": 125.0,
    "paling_banyak": "blas",
    "kiri": {
     "kelas": "blas",
     "yakin": 1.0
    },
    "kanan": {
     "kelas": "bercak_coklat",
     "yakin": 0.5833333333333334
    }
   },
   "kanan": {
    "fitur": "pucat",
    "ambang": 0.027363670989871025,
    "paling_banyak": "blas",
    "kiri": {
     "kelas": "blas",
     "yakin": 1.0
    },
    "kanan": {
     "kelas": "blas",
     "yakin": 0.8888888888888888
    }
   }
  },
  "kanan": {
   "fitur": "pucat",
   "ambang": 0.018625429831445217,
   "paling_banyak": "bercak_coklat",
   "kiri": {
    "fitur": "pucat",
    "ambang": 0.003610918764024973,
    "paling_banyak": "blas",
    "kiri": {
     "kelas": "bercak_coklat",
     "yakin": 0.5000000000000001
    },
    "kanan": {
     "kelas": "blas",
     "yakin": 0.8888888888888888
    }
   },
   "kanan": {
    "fitur": "rasio_lesi",
    "ambang": 0.027339144609868526,
    "paling_banyak": "bercak_coklat",
    "kiri": {
     "kelas": "sehat",
     "yakin": 0.5714285714285714
    },
    "kanan": {
     "kelas": "bercak_coklat",
     "yakin": 0.7368421052631579
    }
   }
  }
 }
};

function jalankanPohon(c, s) {
  if (s.kelas) return { kelas: s.kelas, yakin: s.yakin };
  var v = c[s.fitur];
  return jalankanPohon(c, v <= s.ambang ? s.kiri : s.kanan);
}
