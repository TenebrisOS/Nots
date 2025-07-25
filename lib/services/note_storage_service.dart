import 'dart:convert';
import 'dart:io'; // For HttpException, SocketException, HandshakeException
import 'dart:async'; // For TimeoutException
import 'package:flutter/foundation.dart'; // For kDebugMode
import 'package:http/http.dart' as http;
import 'package:nots/models/note_metadata.dart'; // Ensure this path is correct
import './database_helper.dart'; // For local notes
import 'package:uuid/uuid.dart';

class NoteStorageService {
  final DatabaseHelper dbHelper = DatabaseHelper.instance;
  final Uuid _uuid = const Uuid();
  final http.Client _httpClient;

  // Constructor can accept an http.Client for testing
  NoteStorageService({http.Client? client}) : _httpClient = client ?? http.Client();

  // --- Helper for HTTP POST requests returning a Map (single object) ---
  Future<Map<String, dynamic>> _postRequest(String baseUrl, String path, Map<String, dynamic> body) async {
    final Uri url;
    try {
      url = Uri.parse('$baseUrl$path');
    } catch (e) {
      throw ArgumentError('Invalid Server URL format: $baseUrl$path');
    }

    if (kDebugMode) {
      print('POST Request to: $url');
      print('Body: ${jsonEncode(body)}');
    }

    try {
      final response = await _httpClient.post(
        url,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 15));

      if (kDebugMode) {
        print('Response Status: ${response.statusCode}');
        print('Response Body: ${response.body}');
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.body.isEmpty && response.statusCode == HttpStatus.noContent) {
          return {};
        }
        if (response.body.isEmpty) {
          return {};
        }
        return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      } else {
        String errorMessage = "Server error";
        if (response.body.isNotEmpty) {
          try {
            final errorBody = jsonDecode(utf8.decode(response.bodyBytes));
            errorMessage = errorBody['error']?.toString() ?? 'Unknown server error (Status: ${response.statusCode})';
          } catch (_) {
            errorMessage = 'Failed to parse error from server (Status: ${response.statusCode}). Raw: ${response.body}';
          }
        } else {
          errorMessage = 'Server error (Status: ${response.statusCode}) - No details from server.';
        }
        throw HttpException(errorMessage);
      }
    } on SocketException catch (e) {
      if (kDebugMode) print("SocketException: $e");
      throw const HttpException('Network error: Could not connect to the server. Please check your network and the server address.');
    } on HandshakeException catch (e) {
      if (kDebugMode) print("HandshakeException: $e");
      throw const HttpException('Network security error: SSL handshake failed. The server might be using an invalid or self-signed certificate.');
    } on FormatException catch (e) {
      if (kDebugMode) print("FormatException during JSON decode: $e");
      throw const HttpException('Network error: Invalid response format from server.');
    } on http.ClientException catch (e) {
      if (kDebugMode) print("http.ClientException: $e");
      throw HttpException('Network error: ${e.message}');
    } catch (e) {
      if (kDebugMode) print("Generic HTTP Error in _postRequest: $e");
      throw HttpException('An unexpected network error occurred: ${e.toString()}');
    }
  }

  // --- Helper for HTTP POST requests returning a List ---
  Future<List<dynamic>> _postRequestList(String baseUrl, String path, Map<String, dynamic> body) async {
    final Uri url;
    try {
      url = Uri.parse('$baseUrl$path');
    } catch (e) {
      throw ArgumentError('Invalid Server URL format: $baseUrl$path');
    }
    if (kDebugMode) {
      print('POST Request (List) to: $url');
      print('Body: ${jsonEncode(body)}');
    }

    try {
      final response = await _httpClient.post(
        url,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 15));

      if (kDebugMode) {
        print('Response Status: ${response.statusCode}');
        print('Response Body: ${response.body}');
      }

      if (response.statusCode == 200) {
        if (response.body.isEmpty) return [];
        return jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
      } else {
        String errorMessage = "Server error";
        if (response.body.isNotEmpty) {
          try {
            final errorBody = jsonDecode(utf8.decode(response.bodyBytes));
            errorMessage = errorBody['error']?.toString() ?? 'Unknown server error (Status: ${response.statusCode})';
          } catch (_) {
            errorMessage = 'Failed to parse error from server (Status: ${response.statusCode}). Raw: ${response.body}';
          }
        } else {
          errorMessage = 'Server error (Status: ${response.statusCode}) - No details from server.';
        }
        throw HttpException(errorMessage);
      }
    } on SocketException catch (e) {
      if (kDebugMode) print("SocketException: $e");
      throw const HttpException('Network error: Could not connect to the server. Please check your network and the server address.');
    } on HandshakeException catch (e) {
      if (kDebugMode) print("HandshakeException: $e");
      throw const HttpException('Network security error: SSL handshake failed. The server might be using an invalid or self-signed certificate.');
    } on FormatException catch (e) {
      if (kDebugMode) print("FormatException during JSON decode: $e");
      throw const HttpException('Network error: Invalid response format from server.');
    } on http.ClientException catch (e) {
      if (kDebugMode) print("http.ClientException: $e");
      throw HttpException('Network error: ${e.message}');
    } catch (e) {
      if (kDebugMode) print("Generic HTTP Error in _postRequestList: $e");
      throw HttpException('An unexpected network error occurred: ${e.toString()}');
    }
  }

  // --- New method to check online status ---
  Future<bool> checkOnlineStatus(String serverUrl, String token) async {
    if (serverUrl.trim().isEmpty) {
      return false;
    }
    // Token might not be strictly needed for /status, but we pass it if available.
    // Adjust if your /status endpoint doesn't need/use a token or uses header auth.

    final Uri url;
    try {
      // Assuming your status endpoint is at the root of the serverUrl + /status
      // e.g. if serverUrl = "https://api.example.com/v1", then url = "https://api.example.com/v1/status"
      url = Uri.parse('$serverUrl/status');
    } catch (e) {
      if (kDebugMode) print("Invalid URL for status check: $serverUrl/status. Error: $e");
      return false; // Invalid URL format
    }

    if (kDebugMode) {
      print('GET Request to: $url (Status Check)');
    }

    try {
      // This is a GET request. If your server expects POST for /status with a token in the body:
      // await _postRequest(serverUrl, '/status', {'token': token});
      // return true; // (Assuming _postRequest throws on non-2xx)

      // For GET request:
      final response = await _httpClient.get(
        url,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          // If your /status endpoint expects the token as a Bearer token in the header:
          if (token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10)); // Shorter timeout for status check

      if (kDebugMode) {
        print('Status Check Response Status: ${response.statusCode}');
        print('Status Check Response Body (first 100 chars): ${response.body.substring(0, response.body.length > 100 ? 100 : response.body.length)}');
      }

      return response.statusCode == 200;
    } on SocketException {
      if (kDebugMode) print("Status Check: SocketException - Server unreachable or wrong address.");
      return false;
    } on HandshakeException {
      if (kDebugMode) print("Status Check: HandshakeException - SSL issue.");
      return false;
    } on http.ClientException catch (e) {
      if (kDebugMode) print("Status Check: ClientException - ${e.message}");
      return false;
    } on TimeoutException {
      if (kDebugMode) print("Status Check: TimeoutException - Server did not respond in time.");
      return false;
    } catch (e) { // Catch-all for other unexpected errors during the status check
      if (kDebugMode) print("Status Check: Generic error - $e");
      return false;
    }
  }

  // --- Local Notes Specific Methods (Using SQLite) ---
  Future<List<NoteMetadata>> getAllLocalNoteMetadata() async {
    final List<NoteDbModel> dbNotes = await dbHelper.queryAllNotesMetadata();
    return dbNotes.map((dbNote) => NoteMetadata(
      id: dbNote.id,
      title: dbNote.title,
      updatedAt: DateTime.parse(dbNote.updatedAt),
    )).toList();
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

  Future<NoteMetadata> createLocalNote({required String title, required String content}) async {
    final noteId = _uuid.v4();
    final now = DateTime.now();
    final newDbNote = NoteDbModel(
      id: noteId,
      title: title.isEmpty ? "Untitled Note" : title,
      content: content,
      updatedAt: now.toIso8601String(),
    );
    await dbHelper.insertNote(newDbNote);
    if (kDebugMode) print("Local DB Note Created: ${newDbNote.title} (ID: ${newDbNote.id})");
    return NoteMetadata(id: noteId, title: newDbNote.title, updatedAt: now);
  }

  Future<void> deleteLocalNote(String noteId) async {
    await dbHelper.deleteNote(noteId);
    if (kDebugMode) print("Local DB Note Deleted: $noteId");
  }

  // --- Online Notes Methods ---
  Future<List<NoteMetadata>> getAllOnlineNoteMetadata(String serverUrl, String token) async {
    if (serverUrl.trim().isEmpty) throw ArgumentError("Server URL cannot be empty.");
    if (token.trim().isEmpty) throw ArgumentError("Access token cannot be empty.");

    final List<dynamic> data = await _postRequestList(serverUrl, '/notes', {'token': token});
    return data
        .map((item) => NoteMetadata.fromJsonOnline(item as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, String>?> getOnlineFullNote(String noteId, String serverUrl, String token) async {
    if (serverUrl.trim().isEmpty) throw ArgumentError("Server URL cannot be empty.");
    if (token.trim().isEmpty) throw ArgumentError("Access token cannot be empty.");
    if (noteId.trim().isEmpty) throw ArgumentError("Note ID cannot be empty.");

    final Map<String, dynamic> data = await _postRequest(serverUrl, '/note/detail', {'token': token, 'note_id': noteId});
    if (data.isEmpty) return null;

    return {
      'id': data['id'] as String,
      'title': data['title'] as String,
      'content': data['content'] as String,
      'updated_at': data['updated_at'] as String,
    };
  }

  Future<NoteMetadata> createOnlineNote({
    required String title,
    required String content,
    required String serverUrl,
    required String token,
  }) async {
    if (serverUrl.trim().isEmpty) throw ArgumentError("Server URL cannot be empty.");
    if (token.trim().isEmpty) throw ArgumentError("Access token cannot be empty.");

    final Map<String, dynamic> data = await _postRequest(serverUrl, '/notes/create', {
      'token': token,
      'title': title.isEmpty ? "Untitled Note" : title,
      'content': content,
    });
    return NoteMetadata.fromJsonOnline(data);
  }

  Future<void> deleteOnlineNote(String noteId, String serverUrl, String token) async {
    if (serverUrl.trim().isEmpty) throw ArgumentError("Server URL cannot be empty.");
    if (token.trim().isEmpty) throw ArgumentError("Access token cannot be empty.");
    if (noteId.trim().isEmpty) throw ArgumentError("Note ID cannot be empty.");

    await _postRequest(serverUrl, '/notes/delete', {'token': token, 'note_id': noteId});
  }
}
