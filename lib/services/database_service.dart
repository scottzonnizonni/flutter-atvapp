import 'package:sqflite/sqflite.dart'; // Add sqflite import
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart'; // Import full foundation for debugPrint
import '../models/content_model.dart';
import '../models/user_model.dart'; // Changed to UserModel
import '../models/scan_history_model.dart';
import '../utils/constants.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;
  static bool _initialized = false;

  DatabaseService._init();

  // Initialize database factory for web/desktop
  static void _initializeDatabaseFactory() {
    if (_initialized) return;

    if (kIsWeb) {
      // Use FFI Web for web platform
      databaseFactory = databaseFactoryFfiWeb;
    } else if (!Platform.isAndroid && !Platform.isIOS) {
      // Use FFI for desktop platforms (Windows, macOS, Linux)
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    // For Android and iOS, use default sqflite implementation
    _initialized = true;
  }

  Future<Database> get database async {
    _initializeDatabaseFactory();
    if (_database != null) return _database!;
    _database = await _initDB(AppConstants.databaseName);
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: AppConstants.databaseVersion,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await _createContentTable(db);
    await _createUserTable(db); // Changed to User table
    await _createScanHistoryTable(db);

    // Insert default admin
    await _insertDefaultAdmin(db);

    // Insert sample content
    await _insertSampleContent(db);
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Upgrade from v1 to v2: Migrate Admin to User table
      // Drop old admin table and create new one with more fields
      await db.execute('DROP TABLE IF EXISTS admin');
      await _createUserTable(db);
      await _insertDefaultAdmin(db);
    }
  }

  Future<void> _createContentTable(Database db) async {
    await db.execute('''
      CREATE TABLE content (
        id TEXT PRIMARY KEY,
        qr_code_id TEXT UNIQUE NOT NULL,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        category TEXT NOT NULL,
        image_path TEXT,
        latitude REAL,
        longitude REAL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _createUserTable(Database db) async {
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        username TEXT UNIQUE NOT NULL,
        email TEXT UNIQUE NOT NULL,
        full_name TEXT NOT NULL,
        phone TEXT,
        password_hash TEXT NOT NULL,
        role TEXT NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1,
        must_change_password INTEGER NOT NULL DEFAULT 0,
        last_login_at TEXT,
        created_at TEXT NOT NULL,
        created_by TEXT,
        updated_at TEXT NOT NULL,
        updated_by TEXT
      )
    ''');
  }

  Future<void> _createScanHistoryTable(Database db) async {
    await db.execute('''
      CREATE TABLE scan_history (
        id TEXT PRIMARY KEY,
        content_id TEXT NOT NULL,
        qr_code_id TEXT NOT NULL,
        scanned_at TEXT NOT NULL,
        FOREIGN KEY (content_id) REFERENCES content (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _insertDefaultAdmin(Database db) async {
    final uuid = const Uuid();
    final now = DateTime.now();

    // Check if default admin already exists to avoid duplicates
    final result = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [AppConstants.defaultAdminUsername],
    );

    if (result.isNotEmpty) return;

    final admin = UserModel(
      id: uuid.v4(),
      username: AppConstants.defaultAdminUsername,
      email: AppConstants
          .defaultAdminUsername, // Use username as email for default
      fullName: 'Super Administrador',
      passwordHash: UserModel.hashPassword(AppConstants.defaultAdminPassword),
      role: UserRole.superAdmin,
      createdAt: now,
      updatedAt: now,
    );

    await db.insert('users', admin.toMap());
  }

  Future<void> _insertSampleContent(Database db) async {
    // Only insert if table is empty
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM content'),
    );
    if (count != null && count > 0) return;

    final uuid = const Uuid();
    final now = DateTime.now();

    final sampleContents = [
      ContentModel(
        id: uuid.v4(),
        qrCodeId: 'QR: TV.CNT.TREE',
        title: 'Unidade de Beneficiamento de Cacau',
        description:
            'A unidade de beneficiamento é onde acontece a magia da transformação do cacau em chocolate. Aqui as amêndoas passam por fermentação controlada, secagem, torrefação, moagem e conchagem. O resultado é um chocolate fino, com identidade territorial única.',
        category: 'INFRAESTRUTURAS',
        latitude: -19.427102,
        longitude: -42.551957,
        createdAt: now,
        updatedAt: now,
      ),
      ContentModel(
        id: uuid.v4(),
        qrCodeId: 'QR: TV.PRD.CACAU',
        title: 'Cacaueiro',
        description:
            'O cacaueiro é a base econômica de Terra Vista. Seu nome científico significa "alimento dos deuses". Cultivado em sistema agroflorestal, convive com outras espécies nativas, promovendo biodiversidade e sustentabilidade.',
        category: 'PRODUÇÃO',
        latitude: -19.427500,
        longitude: -42.552000,
        createdAt: now,
        updatedAt: now,
      ),
      ContentModel(
        id: uuid.v4(),
        qrCodeId: 'QR: TV.HIS.PRACA',
        title: 'Praça da Resistência',
        description:
            'O coração do assentamento, onde a comunidade se reúne para celebrar conquistas, debater o futuro e fortalecer os laços de solidariedade. Este espaço simboliza a luta pela terra e a construção coletiva de um território de vida.',
        category: 'HISTÓRIA',
        latitude: -19.426800,
        longitude: -42.551800,
        createdAt: now,
        updatedAt: now,
      ),
    ];

    for (var content in sampleContents) {
      await db.insert('content', content.toMap());
    }
  }

  // CONTENT CRUD OPERATIONS

  Future<ContentModel> createContent(ContentModel content) async {
    final db = await database;
    await db.insert('content', content.toMap());
    return content;
  }

  Future<List<ContentModel>> getAllContent() async {
    final db = await database;
    final result = await db.query('content', orderBy: 'created_at DESC');
    return result.map((map) => ContentModel.fromMap(map)).toList();
  }

  Future<ContentModel?> getContentById(String id) async {
    final db = await database;
    final result = await db.query('content', where: 'id = ?', whereArgs: [id]);

    if (result.isNotEmpty) {
      return ContentModel.fromMap(result.first);
    }
    return null;
  }

  Future<ContentModel?> getContentByQrCodeId(String qrCodeId) async {
    final db = await database;
    final result = await db.query(
      'content',
      where: 'qr_code_id = ?',
      whereArgs: [qrCodeId],
    );

    if (result.isNotEmpty) {
      return ContentModel.fromMap(result.first);
    }
    return null;
  }

  Future<int> updateContent(ContentModel content) async {
    final db = await database;
    return await db.update(
      'content',
      content.toMap(),
      where: 'id = ?',
      whereArgs: [content.id],
    );
  }

  Future<int> deleteContent(String id) async {
    final db = await database;
    return await db.delete('content', where: 'id = ?', whereArgs: [id]);
  }

  // USER MANAGEMENT OPERATIONS

  Future<UserModel?> getUserByUsername(String username) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
    );

    if (result.isNotEmpty) {
      return UserModel.fromMap(result.first);
    }
    return null;
  }

  Future<List<UserModel>> getAllUsers() async {
    final db = await database;
    final result = await db.query('users', orderBy: 'full_name ASC');
    return result.map((map) => UserModel.fromMap(map)).toList();
  }

  Future<bool> createUser(UserModel user) async {
    try {
      final db = await database;
      await db.insert('users', user.toMap());
      return true;
    } catch (e) {
      debugPrint('Error creating user: $e');
      return false;
    }
  }

  Future<bool> updateUser(UserModel user) async {
    try {
      final db = await database;
      await db.update(
        'users',
        user.toMap(),
        where: 'id = ?',
        whereArgs: [user.id],
      );
      return true;
    } catch (e) {
      debugPrint('Error updating user: $e');
      return false;
    }
  }

  Future<bool> deleteUser(String id) async {
    try {
      final db = await database;
      await db.delete('users', where: 'id = ?', whereArgs: [id]);
      return true;
    } catch (e) {
      debugPrint('Error deleting user: $e');
      return false;
    }
  }

  Future<UserModel?> authenticateUser(String username, String password) async {
    final user = await getUserByUsername(username);
    if (user != null && user.isActive && user.verifyPassword(password)) {
      // Update last login
      await updateUser(user.copyWith(lastLoginAt: DateTime.now()));
      return user;
    }
    return null;
  }

  // SCAN HISTORY OPERATIONS

  Future<ScanHistoryModel> addScanHistory(
    String contentId,
    String qrCodeId,
  ) async {
    final db = await database;
    final uuid = const Uuid();
    final history = ScanHistoryModel(
      id: uuid.v4(),
      contentId: contentId,
      qrCodeId: qrCodeId,
      scannedAt: DateTime.now(),
    );

    await db.insert('scan_history', history.toMap());
    return history;
  }

  Future<List<ScanHistoryModel>> getAllScanHistory() async {
    final db = await database;
    final result = await db.query('scan_history', orderBy: 'scanned_at DESC');
    return result.map((map) => ScanHistoryModel.fromMap(map)).toList();
  }

  Future<int> clearScanHistory() async {
    final db = await database;
    return await db.delete('scan_history');
  }

  // Close database
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
