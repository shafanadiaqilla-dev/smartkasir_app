// Mengimpor pustaka deteksi platform Flutter (untuk memeriksa peramban web kIsWeb)
import 'package:flutter/foundation.dart';
// Mengimpor pustaka inti SQLite untuk Flutter
import 'package:sqflite/sqflite.dart';
// Mengimpor pustaka penggabungan path direktori berkas lokal
import 'package:path/path.dart';
// Mengimpor implementasi SQLite FFI khusus peramban Web Google Chrome
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
// Mengimpor model data produk dan karyawan
import '../models/produk.dart';
import '../models/karyawan.dart';

// Kelas pengelola koneksi dan operasi basis data SQLite lokal SmartKasir
class DatabaseHelper {
  // --- 1. PENERAPAN DESIGN PATTERN SINGLETON ---
  // Deklarasi instansi statis tunggal kelas DatabaseHelper yang diakses dari seluruh widget
  static final DatabaseHelper instance = DatabaseHelper._init();

  // Variabel penampung objek koneksi database aktif (Nullable '?' sebelum diinisialisasi)
  static Database? _database;

  // Konstruktor privat: Mengunci kelas agar tidak dapat diinstansiasi dengan 'DatabaseHelper()' secara bebas
  DatabaseHelper._init();

  // --- 2. GETTER DATABASE ASINKRON ---
  // Mengembalikan koneksi database aktif yang sudah ada, atau menginisialisasi baru jika belum pernah dibuka
  Future<Database> get database async {
    // KONTROL PERCABANGAN LOGIKA: Jika objek database sudah hidup di memori, langsung kembalikan
    if (_database != null) return _database!;

    // Jika belum ada, inisialisasi berkas basis data baru
    _database = await _initDB('smartkasir.db');
    return _database!;
  }

  // --- 3. INISIALISASI BERKAS BASIS DATA (DUAL-PLATFORM CHROME & ANDROID) ---
  Future<Database> _initDB(String filePath) async {
    // KONTROL PERCABANGAN DUAL PLATFORM:
    // Jika aplikasi berjalan di Google Chrome (Flutter Web), gunakan web database factory
    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
      return await openDatabase(
        filePath,
        version: 2,
        onCreate: _createDB,
        onUpgrade: _onUpgradeDB,
        onOpen: _onOpenDB,
      );
    }

    // Jika berjalan di smartphone Android fisik / emulator:
    final dbPath = await getDatabasesPath(); // Mengambil jalur folder basis data internal OS
    final path = join(dbPath, filePath); // Menggabungkan direktori dengan nama berkas 'smartkasir.db'

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _onUpgradeDB,
      onOpen: _onOpenDB,
    );
  }

  // --- KONTROL SINKRONISASI DATA AWAL SAAT BASIS DATA DIBUKA ---
  Future _onOpenDB(Database db) async {
    // Sinkronisasi data awal produk
    for (final produk in produkAwalSQLite) {
      final exists = await db.query(
        'produk',
        where: 'kode_produk = ?',
        whereArgs: [produk.kodeProduk],
      );
      if (exists.isEmpty) {
        await db.insert('produk', produk.toMap());
      }
    }

    // Pastikan tabel karyawan tersedia dan memiliki data awal
    await db.execute('''
      CREATE TABLE IF NOT EXISTS karyawan (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nama_karyawan TEXT NOT NULL,
        pin TEXT NOT NULL,
        peran TEXT NOT NULL
      )
    ''');

    final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM karyawan')) ?? 0;
    if (count == 0) {
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

  // --- 4. DDL: PEMBUATAN STRUKTUR TABEL & SEEDING DATA AWAL (VERSI 2) ---
  Future _createDB(Database db, int version) async {
    // 1. Eksekusi kueri DDL CREATE TABLE produk di database SQLite
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

    // Seeding data awal produk
    for (final produk in produkAwalSQLite) {
      await db.insert('produk', produk.toMap());
    }

    // 2. Eksekusi kueri DDL CREATE TABLE karyawan
    await db.execute('''
      CREATE TABLE karyawan (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nama_karyawan TEXT NOT NULL,
        pin TEXT NOT NULL,
        peran TEXT NOT NULL
      )
    ''');

    // 3. Seeding data staf awal (PIN 6 digit selaras Tantangan 2)
    await db.rawInsert('''
      INSERT INTO karyawan (nama_karyawan, pin, peran)
      VALUES ('Ahmad Kasir', '123456', 'Kasir')
    ''');
    await db.rawInsert('''
      INSERT INTO karyawan (nama_karyawan, pin, peran)
      VALUES ('Siti Supervisor', '888888', 'Supervisor')
    ''');
  }

  // --- DDL: MIGRASI SKEMA JIKA VERSI DATABASE DITINGKATKAN ---
  Future _onUpgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS karyawan (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          nama_karyawan TEXT NOT NULL,
          pin TEXT NOT NULL,
          peran TEXT NOT NULL
        )
      ''');

      final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM karyawan')) ?? 0;
      if (count == 0) {
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
  }

  // ==========================================
  // METODE CRUD: TABEL KARYAWAN (MODUL M12)
  // ==========================================

  // 1. CREATE: Menyimpan Karyawan Baru
  Future<int> insertKaryawan(Karyawan karyawan) async {
    final db = await instance.database;
    return await db.insert('karyawan', karyawan.toMap());
  }

  // 2. READ: Mengambil Seluruh Karyawan
  Future<List<Karyawan>> getAllKaryawan() async {
    final db = await instance.database;
    final result = await db.query('karyawan', orderBy: 'id ASC');
    return result.map((json) => Karyawan.fromMap(json)).toList();
  }

  // 3. UPDATE: Memperbarui Data Karyawan
  Future<int> updateKaryawan(Karyawan karyawan) async {
    final db = await instance.database;
    return await db.update(
      'karyawan',
      karyawan.toMap(),
      where: 'id = ?',
      whereArgs: [karyawan.id],
    );
  }

  // 4. DELETE: Menghapus Karyawan Berdasarkan ID
  Future<int> deleteKaryawan(int id) async {
    final db = await instance.database;
    return await db.delete(
      'karyawan',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==========================================
  // METODE CRUD: TABEL PRODUK (DARI MINGGU 11)
  // ==========================================

  // 1. DML CREATE: Menambahkan Produk Baru
  Future<int> insertProduk(Produk produk) async {
    final db = await instance.database;
    final id = await db.insert(
      'produk',
      produk.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return id;
  }

  // 2. DML READ: Mengambil Seluruh Daftar Produk (urut harga_jual ASC sesuai Live Tweak 2)
  Future<List<Produk>> getAllProduk() async {
    final db = await instance.database;
    final result = await db.query('produk', orderBy: 'harga_jual ASC');
    return result.map((json) => Produk.fromMap(json)).toList();
  }

  // 3. DML READ DENGAN FILTER KATEGORI
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

  // 4. DML SEARCH: Pencarian Produk (SQL LIKE)
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

  // 5. DML UPDATE: Memperbarui Data Produk
  Future<int> updateProduk(Produk produk) async {
    final db = await instance.database;
    return await db.update(
      'produk',
      produk.toMap(),
      where: 'id = ?',
      whereArgs: [produk.id],
    );
  }

  // 6. DML DELETE: Menghapus Produk dari SQLite
  Future<int> deleteProduk(int id) async {
    final db = await instance.database;
    return await db.delete(
      'produk',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
