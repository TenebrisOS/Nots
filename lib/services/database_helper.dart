import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p; // For p.join

class NoteDbModel {
  final String id;
  final String title;
  final String content;
  final String updatedAt; // Store as ISO8601 String (camelCase in model, snake_case in DB map)

  NoteDbModel({
    required this.id,
    required this.title,
    required this.content,
    required this.updatedAt, // camelCase constructor parameter
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'updated_at': updatedAt, // snake_case key for DB
    };
  }

  factory NoteDbModel.fromMap(Map<String, dynamic> map) {
    if (map['id'] == null || map['title'] == null || map['content'] == null || map['updated_at'] == null) {
      throw FormatException("Missing required fields in map for NoteDbModel. Received: $map");
    }
    return NoteDbModel(
      id: map['id'] as String,
      title: map['title'] as String,
      content: map['content'] as String,
      updatedAt: map['updated_at'] as String, // map key is snake_case, constructor param is camelCase
    );
  }
}

class DatabaseHelper {
  static const _databaseName = "LocalNotes.db";
  static const _databaseVersion = 1;

  static const tableNotes = 'notes';
  static const columnId = 'id';
  static const columnTitle = 'title';
  static const columnContent = 'content';
  static const columnUpdatedAt = 'updated_at'; // DB column name

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = p.join(documentsDirectory.path, _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
          CREATE TABLE $tableNotes (
            $columnId TEXT PRIMARY KEY,
            $columnTitle TEXT NOT NULL,
            $columnContent TEXT NOT NULL,
            $columnUpdatedAt TEXT NOT NULL
          )
          ''');
  }

  Future<int> insertNote(NoteDbModel note) async {
    Database db = await instance.database;
    return await db.insert(tableNotes, note.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<NoteDbModel>> queryAllNotesMetadata() async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
        tableNotes,
        columns: [columnId, columnTitle, columnUpdatedAt],
        orderBy: '$columnUpdatedAt DESC'
    );
    return List.generate(maps.length, (i) {
      return NoteDbModel.fromMap({
        'id': maps[i][columnId],
        'title': maps[i][columnTitle],
        'content': '', // Not needed for metadata list, but NoteDbModel.fromMap expects it
        'updated_at': maps[i][columnUpdatedAt]
      });
    });
  }

  Future<NoteDbModel?> queryNoteById(String id) async {
    Database db = await instance.database;
    List<Map<String, dynamic>> maps = await db.query(
        tableNotes,
        where: '$columnId = ?',
        whereArgs: [id],
        limit: 1
    );
    if (maps.isNotEmpty) {
      return NoteDbModel.fromMap(maps.first);
    }
    return null;
  }

  Future<int> deleteNote(String id) async {
    Database db = await instance.database;
    return await db.delete(
      tableNotes,
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }
}
