import '../models/note_metadata.dart';

class NoteStorageService {
  final List<NoteMetadata> _mockLocalNotes = [];
  final Map<String, String> _mockLocalNoteContents = {};
  int _nextId = 1;

  // --- Local Notes Specific Methods ---
  Future<List<NoteMetadata>> getAllLocalNoteMetadata() async {
    await Future.delayed(const Duration(milliseconds: 150));
    _mockLocalNotes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return List<NoteMetadata>.from(_mockLocalNotes);
  }

  Future<Map<String, String>?> getLocalFullNote(String noteId) async {
    await Future.delayed(const Duration(milliseconds: 50));
    try {
      final noteMetadata = _mockLocalNotes.firstWhere((n) => n.id == noteId);
      final content = _mockLocalNoteContents[noteId]; // <-- RETRIEVE ACTUAL CONTENT

      if (content != null) {
        return {'title': noteMetadata.title, 'content': content};
      } else {
        // Fallback if content somehow wasn't stored (should not happen with createLocalNote change)
        return {'title': noteMetadata.title, 'content': 'Content not found.'};
      }
    } catch (e) {
      // This catch is for when _mockLocalNotes.firstWhere fails (noteId not in metadata)
      print("Error getting full note: Note metadata not found for ID $noteId. $e");
      return null;
    }
  }

  Future<void> createLocalNote({required String title, required String content}) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final noteId = 'local$_nextId';
    final newNoteMetadata = NoteMetadata(
      id: noteId,
      title: title.isEmpty ? "Untitled Local Note" : title,
      updatedAt: DateTime.now(),
    );
    _mockLocalNotes.add(newNoteMetadata);
    _mockLocalNoteContents[noteId] = content;
    _nextId++;
    print("Local Mock Note Created: ${newNoteMetadata.title} (ID: $noteId)");
  }

  Future<void> deleteLocalNote(String noteId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _mockLocalNotes.removeWhere((note) => note.id == noteId);
    _mockLocalNoteContents.remove(noteId);
    print("Local Mock Note Deleted: $noteId");
  }

  Future<List<NoteMetadata>> getAllOnlineNoteMetadata(String serverUrl, String token) async {
    await Future.delayed(const Duration(milliseconds: 500));
    print("Fetching online notes from $serverUrl with token: $token (mock)");
    return [];
  }

  Future<Map<String, String>?> getOnlineFullNote(String noteId, String serverUrl, String token) async {
    await Future.delayed(const Duration(milliseconds: 100));
    print("Fetching full online note $noteId from $serverUrl (mock)");
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
  }

  Future<void> deleteOnlineNote(String noteId, String serverUrl, String token) async {
    await Future.delayed(const Duration(milliseconds: 200));
    print("Deleting online note $noteId on $serverUrl (mock)");
  }
}
