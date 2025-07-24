import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p; // For p.join

class NoteDbModel {
  final String id;
  final String title;
  final String content;
  final String updatedAt; // Field name

  NoteDbModel({
    required this.id,
    required this.title,
    required this.content,
    required this.updatedAt, // Constructor parameter name
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'updated_at': updatedAt, // DB key
    };
  }

  factory NoteDbModel.fromMap(Map<String, dynamic> map) {
    return NoteDbModel(
      id: map['id'] as String,
      title: map['title'] as String,
      content: map['content'] as String,
      updatedAt: map['updated_at'] as String, // Ensure this matches constructor param name
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
  static const columnUpdatedAt = 'updated_at'; // ISO8601 String

  // Make this a singleton class
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  // Only have a single app-wide reference to the database
  static Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    // Lazily instantiate the db the first time it is accessed
    _database = await _initDatabase();
    return _database!;
  }

  // This opens the database (and creates it if it doesn't exist)
  _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = p.join(documentsDirectory.path, _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      // onUpgrade: _onUpgrade, // For future schema migrations
    );
  }

  // SQL code to create the database table
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

  // --- CRUD Methods for Notes ---

  Future<int> insertNote(NoteDbModel note) async {
    Database db = await instance.database;
    return await db.insert(tableNotes, note.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<NoteDbModel>> queryAllNotesMetadata() async {
    Database db = await instance.database;
    // Order by updated_at descending to get newest notes first
    final List<Map<String, dynamic>> maps = await db.query(
        tableNotes,
        columns: [columnId, columnTitle, columnUpdatedAt], // Only fetch metadata columns
        orderBy: '$columnUpdatedAt DESC'
    );
    return List.generate(maps.length, (i) {
      return NoteDbModel.fromMap({ // Reconstruct with dummy content for metadata only
        'id': maps[i][columnId],
        'title': maps[i][columnTitle],
        'content': '', // Not needed for metadata list
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

// Future<int> updateNote(NoteDbModel note) async {
//   Database db = await instance.database;
//   return await db.update(
//     tableNotes,
//     note.toMap(),
//     where: '$columnId = ?',
//     whereArgs: [note.id],
//   );
// }

// Close the database (optional, as sqflite handles this, but good practice if needed)
// Future close() async {
//   final db = await instance.database;
//   db.close();
// }
}
