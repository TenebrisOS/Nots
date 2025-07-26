import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:nots/services/database_helper.dart';

class NoteMetadata {
  final String id;
  final String title;
  final DateTime updatedAt;
  final bool isLocal;

  NoteMetadata({
    required this.id,
    required this.title,
    required this.updatedAt,
    this.isLocal = true,
  });

  factory NoteMetadata.fromJsonOnline(Map<String, dynamic> json) {
    if (kDebugMode) {
      print("NoteMetadata.fromJsonOnline received JSON: $json");
    }
    try {
      String id = json['id']?.toString() ?? json['_id']?.toString() ?? const Uuid().v4();
      String title = json['title']?.toString()?.trim() ?? 'Untitled Online Note';
      if (title.isEmpty) title = 'Untitled Online Note';
      DateTime updatedAt;

      var updateTimestamp = json['updated_at'] ?? json['updatedAt'] ?? json['date_modified'] ?? json['last_modified'];

      if (updateTimestamp != null) {
        if (updateTimestamp is int) { // Unix timestamp (seconds or milliseconds)
          if (updateTimestamp.toString().length == 10) { // Likely seconds
            updatedAt = DateTime.fromMillisecondsSinceEpoch(updateTimestamp * 1000, isUtc: true);
          } else { // Likely milliseconds
            updatedAt = DateTime.fromMillisecondsSinceEpoch(updateTimestamp, isUtc: true);
          }
        } else if (updateTimestamp is String) {
          updatedAt = DateTime.tryParse(updateTimestamp)?.toUtc() ?? DateTime.now().toUtc();
        } else if (updateTimestamp is double) { // Some systems might send it as double (e.g. Firestore serverTimestamp)
          updatedAt = DateTime.fromMillisecondsSinceEpoch(updateTimestamp.toInt(), isUtc: true);
        }
        else {
          if (kDebugMode) print("NoteMetadata.fromJsonOnline: Unexpected timestamp type for 'updated_at': ${updateTimestamp.runtimeType}, value: $updateTimestamp");
          updatedAt = DateTime.now().toUtc();
        }
      } else {
        if (kDebugMode) print("NoteMetadata.fromJsonOnline: 'updated_at' (or variant) is missing in JSON. Using current time.");
        updatedAt = DateTime.now().toUtc();
      }

      return NoteMetadata(
        id: id,
        title: title,
        updatedAt: updatedAt, // Already UTC
        isLocal: false,
      );
    } catch (e, stacktrace) {
      if (kDebugMode) {
        print("Error parsing NoteMetadata from Online JSON: $e. \nProblematic JSON: $json\nStacktrace: $stacktrace");
      }
      return NoteMetadata(
        id: const Uuid().v4(),
        title: "Error Parsing Note",
        updatedAt: DateTime.now().toUtc(),
        isLocal: false,
      );
    }
  }

  factory NoteMetadata.fromDbMap(Map<String, dynamic> map) {
    if (kDebugMode) {
      print("NoteMetadata.fromDbMap received map: $map");
    }
    try {
      String id = map[DatabaseHelper.columnIdS]?.toString() ?? const Uuid().v4(); // Corrected Uuid
      String title = map[DatabaseHelper.columnTitle]?.toString()?.trim() ?? 'Untitled Note';
      if (title.isEmpty) title = 'Untitled Note';

      String? updatedAtString = map[DatabaseHelper.columnUpdatedAt]?.toString();

      DateTime updatedAt;
      if (updatedAtString != null && updatedAtString.isNotEmpty) {
        updatedAt = DateTime.tryParse(updatedAtString)?.toUtc() ?? DateTime.now().toUtc();
      } else {
        if (kDebugMode) print("NoteMetadata.fromDbMap: '${DatabaseHelper.columnUpdatedAt}' is missing or empty in map. Using current time.");
        updatedAt = DateTime.now().toUtc();
      }

      return NoteMetadata(
        id: id,
        title: title,
        updatedAt: updatedAt, // Already UTC
        isLocal: true,
      );
    } catch (e, stacktrace) {
      if (kDebugMode) {
        print("Error parsing NoteMetadata from DB map: $e. \nProblematic map: $map\nStacktrace: $stacktrace");
      }
      return NoteMetadata( // Fallback
        id: const Uuid().v4(),
        title: "Error Parsing DB Note",
        updatedAt: DateTime.now().toUtc(),
        isLocal: true,
      );
    }
  }

  Map<String, dynamic> toDbMap({String? newContent}) {
    final now = DateTime.now().toUtc().toIso8601String();
    return {
      DatabaseHelper.columnIdS: id,
      DatabaseHelper.columnTitle: title.trim().isEmpty ? "Untitled Note" : title.trim(),
      DatabaseHelper.columnUpdatedAt: updatedAt.toIso8601String(), // Use existing, or 'now' if updating
    };
  }
}
