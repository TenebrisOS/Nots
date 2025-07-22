class NoteMetadata {
  String id; //.txt
  String title;
  DateTime createdAt;
  DateTime updatedAt;

  NoteMetadata({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NoteMetadata.fromJson(Map<String, dynamic> json) {
    return NoteMetadata(
      id: json['id'] as String,
      title: json['title'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}