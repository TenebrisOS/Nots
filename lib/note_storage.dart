import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import 'notes_system.dart'; // For generating unique IDs
// Import your NoteMetadata model
// import 'note_model.dart';

class NoteTxtStorageService {
  final Uuid _uuid = Uuid();

  Future<String> get _documentsPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<String> get _notesDirectoryPath async {
    final path = await _documentsPath;
    final notesDir = Directory('$path/notes');
    if (!await notesDir.exists()) {
      await notesDir.create(recursive: true);
    }
    return notesDir.path;
  }

  Future<File> get _indexFile async {
    final path = await _documentsPath;
    return File('$path/notes_index.json');
  }

  // --- Index File Operations ---
  Future<List<NoteMetadata>> _loadMetadataIndex() async {
    try {
      final file = await _indexFile;
      if (!await file.exists()) {
        return [];
      }
      final contents = await file.readAsString();
      if (contents.isEmpty) {
        return [];
      }
      final List<dynamic> jsonData = jsonDecode(contents);
      return jsonData
          .map((item) => NoteMetadata.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print("Error loading metadata index: $e");
      return [];
    }
  }

  Future<void> _saveMetadataIndex(List<NoteMetadata> metadataList) async {
    final file = await _indexFile;
    final jsonString =
    jsonEncode(metadataList.map((m) => m.toJson()).toList());
    await file.writeAsString(jsonString);
  }

  // --- Note File (.txt) Operations ---
  Future<String?> _readNoteContent(String noteId) async {
    try {
      final notesPath = await _notesDirectoryPath;
      final file = File('$notesPath/$noteId.txt');
      if (await file.exists()) {
        return await file.readAsString();
      }
      return null;
    } catch (e) {
      print("Error reading note content for $noteId: $e");
      return null;
    }
  }

  Future<void> _writeNoteContent(String noteId, String content) async {
    try {
      final notesPath = await _notesDirectoryPath;
      final file = File('$notesPath/$noteId.txt');
      await file.writeAsString(content);
    } catch (e) {
      print("Error writing note content for $noteId: $e");
    }
  }

  Future<void> _deleteNoteContentFile(String noteId) async {
    try {
      final notesPath = await _notesDirectoryPath;
      final file = File('$notesPath/$noteId.txt');
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      print("Error deleting note content file for $noteId: $e");
    }
  }

  // --- Public API for Notes ---

  Future<List<NoteMetadata>> getAllNoteMetadata() async {
    return await _loadMetadataIndex();
  }

  // To display a full note, you'd combine metadata and content
  Future<Map<String, dynamic>?> getFullNote(String noteId) async {
    final metadataList = await _loadMetadataIndex();
    final metadata = metadataList.firstWhere((m) => m.id == noteId,
        orElse: () => NoteMetadata(id: '', title: '', createdAt: DateTime.now(), updatedAt: DateTime.now()) // A bit hacky, handle properly
    );

    if (metadata.id.isEmpty) return null; // Note not found in index

    final content = await _readNoteContent(noteId);
    if (content == null) return null; // Content file missing (should not happen if index is correct)

    return {
      'id': metadata.id,
      'title': metadata.title,
      'createdAt': metadata.createdAt,
      'updatedAt': metadata.updatedAt,
      'content': content,
    };
  }


  Future<String> createNote({required String title, required String content}) async {
    final noteId = _uuid.v4();
    final now = DateTime.now();
    final newMetadata = NoteMetadata(
        id: noteId, title: title, createdAt: now, updatedAt: now);

    final metadataList = await _loadMetadataIndex();
    metadataList.add(newMetadata);

    await _writeNoteContent(noteId, content);
    await _saveMetadataIndex(metadataList);
    return noteId;
  }

  Future<void> updateNote({
    required String noteId,
    String? newTitle,
    String? newContent,
  }) async {
    final metadataList = await _loadMetadataIndex();
    final noteIndex = metadataList.indexWhere((m) => m.id == noteId);

    if (noteIndex == -1) {
      print("Note with ID $noteId not found for update.");
      return;
    }

    bool metadataChanged = false;
    NoteMetadata currentMetadata = metadataList[noteIndex];

    if (newTitle != null && currentMetadata.title != newTitle) {
      currentMetadata.title = newTitle;
      metadataChanged = true;
    }

    if (newContent != null) {
      await _writeNoteContent(noteId, newContent);
      // If content changes, always update the 'updatedAt' timestamp
      metadataChanged = true;
    }

    if (metadataChanged) {
      currentMetadata.updatedAt = DateTime.now();
      metadataList[noteIndex] = currentMetadata;
      await _saveMetadataIndex(metadataList);
    }
  }

  Future<void> deleteNote(String noteId) async {
    final metadataList = await _loadMetadataIndex();
    metadataList.removeWhere((m) => m.id == noteId);

    await _saveMetadataIndex(metadataList);
    await _deleteNoteContentFile(noteId);
  }
}