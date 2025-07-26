class OnlineNoteMetadata {
  final String id;
  final String title;
  final DateTime updatedAt;

  OnlineNoteMetadata({
    required this.id,
    required this.title,
    required this.updatedAt,
  });

  factory OnlineNoteMetadata.fromJson(Map<String, dynamic> json) {
    final String id = json['id'] as String? ?? '';
    final String title = json['title'] as String? ?? 'Untitled Note';

    DateTime updatedAt;
    if (json['updated_at'] is String) {
      try {
        updatedAt = DateTime.parse(json['updated_at'] as String);
      } catch (e) {
        print("Error parsing 'updated_at' string: ${json['updated_at']}. Using current time as fallback. Error: $e");
        updatedAt = DateTime.now();
      }
    } else if (json['updated_at'] is int) {
      updatedAt = DateTime.fromMillisecondsSinceEpoch(json['updated_at'] as int);
    } else {
      print("Warning: 'updated_at' field is missing or not a String/int. Using current time as fallback. Value: ${json['updated_at']}");
      updatedAt = DateTime.now();
    }

    return OnlineNoteMetadata(
      id: id,
      title: title,
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'updated_at': updatedAt.toIso8601String(), // Standard ISO 8601 format
    };
  }

  @override
  String toString() {
    return 'OnlineNoteMetadata(id: $id, title: "$title", updatedAt: ${updatedAt.toLocal()})';
  }
}
