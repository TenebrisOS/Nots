class NoteMetadata {
  final String id;
  final String title;
  final DateTime updatedAt;

  NoteMetadata({
    required this.id,
    required this.title,
    required this.updatedAt,
  });

  // Factory constructor for creating NoteMetadata from JSON (e.g., from an online server)
  factory NoteMetadata.fromJsonOnline(Map<String, dynamic> json) {
    if (json['id'] == null || json['title'] == null || json['updated_at'] == null) {
      // It's good practice to check for nulls before casting,
      // especially with data coming from an external source.
      throw FormatException("Missing required fields in JSON for NoteMetadata: id, title, or updated_at. Received: $json");
    }
    try {
      return NoteMetadata(
        id: json['id'] as String,
        title: json['title'] as String,
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );
    } catch (e) {
      throw FormatException("Error parsing NoteMetadata from JSON: $e. Received: $json");
    }
  }
}
