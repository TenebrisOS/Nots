class OnlineNoteDetail {
  final String id;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  OnlineNoteDetail({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  });

  factory OnlineNoteDetail.fromJson(Map<String, dynamic> json) {
    final String id = json['id'] as String? ?? '';
    final String title = json['title'] as String? ?? 'Untitled Note';
    final String content = json['content'] as String? ?? '';

    DateTime createdAt;
    DateTime updatedAt;

    DateTime parseDate(dynamic dateValue, String fieldName) {
      if (dateValue is String) {
        try {
          return DateTime.parse(dateValue);
        } catch (e) {
          print("Error parsing '$fieldName' string: $dateValue. Using current time. Error: $e");
          return DateTime.now();
        }
      } else if (dateValue is int) {
        return DateTime.fromMillisecondsSinceEpoch(dateValue);
      }
      print("Warning: '$fieldName' field is missing or not a String/int. Using current time. Value: $dateValue");
      return DateTime.now();
    }

    createdAt = parseDate(json['created_at'], 'created_at');
    updatedAt = parseDate(json['updated_at'], 'updated_at');

    return OnlineNoteDetail(
      id: id,
      title: title,
      content: content,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'OnlineNoteDetail(id: $id, title: "$title", content: "${content.substring(0, (content.length > 50 ? 50 : content.length))}...", createdAt: ${createdAt.toLocal()}, updatedAt: ${updatedAt.toLocal()})';
  }
}
