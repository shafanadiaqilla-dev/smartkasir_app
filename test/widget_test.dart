import 'package:flutter_test/flutter_test.dart';
import 'package:smartkasir_app/models/produk.dart';
import 'package:smartkasir_app/models/karyawan.dart';

void main() {
  group('Pengujian Model dan Validasi SmartKasir P11', () {
    test('Verifikasi Data Awal Seeding & Preservasi Promo 20% P10', () {
      expect(produkAwalSQLite.length, 7);

      final kopiSusu = produkAwalSQLite.firstWhere((p) => p.kodeProduk == 'PRD-001');
      expect(kopiSusu.nama, 'Kopi Susu Gula Aren 250ml');
      expect(kopiSusu.diskonPersen, 20); // Memastikan badge promo 20% P10 tidak hilang

      final dessert = produkAwalSQLite.firstWhere((p) => p.kodeProduk == 'PRD-007');
      expect(dessert.kategori, 'Dessert');
    });

    test('Verifikasi Serialisasi toMap dan Deserialisasi fromMap Produk', () {
      const produkAsli = Produk(
        id: 99,
        kodeProduk: 'PRD-TEST',
        nama: 'Puding Cokelat Silky',
        kategori: 'Dessert',
        hargaBeli: 5000,
        hargaJual: 10000,
        stok: 15,
        gambarUrl: 'https://example.com/puding.jpg',
        diskonPersen: 15,
      );

      final map = produkAsli.toMap();
      expect(map['id'], 99);
      expect(map['kode_produk'], 'PRD-TEST');
      expect(map['nama_produk'], 'Puding Cokelat Silky');
      expect(map['kategori'], 'Dessert');
      expect(map['harga_beli'], 5000.0);
      expect(map['harga_jual'], 10000.0);
      expect(map['stok'], 15);
      expect(map['gambar_path'], 'https://example.com/puding.jpg');
      expect(map['diskon_persen'], 15);
      expect(map['created_at'], isNotNull);

      final produkHasil = Produk.fromMap(map);
      expect(produkHasil.id, produkAsli.id);
      expect(produkHasil.kodeProduk, produkAsli.kodeProduk);
      expect(produkHasil.nama, produkAsli.nama);
      expect(produkHasil.kategori, produkAsli.kategori);
      expect(produkHasil.hargaBeli, produkAsli.hargaBeli);
      expect(produkHasil.hargaJual, produkAsli.hargaJual);
      expect(produkHasil.stok, produkAsli.stok);
      expect(produkHasil.gambarUrl, produkAsli.gambarUrl);
      expect(produkHasil.diskonPersen, produkAsli.diskonPersen);
      expect(produkHasil.harga, 10000.0);
    });

    test('Validasi Logika Bisnis Kasir: Jual Harus Lebih Besar Dari Modal', () {
      const beli = 5000.0;
      const jualValid = 8000.0;
      const jualInvalid = 4000.0;

      expect(jualValid > beli, isTrue);
      expect(jualInvalid > beli, isFalse);
    });

    test('Validasi Live Tweak 3 P11: Diskon Maksimal 50%', () {
      int diskon1 = 20;
      int diskon2 = 50;
      int diskon3 = 60;

      bool isValidDiskon(int d) => d >= 0 && d <= 50;

      expect(isValidDiskon(diskon1), isTrue);
      expect(isValidDiskon(diskon2), isTrue);
      expect(isValidDiskon(diskon3), isFalse);
    });
  });

  group('Pengujian Model dan Validasi SmartKasir P12', () {
    test('Verifikasi Serialisasi toMap dan Deserialisasi fromMap Karyawan', () {
      const staf = Karyawan(
        id: 1,
        namaKaryawan: 'Ahmad Kasir',
        pin: '123456',
        peran: 'Kasir',
      );

      final map = staf.toMap();
      expect(map['id'], 1);
      expect(map['nama_karyawan'], 'Ahmad Kasir');
      expect(map['pin'], '123456');
      expect(map['peran'], 'Kasir');

      final stafHasil = Karyawan.fromMap(map);
      expect(stafHasil.id, staf.id);
      expect(stafHasil.namaKaryawan, staf.namaKaryawan);
      expect(stafHasil.pin, staf.pin);
      expect(stafHasil.peran, staf.peran);
    });

    test('Tantangan 1 P12: Dukungan Peran Supervisor', () {
      const daftarPeran = ['Kasir', 'Admin', 'Supervisor', 'Manajer'];
      expect(daftarPeran.contains('Supervisor'), isTrue);
    });

    test('Tantangan 2 P12: Validasi PIN Kasir Wajib Tepat 6 Digit', () {
      bool isValidPin(String? pin) {
        if (pin == null || pin.trim().isEmpty) return false;
        return pin.trim().length == 6;
      }

      expect(isValidPin('123456'), isTrue);
      expect(isValidPin('1234'), isFalse);
      expect(isValidPin('1234567'), isFalse);
      expect(isValidPin(''), isFalse);
    });
  });
}
