import '../models/note_metadata.dart';
import './database_helper.dart';
import 'package:uuid/uuid.dart';

class NoteStorageService {
  final dbHelper = DatabaseHelper.instance;
  final _uuid = const Uuid();

  // --- Local Notes Specific Methods (Using SQLite) ---

  Future<List<NoteMetadata>> getAllLocalNoteMetadata() async {
    final List<NoteDbModel> dbNotes = await dbHelper.queryAllNotesMetadata();
    return dbNotes
        .map(
          (dbNote) => NoteMetadata(
            id: dbNote.id,
            title: dbNote.title,
            updatedAt: DateTime.parse(dbNote.updatedAt),
          ),
        )
        .toList();
  }

  Future<Map<String, String>?> getLocalFullNote(String noteId) async {
    final NoteDbModel? dbNote = await dbHelper.queryNoteById(noteId);
    if (dbNote != null) {
      return {
        'id': dbNote.id,
        'title': dbNote.title,
        'content': dbNote.content,
        'updated_at': dbNote.updatedAt,
      };
    }
    return null;
  }

  Future<void> createLocalNote({
    required String title,
    required String content,
  }) async {
    final noteId = _uuid.v4();
    final now = DateTime.now();
    final newDbNote = NoteDbModel(
      id: noteId,
      title: title.isEmpty ? "Untitled Note" : title,
      content: content,
      updatedAt: now.toIso8601String(),
    );
    await dbHelper.insertNote(newDbNote);
  }

  Future<void> updateLocalNote({
    required String id,
    required String title,
    required String content,
  }) async {
    final now = DateTime.now();
    final updatedDbNote = NoteDbModel(
      id: id,
      title: title,
      content: content,
      updatedAt: now.toIso8601String(),
    );
    await dbHelper.updateNote(updatedDbNote);
  }

  Future<void> deleteLocalNote(String noteId) async {
    await dbHelper.deleteNote(noteId);
  }

  // --- Online Notes Methods (Placeholders) ---
  Future<List<NoteMetadata>> getAllOnlineNoteMetadata(
    String serverUrl,
    String token,
  ) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return [];
  }

  Future<Map<String, String>?> getOnlineFullNote(
    String noteId,
    String serverUrl,
    String token,
  ) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return null;
  }

  Future<void> createOnlineNote({
    required String title,
    required String content,
    required String serverUrl,
    required String token,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
  }

  Future<void> deleteOnlineNote(
    String noteId,
    String serverUrl,
    String token,
  ) async {
    await Future.delayed(const Duration(milliseconds: 200));
  }
}
