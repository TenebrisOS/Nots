// lib/services/note_storage_service.dart
import '../models/note_metadata.dart';
import './database_helper.dart'; // Import DatabaseHelper
import 'package:uuid/uuid.dart'; // For generating unique IDs

// For online functionality
// import 'dart:convert';
// import 'package:http/http.dart' as http;

class NoteStorageService {
  final dbHelper = DatabaseHelper.instance;
  final _uuid = const Uuid(); // Create a Uuid instance

  // --- Local Notes Specific Methods (Using SQLite) ---

  Future<List<NoteMetadata>> getAllLocalNoteMetadata() async {
    final List<NoteDbModel> dbNotes = await dbHelper.queryAllNotesMetadata();
    return dbNotes.map((dbNote) => NoteMetadata(
      id: dbNote.id,
      title: dbNote.title,
      updatedAt: DateTime.parse(dbNote.updatedAt), // Parse from ISO string
    )).toList();
  }

  Future<Map<String, String>?> getLocalFullNote(String noteId) async {
    final NoteDbModel? dbNote = await dbHelper.queryNoteById(noteId);
    if (dbNote != null) {
      return {
        'id': dbNote.id,
        'title': dbNote.title,
        'content': dbNote.content,
        'updated_at': dbNote.updatedAt, // Pass as ISO string
      };
    }
    return null;
  }

  Future<void> createLocalNote({required String title, required String content}) async {
    final noteId = _uuid.v4(); // Generate a unique v4 UUID
    final now = DateTime.now();
    final newDbNote = NoteDbModel(
      id: noteId,
      title: title.isEmpty ? "Untitled Note" : title,
      content: content,
      updatedAt: now.toIso8601String(), // Store as ISO8601 string
    );
    await dbHelper.insertNote(newDbNote);
    print("Local DB Note Created: ${newDbNote.title} (ID: ${newDbNote.id})");
  }

  Future<void> deleteLocalNote(String noteId) async {
    await dbHelper.deleteNote(noteId);
    print("Local DB Note Deleted: $noteId");
  }

  // --- Online Notes Methods (Placeholders or your HTTP implementation) ---
  // These remain as placeholders or your actual HTTP logic for now.
  Future<List<NoteMetadata>> getAllOnlineNoteMetadata(String serverUrl, String token) async {
    await Future.delayed(const Duration(milliseconds: 500));
    print("Fetching online notes from $serverUrl with token: $token (mock)");
    // TODO: Implement actual HTTP call to your server
    return [];
  }

  Future<Map<String, String>?> getOnlineFullNote(String noteId, String serverUrl, String token) async {
    await Future.delayed(const Duration(milliseconds: 100));
    print("Fetching full online note $noteId from $serverUrl (mock)");
    // TODO: Implement actual HTTP call
    return null;
  }

  Future<void> createOnlineNote({
    required String title,
    required String content,
    required String serverUrl,
    required String token
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    print("Creating online note '$title' on $serverUrl (mock)");
    // TODO: Implement actual HTTP call
  }

  Future<void> deleteOnlineNote(String noteId, String serverUrl, String token) async {
    await Future.delayed(const Duration(milliseconds: 200));
    print("Deleting online note $noteId on $serverUrl (mock)");
    // TODO: Implement actual HTTP call
  }
}
