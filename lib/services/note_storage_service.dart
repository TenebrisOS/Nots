// lib/services/note_storage_service.dart
import '../models/note_metadata.dart'; // Import the NoteMetadata model

// Mock/Placeholder for Note Storage
// In a real app, this would interact with local DB, file system, or a remote API.
class NoteStorageService { // Renamed from NoteTxtStorageService for generality
  final List<NoteMetadata> _mockLocalNotes = [];
  int _nextId = 1;

  // --- Local Notes Specific Methods ---
  Future<List<NoteMetadata>> getAllLocalNoteMetadata() async {
    await Future.delayed(const Duration(milliseconds: 150)); // Simulate async
    _mockLocalNotes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return List<NoteMetadata>.from(_mockLocalNotes);
  }

  Future<Map<String, String>?> getLocalFullNote(String noteId) async {
    await Future.delayed(const Duration(milliseconds: 50));
    try {
      final note = _mockLocalNotes.firstWhere((n) => n.id == noteId);
      return {'title': note.title, 'content': 'This is the full local content for ${note.title}. Details...'};
    } catch (e) {
      return null;
    }
  }

  Future<void> createLocalNote({required String title, required String content}) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final newNote = NoteMetadata(
      id: 'local$_nextId',
      title: title.isEmpty ? "Untitled Local Note" : title,
      updatedAt: DateTime.now(),
    );
    _mockLocalNotes.add(newNote);
    _nextId++;
    print("Local Mock Note Created: ${newNote.title}");
  }

  Future<void> deleteLocalNote(String noteId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _mockLocalNotes.removeWhere((note) => note.id == noteId);
    print("Local Mock Note Deleted: $noteId");
  }

  // --- Online Notes Methods (Placeholders) ---
  // You would implement these to interact with your server
  Future<List<NoteMetadata>> getAllOnlineNoteMetadata(String serverUrl, String token) async {
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate network
    print("Fetching online notes from $serverUrl with token: $token (mock)");
    // Example: return [ NoteMetadata(id: 'online1', title: 'Synced Note', updatedAt: DateTime.now()) ];
    return []; // Return empty list for now
  }

  Future<Map<String, String>?> getOnlineFullNote(String noteId, String serverUrl, String token) async {
    await Future.delayed(const Duration(milliseconds: 100));
    print("Fetching full online note $noteId from $serverUrl (mock)");
    return null; // Placeholder
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
