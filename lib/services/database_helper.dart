import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart'; // For kDebugMode

class DatabaseHelper {
  static const _dbName = "notes_app.db";
  static const _dbVersion = 1;

  static const String tableName = "notes";

  static const String columnId = "_id";
  static const String columnIdS = "id_s";
  static const String columnTitle = "title";
  static const String columnContent = "content";
  static const String columnCreatedAt = "created_at";
  static const String columnUpdatedAt = "updated_at";

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
    String path = join(documentsDirectory.path, _dbName);
    if (kDebugMode) {
      print("Database path: $path");
    }
    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    if (kDebugMode) {
      print("DatabaseHelper: _onCreate called for version $version");
    }
    await db.execute('''
      CREATE TABLE $tableName (
        $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnIdS TEXT UNIQUE NOT NULL,
        $columnTitle TEXT NOT NULL,
        $columnContent TEXT NOT NULL,
        $columnCreatedAt TEXT NOT NULL,
        $columnUpdatedAt TEXT NOT NULL
      )
    ''');
    if (kDebugMode) {
      print("DatabaseHelper: Table '$tableName' created successfully.");
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (kDebugMode) {
      print("DatabaseHelper: _onUpgrade called from $oldVersion to $newVersion");
    }
  }

  Future<int> insert(Map<String, dynamic> row) async {
    Database db = await instance.database;
    if (kDebugMode) {
      print("DatabaseHelper: Inserting into $tableName: $row");
    }
    try {
      return await db.insert(tableName, row, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      if (kDebugMode) {
        print("DatabaseHelper: Error inserting into $tableName: $e");
        print("Row data was: $row");
      }
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> queryAllNoteMetadata() async {
    Database db = await instance.database;
    if (kDebugMode) {
      print("DatabaseHelper: Querying all metadata from $tableName");
    }
    try {
      return await db.query(
        tableName,
        columns: [columnIdS, columnTitle, columnUpdatedAt],
        orderBy: "$columnUpdatedAt DESC", // Show newest first
      );
    } catch (e) {
      if (kDebugMode) {
        print("DatabaseHelper: Error querying metadata from $tableName: $e");
      }
      if (e.toString().contains("no such table")) {
        return []; // Or rethrow if this shouldn't happen silently
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> queryFullNote(String idS) async {
    Database db = await instance.database;
    if (kDebugMode) {
      print("DatabaseHelper: Querying full note with id_s $idS from $tableName");
    }
    List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: '$columnIdS = ?',
      whereArgs: [idS],
    );
    if (maps.isNotEmpty) {
      return maps.first;
    }
    return null;
  }

  Future<int> update(Map<String, dynamic> row) async {
    Database db = await instance.database;
    String idS = row[columnIdS] as String;
    if (kDebugMode) {
      print("DatabaseHelper: Updating row with id_s $idS in $tableName: $row");
    }
    try {
      return await db.update(
        tableName,
        row,
        where: '$columnIdS = ?',
        whereArgs: [idS],
      );
    } catch (e) {
      if (kDebugMode) {
        print("DatabaseHelper: Error updating $tableName for id_s $idS: $e");
        print("Row data was: $row");
      }
      rethrow;
    }
  }


  Future<int> delete(String idS) async {
    Database db = await instance.database;
    if (kDebugMode) {
      print("DatabaseHelper: Deleting row with id_s $idS from $tableName");
    }
    try {
      return await db.delete(
        tableName,
        where: '$columnIdS = ?',
        whereArgs: [idS],
      );
    } catch (e) {
      if (kDebugMode) {
        print("DatabaseHelper: Error deleting from $tableName for id_s $idS: $e");
      }
      rethrow;
    }
  }

  Future close() async {
    final db = await instance.database;
    _database = null;
    db.close();
    if (kDebugMode) {
      print("DatabaseHelper: Database closed.");
    }
  }

  Future<void> deleteDatabaseFile() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _dbName);
    if (await databaseExists(path)) {
      if (kDebugMode) {
        print("DatabaseHelper: Deleting database file at $path");
      }
      await deleteDatabase(path);
      _database = null;
    } else {
      if (kDebugMode) {
        print("DatabaseHelper: Database file at $path does not exist. Nothing to delete.");
      }
    }
  }
}
