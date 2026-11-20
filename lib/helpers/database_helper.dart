// Mengimpor pustaka deteksi platform Flutter (untuk memeriksa peramban web kIsWeb)
import 'package:flutter/foundation.dart';
// Mengimpor pustaka inti SQLite untuk Flutter
import 'package:sqflite/sqflite.dart';
// Mengimpor pustaka penggabungan path direktori berkas lokal
import 'package:path/path.dart';
// Mengimpor implementasi SQLite FFI khusus peramban Web Google Chrome
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
// Mengimpor model data produk, karyawan, dan pelanggan
import '../models/produk.dart';
import '../models/karyawan.dart';
import '../models/pelanggan.dart';

// Kelas pengelola koneksi dan operasi basis data SQLite lokal SmartKasir
class DatabaseHelper {
  // --- 1. PENERAPAN DESIGN PATTERN SINGLETON ---
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  // --- 2. GETTER DATABASE ASINKRON ---
  Future<Database> get database async {
    if (_database != null) {
      await _seedProdukAwal(_database!);
      return _database!;
    }
    _database = await _initDB('smartkasir.db');
    await _seedProdukAwal(_database!);
    return _database!;
  }

  // --- 3. INISIALISASI BERKAS BASIS DATA (DUAL-PLATFORM CHROME & ANDROID) ---
  Future<Database> _initDB(String filePath) async {
    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
      return await databaseFactory.openDatabase(
        filePath,
        options: OpenDatabaseOptions(
          version: 3, // Ditingkatkan ke Versi 3 untuk tabel pelanggan
          onCreate: _createDB,
          onUpgrade: _onUpgradeDB,
          onOpen: _onOpenDB,
        ),
      );
    } else {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, filePath);
      return await openDatabase(
        path,
        version: 3, // Ditingkatkan ke Versi 3 untuk tabel pelanggan
        onCreate: _createDB,
        onUpgrade: _onUpgradeDB,
        onOpen: _onOpenDB,
      );
    }
  }

  // Self-healing database check on open
  Future<void> _onOpenDB(Database db) async {
    // 1. Pastikan tabel karyawan ada
    await db.execute('''
      CREATE TABLE IF NOT EXISTS karyawan (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nama_karyawan TEXT NOT NULL,
        pin TEXT NOT NULL,
        peran TEXT NOT NULL
      )
    ''');

    final countKaryawan = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM karyawan'),
    ) ?? 0;
    if (countKaryawan == 0) {
      await db.rawInsert('''
        INSERT INTO karyawan (nama_karyawan, pin, peran)
        VALUES ('Ahmad Kasir', '123456', 'Kasir')
      ''');
      await db.rawInsert('''
        INSERT INTO karyawan (nama_karyawan, pin, peran)
        VALUES ('Siti Supervisor', '888888', 'Supervisor')
      ''');
    }

    // 2. Pastikan tabel pelanggan ada (Modul M13)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS pelanggan (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        kode_pelanggan TEXT UNIQUE NOT NULL,
        nama_pelanggan TEXT NOT NULL,
        nomor_wa TEXT NOT NULL,
        alamat TEXT NOT NULL,
        latitude REAL,
        longitude REAL,
        created_at TEXT NOT NULL
      )
    ''');

    final countPelanggan = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM pelanggan'),
    ) ?? 0;
    if (countPelanggan == 0) {
      await db.rawInsert('''
        INSERT INTO pelanggan (kode_pelanggan, nama_pelanggan, nomor_wa, alamat, latitude, longitude, created_at)
        VALUES ('CUST-001', 'Warung Bu Siti', '081234567890', 'Jl. Hasan Basri No. 12, Banjarmasin', -3.298280, 114.588820, '2026-11-01 09:00:00')
      ''');
      await db.rawInsert('''
        INSERT INTO pelanggan (kode_pelanggan, nama_pelanggan, nomor_wa, alamat, latitude, longitude, created_at)
        VALUES ('CUST-002', 'Budi Santoso', '085712345678', 'Jl. Kayu Tangi II No. 45, Banjarmasin', -3.295410, 114.582150, '2026-11-02 10:30:00')
      ''');
    }
  }

  // --- SEEDER DATA AWAL PRODUK ---
  Future<void> _seedProdukAwal(Database db) async {
    try {
      final count = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM produk'),
      ) ?? 0;

      if (count == 0) {
        for (final item in produkAwalSQLite) {
          await db.insert('produk', item.toMap());
        }
      } else {
        // Pastikan produk Dessert selalu tersedia
        final countDessert = Sqflite.firstIntValue(
          await db.rawQuery("SELECT COUNT(*) FROM produk WHERE kategori = 'Dessert'"),
        ) ?? 0;
        if (countDessert == 0) {
          final defaultDessert = produkAwalSQLite.firstWhere(
            (p) => p.kategori == 'Dessert',
            orElse: () => Produk(
              kodeProduk: 'PRD-005',
              nama: 'Pancake Sirup Maple',
              kategori: 'Dessert',
              hargaBeli: 12000,
              hargaJual: 18000,
              stok: 15,
              gambarUrl: 'https://images.unsplash.com/photo-1567620905732-2d1ec7ab7445?w=500',
              diskonPersen: 0,
            ),
          );
          await db.insert('produk', defaultDessert.toMap());
        }
      }
    } catch (_) {
      // Abaikan jika tabel produk sedang dimigrasikan
    }
  }

  // --- DDL PEMBUATAN TABEL SAAT DATABASE PERTAMA KALI DIBUAT ---
  Future _createDB(Database db, int version) async {
    // 1. Tabel Produk (Modul M11)
    await db.execute('''
      CREATE TABLE produk (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        kode_produk TEXT UNIQUE,
        nama_produk TEXT NOT NULL,
        kategori TEXT NOT NULL,
        harga_beli REAL NOT NULL,
        harga_jual REAL NOT NULL,
        stok INTEGER NOT NULL,
        gambar_path TEXT,
        diskon_persen INTEGER DEFAULT 0,
        created_at TEXT
      )
    ''');

    // 2. Tabel Karyawan (Modul M12)
    await db.execute('''
      CREATE TABLE karyawan (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nama_karyawan TEXT NOT NULL,
        pin TEXT NOT NULL,
        peran TEXT NOT NULL
      )
    ''');

    // 3. Tabel Pelanggan & Koordinat GPS Maps (Modul M13)
    await db.execute('''
      CREATE TABLE pelanggan (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        kode_pelanggan TEXT UNIQUE NOT NULL,
        nama_pelanggan TEXT NOT NULL,
        nomor_wa TEXT NOT NULL,
        alamat TEXT NOT NULL,
        latitude REAL,
        longitude REAL,
        created_at TEXT NOT NULL
      )
    ''');

    // Seeding data produk awal
    await _seedProdukAwal(db);

    // Seeding data karyawan awal
    await db.rawInsert('''
      INSERT INTO karyawan (nama_karyawan, pin, peran)
      VALUES ('Ahmad Kasir', '123456', 'Kasir')
    ''');
    await db.rawInsert('''
      INSERT INTO karyawan (nama_karyawan, pin, peran)
      VALUES ('Siti Supervisor', '888888', 'Supervisor')
    ''');

    // Seeding data pelanggan awal (dengan koordinat GPS Banjarmasin)
    await db.rawInsert('''
      INSERT INTO pelanggan (kode_pelanggan, nama_pelanggan, nomor_wa, alamat, latitude, longitude, created_at)
      VALUES ('CUST-001', 'Warung Bu Siti', '081234567890', 'Jl. Hasan Basri No. 12, Banjarmasin', -3.298280, 114.588820, '2026-11-01 09:00:00')
    ''');
    await db.rawInsert('''
      INSERT INTO pelanggan (kode_pelanggan, nama_pelanggan, nomor_wa, alamat, latitude, longitude, created_at)
      VALUES ('CUST-002', 'Budi Santoso', '085712345678', 'Jl. Kayu Tangi II No. 45, Banjarmasin', -3.295410, 114.582150, '2026-11-02 10:30:00')
    ''');
  }

  // --- DDL UPGRADE SKEMA DATABASE ---
  Future _onUpgradeDB(Database db, int oldVersion, int newVersion) async {
    // 1. Memastikan tabel produk tetap ada
    await db.execute('''
      CREATE TABLE IF NOT EXISTS produk (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        kode_produk TEXT UNIQUE,
        nama_produk TEXT NOT NULL,
        kategori TEXT NOT NULL,
        harga_beli REAL NOT NULL,
        harga_jual REAL NOT NULL,
        stok INTEGER NOT NULL,
        gambar_path TEXT,
        diskon_persen INTEGER DEFAULT 0,
        created_at TEXT
      )
    ''');
    await _seedProdukAwal(db);

    // Migrasi versi 2: Tambah tabel karyawan
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS karyawan (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          nama_karyawan TEXT NOT NULL,
          pin TEXT NOT NULL,
          peran TEXT NOT NULL
        )
      ''');
      final countKaryawan = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM karyawan'),
      ) ?? 0;
      if (countKaryawan == 0) {
        await db.rawInsert('''
          INSERT INTO karyawan (nama_karyawan, pin, peran)
          VALUES ('Ahmad Kasir', '123456', 'Kasir')
        ''');
        await db.rawInsert('''
          INSERT INTO karyawan (nama_karyawan, pin, peran)
          VALUES ('Siti Supervisor', '888888', 'Supervisor')
        ''');
      }
    }

    // Migrasi versi 3: Tambah tabel pelanggan (Modul M13)
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS pelanggan (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          kode_pelanggan TEXT UNIQUE NOT NULL,
          nama_pelanggan TEXT NOT NULL,
          nomor_wa TEXT NOT NULL,
          alamat TEXT NOT NULL,
          latitude REAL,
          longitude REAL,
          created_at TEXT NOT NULL
        )
      ''');
      final countPelanggan = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM pelanggan'),
      ) ?? 0;
      if (countPelanggan == 0) {
        await db.rawInsert('''
          INSERT INTO pelanggan (kode_pelanggan, nama_pelanggan, nomor_wa, alamat, latitude, longitude, created_at)
          VALUES ('CUST-001', 'Warung Bu Siti', '081234567890', 'Jl. Hasan Basri No. 12, Banjarmasin', -3.298280, 114.588820, '2026-11-01 09:00:00')
        ''');
        await db.rawInsert('''
          INSERT INTO pelanggan (kode_pelanggan, nama_pelanggan, nomor_wa, alamat, latitude, longitude, created_at)
          VALUES ('CUST-002', 'Budi Santoso', '085712345678', 'Jl. Kayu Tangi II No. 45, Banjarmasin', -3.295410, 114.582150, '2026-11-02 10:30:00')
        ''');
      }
    }
  }

  // ==========================================
  // METODE CRUD: TABEL PELANGGAN (MODUL M13)
  // ==========================================
  // 1. CREATE: Menyimpan data pelanggan baru
  Future<int> insertPelanggan(Pelanggan pelanggan) async {
    final db = await instance.database;
    return await db.insert('pelanggan', pelanggan.toMap());
  }

  // 2. READ: Mengambil seluruh daftar pelanggan diurutkan dari yang terbaru
  Future<List<Pelanggan>> getAllPelanggan() async {
    final db = await instance.database;
    final result = await db.query('pelanggan', orderBy: 'id DESC');
    return result.map((json) => Pelanggan.fromMap(json)).toList();
  }

  // 3. READ: Mencari pelanggan berdasarkan nama, nomor WA, atau kode member (SQL LIKE)
  Future<List<Pelanggan>> searchPelanggan(String keyword) async {
    final db = await instance.database;
    final result = await db.query(
      'pelanggan',
      where: 'nama_pelanggan LIKE ? OR nomor_wa LIKE ? OR kode_pelanggan LIKE ?',
      whereArgs: ['%$keyword%', '%$keyword%', '%$keyword%'],
      orderBy: 'id DESC',
    );
    return result.map((json) => Pelanggan.fromMap(json)).toList();
  }

  // 4. UPDATE: Memperbarui data profil dan koordinat GPS pelanggan
  Future<int> updatePelanggan(Pelanggan pelanggan) async {
    final db = await instance.database;
    return await db.update(
      'pelanggan',
      pelanggan.toMap(),
      where: 'id = ?',
      whereArgs: [pelanggan.id],
    );
  }

  // 5. DELETE: Menghapus data pelanggan berdasarkan ID
  Future<int> deletePelanggan(int id) async {
    final db = await instance.database;
    return await db.delete('pelanggan', where: 'id = ?', whereArgs: [id]);
  }

  // 6. COUNT: Menghitung total jumlah pelanggan terdaftar untuk ringkasan Dashboard / Tab Toko
  Future<int> countPelanggan() async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT COUNT(*) as total FROM pelanggan');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // ==========================================
  // METODE CRUD: TABEL KARYAWAN (MODUL M12)
  // ==========================================
  Future<int> insertKaryawan(Karyawan karyawan) async {
    final db = await instance.database;
    return await db.insert('karyawan', karyawan.toMap());
  }

  Future<List<Karyawan>> getAllKaryawan() async {
    final db = await instance.database;
    final result = await db.query('karyawan', orderBy: 'id ASC');
    return result.map((json) => Karyawan.fromMap(json)).toList();
  }

  Future<int> updateKaryawan(Karyawan karyawan) async {
    final db = await instance.database;
    return await db.update(
      'karyawan',
      karyawan.toMap(),
      where: 'id = ?',
      whereArgs: [karyawan.id],
    );
  }

  Future<int> deleteKaryawan(int id) async {
    final db = await instance.database;
    return await db.delete(
      'karyawan',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==========================================
  // METODE CRUD: TABEL PRODUK (MODUL M11)
  // ==========================================
  Future<int> insertProduk(Produk produk) async {
    final db = await instance.database;
    return await db.insert('produk', produk.toMap());
  }

  Future<List<Produk>> getAllProduk() async {
    final db = await instance.database;
    // Mengurutkan harga terendah ke tertinggi sesuai P11 Live Tweak 2
    final result = await db.query('produk', orderBy: 'harga_jual ASC');
    return result.map((json) => Produk.fromMap(json)).toList();
  }

  Future<List<Produk>> getProdukByKategori(String kategori) async {
    final db = await instance.database;
    if (kategori == 'Semua') {
      return await getAllProduk();
    }
    final result = await db.query(
      'produk',
      where: 'kategori = ?',
      whereArgs: [kategori],
      orderBy: 'harga_jual ASC',
    );
    return result.map((json) => Produk.fromMap(json)).toList();
  }

  Future<List<Produk>> searchProduk(String keyword) async {
    final db = await instance.database;
    final result = await db.query(
      'produk',
      where: 'nama_produk LIKE ?',
      whereArgs: ['%$keyword%'],
      orderBy: 'harga_jual ASC',
    );
    return result.map((json) => Produk.fromMap(json)).toList();
  }

  Future<int> updateProduk(Produk produk) async {
    final db = await instance.database;
    return await db.update(
      'produk',
      produk.toMap(),
      where: 'id = ?',
      whereArgs: [produk.id],
    );
  }

  Future<int> deleteProduk(int id) async {
    final db = await instance.database;
    return await db.delete(
      'produk',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> countProduk() async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT COUNT(*) as total FROM produk');
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
