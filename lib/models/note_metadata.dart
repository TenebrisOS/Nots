// In lib/models/note_metadata.dart (or wherever it's defined)
class NoteMetadata {
  final String id;
  final String title;
  final DateTime updatedAt; // Ensure this is camelCase and required if so

  NoteMetadata({
    required this.id,
    required this.title,
    required this.updatedAt, // Parameter is camelCase
  });

  // If you have a fromJsonOnline for your server, it might look like:
  factory NoteMetadata.fromJsonOnline(Map<String, dynamic> json) {
    return NoteMetadata(
      id: json['id'] as String,
      title: json['title'] as String,
      updatedAt: DateTime.parse(json['updated_at'] as String), // map key 'updated_at', constructor param 'updatedAt'
    );
  }
}