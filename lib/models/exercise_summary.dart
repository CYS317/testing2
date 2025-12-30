import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:intl/intl.dart';

class ExerciseSummary {
  final int? id;
  final String name;
  final String exerciseType;
  final int focusSeconds;   
  final int unfocusSeconds; 
  final int totalSeconds;
  final double focusPercent;
  final double unfocusPercent;
  final String timestamp;
  final String username;

  ExerciseSummary({
    this.id,
    required this.name,
    required this.exerciseType,
    required this.focusSeconds,
    required this.unfocusSeconds,
    required this.totalSeconds,
    required this.focusPercent,
    required this.unfocusPercent,
    required this.timestamp,
    required this.username,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'exerciseType': exerciseType,
      'focusSeconds': focusSeconds,
      'unfocusSeconds': unfocusSeconds,
      'totalSeconds': totalSeconds,
      'focusPercent': focusPercent,
      'unfocusPercent': unfocusPercent,
      'timestamp': timestamp,
      'username': username,
    };
  }

  factory ExerciseSummary.fromMap(Map<String, dynamic> map) {
    return ExerciseSummary(
      id: map['id'] as int?,
      name: map['name'] as String? ?? 'Unknown',
      exerciseType: map['exerciseType'] as String? ?? 'Unknown',
      focusSeconds: map['focusSeconds'] as int? ?? 0,
      unfocusSeconds: map['unfocusSeconds'] as int? ?? 0,
      totalSeconds: map['totalSeconds'] as int? ?? 0,
      focusPercent: (map['focusPercent'] as num?)?.toDouble() ?? 0.0,
      unfocusPercent: (map['unfocusPercent'] as num?)?.toDouble() ?? 0.0,
      timestamp: map['timestamp'] as String? ?? DateTime.now().toIso8601String(),
      username: map['username'] as String? ?? 'Unknown',
    );
  }

  String formattedTimestamp() {
    try {
      final dt = DateTime.parse(timestamp).toLocal();
      return DateFormat('yyyy-MM-dd HH:mm').format(dt);
    } catch (_) {
      return timestamp;
    }
  }
}

class ExerciseSummaryDatabase {
  static final ExerciseSummaryDatabase instance = ExerciseSummaryDatabase._internal();
  static Database? _database;

  ExerciseSummaryDatabase._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('exercise_summary.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 4,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE exercise_summary (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        exerciseType TEXT,
        focusSeconds INTEGER,
        unfocusSeconds INTEGER,
        totalSeconds INTEGER,
        focusPercent REAL DEFAULT 0,
        unfocusPercent REAL DEFAULT 0,
        timestamp TEXT,
        username TEXT
      )
    ''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 4) {
      await db.execute('ALTER TABLE exercise_summary ADD COLUMN username TEXT DEFAULT "Unknown"');
    }
  }

  Future<int> insertSummary(ExerciseSummary summary) async {
    final db = await instance.database;
    return await db.insert('exercise_summary', summary.toMap());
  }

  Future<List<ExerciseSummary>> getAllSummaries() async {
    final db = await instance.database;
    final result = await db.query('exercise_summary', orderBy: 'id DESC');
    return result.map((m) => ExerciseSummary.fromMap(m)).toList();
  }

  Future<List<ExerciseSummary>> getSummariesByUser(String username) async {
    final db = await instance.database;
    final result = await db.query(
      'exercise_summary',
      where: 'username = ?',
      whereArgs: [username],
      orderBy: 'id DESC',
    );
    return result.map((m) => ExerciseSummary.fromMap(m)).toList();
  }

  Future<int> deleteSummary(int id) async {
    final db = await instance.database;
    return await db.delete('exercise_summary', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteSummaryByUser(int id, String username) async {
    final db = await instance.database;
    return await db.delete(
      'exercise_summary',
      where: 'id = ? AND username = ?',
      whereArgs: [id, username],
    );
  }

  Future close() async {
    final db = await instance.database;
    await db.close();
  }
}
