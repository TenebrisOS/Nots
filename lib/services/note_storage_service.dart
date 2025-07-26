import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:nots/models/note_metadata.dart'; // Ensure this path is correct

import './database_helper.dart'; // Ensure this path is correct
import 'package:uuid/uuid.dart';

class NoteStorageService {
  final DatabaseHelper dbHelper = DatabaseHelper.instance;
  final Uuid _uuid = const Uuid();
  final http.Client _httpClient;

  NoteStorageService({http.Client? client})
      : _httpClient = client ?? http.Client();

  Map<String, String> _buildHeaders({String? token, bool isJsonContent = true}) {
    final headers = <String, String>{
      'Accept': 'application/json', // Common header
    };
    if (isJsonContent) {
      headers['Content-Type'] = 'application/json; charset=UTF-8';
    }
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  HttpException _handleHttpError(http.Response response, String operationName) {
    String errorMessage = "Server error during $operationName";
    String rawBodyPreview = response.body.length > 300
        ? '${response.body.substring(0, 300)}...'
        : response.body;

    if (response.body.isNotEmpty) {
      try {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is Map<String, dynamic>) {
          errorMessage = decoded['error']?.toString() ??
              decoded['message']?.toString() ??
              decoded['detail']?.toString() ?? // Common in Django REST Framework
              'Unknown server error from $operationName.';
        } else if (decoded is String && decoded.isNotEmpty) {
          errorMessage = decoded;
        } else {
          errorMessage = 'Server returned a non-standard error format from $operationName.';
        }
      } catch (e) {
        // If JSON parsing fails, use the raw response (or a preview)
        errorMessage = 'Failed to parse error from server during $operationName. Raw response preview: $rawBodyPreview';
      }
    } else {
      errorMessage = 'Server error with no details from $operationName.';
    }

    // Append status code for clarity
    errorMessage += " (Status: ${response.statusCode})";

    if (kDebugMode) {
      print("_handleHttpError for $operationName: $errorMessage. Full response status: ${response.statusCode}, body:\n${response.body}");
    }
    return HttpException(errorMessage);
  }

  Future<Map<String, dynamic>> _postRequestMap(
      String baseUrl, String path, Map<String, dynamic> body, {String? token}) async {
    final Uri url;
    final String operationName = "POST to $path";
    try { url = Uri.parse('$baseUrl$path'); } catch (e) { throw ArgumentError('Invalid Server URL format for $operationName: $baseUrl$path. Error: $e'); }
    final requestBody = jsonEncode(body);
    if (kDebugMode) { print('$operationName Request to: $url\nHeaders: ${_buildHeaders(token: token)}\nBody: $requestBody');}
    try {
      final response = await _httpClient.post(url, headers: _buildHeaders(token: token), body: requestBody).timeout(const Duration(seconds: 20));
      if (kDebugMode) { print('Response ($operationName, Status ${response.statusCode}): ${response.body.length > 500 ? response.body.substring(0,500)+'...' : response.body}'); }
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.body.isEmpty || response.statusCode == HttpStatus.noContent) return {}; // e.g. HTTP 204
        if (response.statusCode == HttpStatus.created && response.body.isEmpty) return {}; // Common for CREATED

        final decodedBody = jsonDecode(utf8.decode(response.bodyBytes));
        if (decodedBody is Map<String, dynamic>) return decodedBody;
        throw FormatException("Unexpected JSON format from server in $operationName. Expected a JSON object, got ${decodedBody.runtimeType}. Body: ${response.body}");
      } else { throw _handleHttpError(response, operationName); }
    } on SocketException catch (e) { if (kDebugMode) print("SocketException in $operationName: $e"); throw HttpException('Network error: Could not connect to the server. ($operationName)'); }
    on HandshakeException catch (e) { if (kDebugMode) print("HandshakeException in $operationName: $e"); throw HttpException('Network security error: SSL handshake failed. ($operationName)'); }
    on FormatException catch (e) { if (kDebugMode) print("FormatException in $operationName: $e"); throw HttpException('Network error: Invalid response format from server. ($operationName) Error: $e');}
    on TimeoutException { if (kDebugMode) print("TimeoutException in $operationName"); throw HttpException('Network error: The server took too long to respond. ($operationName)'); }
    on http.ClientException catch (e) { if (kDebugMode) print("http.ClientException in $operationName: $e"); throw HttpException('Network error: ${e.message} ($operationName)'); }
    catch (e) { if (kDebugMode) print("Generic HTTP Error in $operationName: $e"); if (e is HttpException) rethrow; throw HttpException('An unexpected network error occurred in $operationName: ${e.toString()}');}
  }

  Future<Map<String, dynamic>> _putRequestMap(
      String baseUrl, String path, Map<String, dynamic> body, {String? token}) async {
    final Uri url;
    final String operationName = "PUT to $path";
    try { url = Uri.parse('$baseUrl$path'); } catch (e) { throw ArgumentError('Invalid Server URL format for $operationName: $baseUrl$path. Error: $e'); }
    final requestBody = jsonEncode(body);
    if (kDebugMode) { print('$operationName Request to: $url\nHeaders: ${_buildHeaders(token: token)}\nBody: $requestBody');}
    try {
      final response = await _httpClient.put(url, headers: _buildHeaders(token: token), body: requestBody).timeout(const Duration(seconds: 20));
      if (kDebugMode) { print('Response ($operationName, Status ${response.statusCode}): ${response.body.length > 500 ? response.body.substring(0,500)+'...' : response.body}'); }
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.body.isEmpty || response.statusCode == HttpStatus.noContent) return {};
        final decodedBody = jsonDecode(utf8.decode(response.bodyBytes));
        if (decodedBody is Map<String, dynamic>) return decodedBody;
        throw FormatException("Unexpected JSON format from server in $operationName. Expected a JSON object, got ${decodedBody.runtimeType}. Body: ${response.body}");
      } else { throw _handleHttpError(response, operationName); }
    } on SocketException catch (e) { if (kDebugMode) print("SocketException in $operationName: $e"); throw HttpException('Network error: Could not connect to the server. ($operationName)'); }
    on HandshakeException catch (e) { if (kDebugMode) print("HandshakeException in $operationName: $e"); throw HttpException('Network security error: SSL handshake failed. ($operationName)'); }
    on FormatException catch (e) { if (kDebugMode) print("FormatException in $operationName: $e"); throw HttpException('Network error: Invalid response format from server. ($operationName) Error: $e');}
    on TimeoutException { if (kDebugMode) print("TimeoutException in $operationName"); throw HttpException('Network error: The server took too long to respond. ($operationName)'); }
    on http.ClientException catch (e) { if (kDebugMode) print("http.ClientException in $operationName: $e"); throw HttpException('Network error: ${e.message} ($operationName)'); }
    catch (e) { if (kDebugMode) print("Generic HTTP Error in $operationName: $e"); if (e is HttpException) rethrow; throw HttpException('An unexpected network error occurred in $operationName: ${e.toString()}');}
  }

  Future<List<dynamic>> _getRequestList(
      String baseUrl, String path, {String? token, Map<String, String>? queryParameters}) async {
    final Uri url;
    final String operationName = "GET List from $path";
    try { url = Uri.parse('$baseUrl$path').replace(queryParameters: queryParameters); } catch (e) { throw ArgumentError('Invalid Server URL format for $operationName: $baseUrl$path. Error: $e'); }
    if (kDebugMode) { print('$operationName Request to: $url\nHeaders: ${_buildHeaders(token: token, isJsonContent: false)}');}
    try {
      final response = await _httpClient.get(url, headers: _buildHeaders(token: token, isJsonContent: false)).timeout(const Duration(seconds: 20));
      if (kDebugMode) { print('Response ($operationName, Status ${response.statusCode}): ${response.body.length > 500 ? response.body.substring(0,500)+'...' : response.body}'); }
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.body.isEmpty) return [];
        final decodedBody = jsonDecode(utf8.decode(response.bodyBytes));
        if (decodedBody is List<dynamic>) return decodedBody;
        throw FormatException("Unexpected JSON format from server in $operationName. Expected a JSON list, got ${decodedBody.runtimeType}. Body: ${response.body}");
      } else { throw _handleHttpError(response, operationName); }
    } on SocketException catch (e) { if (kDebugMode) print("SocketException in $operationName: $e"); throw HttpException('Network error: Could not connect to the server. ($operationName)'); }
    on HandshakeException catch (e) { if (kDebugMode) print("HandshakeException in $operationName: $e"); throw HttpException('Network security error: SSL handshake failed. ($operationName)'); }
    on FormatException catch (e) { if (kDebugMode) print("FormatException in $operationName: $e"); throw HttpException('Network error: Invalid response format from server. Expected JSON list. ($operationName) Error: $e');}
    on TimeoutException { if (kDebugMode) print("TimeoutException in $operationName"); throw HttpException('Network error: The server took too long to respond. ($operationName)'); }
    on http.ClientException catch (e) { if (kDebugMode) print("http.ClientException in $operationName: $e"); throw HttpException('Network error: ${e.message} ($operationName)'); }
    catch (e) { if (kDebugMode) print("Generic HTTP Error in $operationName: $e"); if (e is HttpException) rethrow; throw HttpException('An unexpected network error occurred in $operationName: ${e.toString()}');}
  }

  Future<Map<String, dynamic>?> _getRequestMap(
      String baseUrl, String path, {String? token, Map<String, String>? queryParameters}) async {
    final Uri url;
    final String operationName = "GET Map from $path";
    try { url = Uri.parse('$baseUrl$path').replace(queryParameters: queryParameters); } catch (e) { throw ArgumentError('Invalid Server URL format for $operationName: $baseUrl$path. Error: $e'); }
    if (kDebugMode) { print('$operationName Request to: $url\nHeaders: ${_buildHeaders(token: token, isJsonContent: false)}');}
    try {
      final response = await _httpClient.get(url, headers: _buildHeaders(token: token, isJsonContent: false)).timeout(const Duration(seconds: 20));
      if (kDebugMode) { print('Response ($operationName, Status ${response.statusCode}): ${response.body.length > 500 ? response.body.substring(0,500)+'...' : response.body}'); }
      if (response.statusCode == HttpStatus.notFound) return null;
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.body.isEmpty) return null; // Or {} if that's more appropriate for your API
        final decodedBody = jsonDecode(utf8.decode(response.bodyBytes));
        if (decodedBody is Map<String, dynamic>) return decodedBody;
        throw FormatException("Unexpected JSON format from server in $operationName. Expected a JSON object, got ${decodedBody.runtimeType}. Body: ${response.body}");
      } else { throw _handleHttpError(response, operationName); }
    } on SocketException catch (e) { if (kDebugMode) print("SocketException in $operationName: $e"); throw HttpException('Network error: Could not connect to the server. ($operationName)'); }
    on HandshakeException catch (e) { if (kDebugMode) print("HandshakeException in $operationName: $e"); throw HttpException('Network security error: SSL handshake failed. ($operationName)'); }
    on FormatException catch (e) { if (kDebugMode) print("FormatException in $operationName: $e"); throw HttpException('Network error: Invalid response format from server. Expected JSON object. ($operationName) Error: $e');}
    on TimeoutException { if (kDebugMode) print("TimeoutException in $operationName"); throw HttpException('Network error: The server took too long to respond. ($operationName)'); }
    on http.ClientException catch (e) { if (kDebugMode) print("http.ClientException in $operationName: $e"); throw HttpException('Network error: ${e.message} ($operationName)'); }
    catch (e) { if (kDebugMode) print("Generic HTTP Error in $operationName: $e"); if (e is HttpException) rethrow; throw HttpException('An unexpected network error occurred in $operationName: ${e.toString()}');}
  }

  Future<void> _deleteRequest(String baseUrl, String path, {String? token}) async {
    final Uri url;
    final String operationName = "DELETE to $path";
    try { url = Uri.parse('$baseUrl$path'); } catch (e) { throw ArgumentError('Invalid Server URL format for $operationName: $baseUrl$path. Error: $e'); }
    if (kDebugMode) { print('$operationName Request to: $url\nHeaders: ${_buildHeaders(token: token, isJsonContent: false)}');}
    try {
      final response = await _httpClient.delete(url, headers: _buildHeaders(token: token, isJsonContent: false)).timeout(const Duration(seconds: 20));
      if (kDebugMode) { print('Response ($operationName, Status ${response.statusCode}): ${response.body.length > 500 ? response.body.substring(0,500)+'...' : response.body}'); }
      if (response.statusCode >= 200 && response.statusCode < 300 || response.statusCode == HttpStatus.noContent) {
        return; // Success
      } else {
        throw _handleHttpError(response, operationName);
      }
    } on SocketException catch (e) { if (kDebugMode) print("SocketException in $operationName: $e"); throw HttpException('Network error: Could not connect to the server. ($operationName)'); }
    on HandshakeException catch (e) { if (kDebugMode) print("HandshakeException in $operationName: $e"); throw HttpException('Network security error: SSL handshake failed. ($operationName)'); }
    on TimeoutException { if (kDebugMode) print("TimeoutException in $operationName"); throw HttpException('Network error: The server took too long to respond. ($operationName)'); }
    on http.ClientException catch (e) { if (kDebugMode) print("http.ClientException in $operationName: $e"); throw HttpException('Network error: ${e.message} ($operationName)'); }
    catch (e) { if (kDebugMode) print("Generic HTTP Error in $operationName: $e"); if (e is HttpException) rethrow; throw HttpException('An unexpected network error occurred in $operationName: ${e.toString()}');}
  }

// --- Public API ---

  Future<bool> checkOnlineStatus(String serverUrl, String token) async {
    if (serverUrl.trim().isEmpty) {
      if (kDebugMode) print("Status Check: Server URL is empty.");
      return false;
    }
    // TODO: Make this path configurable or a constant if it's always the same.
    final String statusPath = "/api/v1/status"; // Example: common pattern for a status endpoint
    final Uri url;
    try {
      url = Uri.parse('$serverUrl$statusPath');
    } catch (e) {
      if (kDebugMode) print("Invalid URL for status check: $serverUrl$statusPath. Error: $e");
      return false;
    }

    if (kDebugMode) {
      print('GET Request to: $url (Status Check)\nHeaders: ${_buildHeaders(token: token, isJsonContent: false)}');
    }
    try {
      final response = await _httpClient
          .get(url, headers: _buildHeaders(token: token, isJsonContent: false))
          .timeout(const Duration(seconds: 10)); // Shorter timeout for status check
      if (kDebugMode) {
        print('Status Check Response Status: ${response.statusCode}\nStatus Check Response Body: ${response.body.length > 100 ? response.body.substring(0, 100) + '...' : response.body}');
      }
      // Consider what status codes are "OK". Some APIs might return 204 No Content for a status check.
      return response.statusCode == HttpStatus.ok || response.statusCode == HttpStatus.noContent;
    } on SocketException {
      if (kDebugMode) print("Status Check: SocketException (Server unreachable or no network)");
      return false;
    } on HandshakeException {
      if (kDebugMode) print("Status Check: HandshakeException (SSL issue)");
      return false;
    } on TimeoutException {
      if (kDebugMode) print("Status Check: TimeoutException (Server didn't respond in time)");
      return false;
    } on http.ClientException catch (e) {
      if (kDebugMode) print("Status Check: ClientException - ${e.message}");
      return false;
    } catch (e) {
      if (kDebugMode) print("Status Check: Generic error - $e");
      return false;
    }
  }

  // --- Local Database Operations ---
  Future<List<NoteMetadata>> getAllLocalNoteMetadata() async {
    if (kDebugMode) print("NoteStorageService: getAllLocalNoteMetadata called.");
    final List<Map<String, dynamic>> maps = await dbHelper.queryAllNoteMetadata();
    if (maps.isEmpty) {
      if (kDebugMode) print("NoteStorageService: No local note metadata found.");
      return [];
    }
    try {
      final metadataList = maps.map((map) => NoteMetadata.fromDbMap(map)).toList();
      if (kDebugMode) print("NoteStorageService: Successfully mapped ${metadataList.length} local notes metadata.");
      return metadataList;
    } catch (e, stacktrace) {
      if (kDebugMode) print("Error mapping local notes metadata: $e. Data: $maps\nStacktrace: $stacktrace");
      return [];
    }
  }

  Future<Map<String, dynamic>?> getLocalFullNote(String noteIdS) async {
    if (kDebugMode) print("NoteStorageService: getLocalFullNote called for id_s: $noteIdS.");
    final noteData = await dbHelper.queryFullNote(noteIdS);
    if (noteData == null) {
      if (kDebugMode) print("NoteStorageService: No local full note found for id_s: $noteIdS.");
      return null;
    }
    if (kDebugMode) print("NoteStorageService: Successfully fetched local full note for id_s: $noteIdS. Data: $noteData");
    return noteData;
  }

  Future<NoteMetadata> createLocalNote({required String title, required String content}) async {
    final String idS = _uuid.v4();
    final String now = DateTime.now().toUtc().toIso8601String();
    final String titleToStore = title.trim().isEmpty ? "Untitled Note" : title.trim();

    final Map<String, dynamic> row = {
      DatabaseHelper.columnIdS: idS,
      DatabaseHelper.columnTitle: titleToStore,
      DatabaseHelper.columnContent: content.trim(),
      DatabaseHelper.columnCreatedAt: now,
      DatabaseHelper.columnUpdatedAt: now,
    };
    if (kDebugMode) print("NoteStorageService: Creating local note with id_s: $idS, title: $titleToStore");
    await dbHelper.insert(row);
    final newMeta = NoteMetadata(id: idS, title: titleToStore, updatedAt: DateTime.parse(now).toUtc(), isLocal: true);
    if (kDebugMode) print("NoteStorageService: Local note created. Metadata: ID=${newMeta.id}, Title=${newMeta.title}");
    return newMeta;
  }

  Future<NoteMetadata?> updateLocalNote({required String noteIdS, String? title, String? content}) async {
    if (title == null && content == null) {
      if (kDebugMode) print("UpdateLocalNote: No changes provided for local note $noteIdS.");
      final currentNoteData = await dbHelper.queryFullNote(noteIdS);
      if (currentNoteData != null) {
        return NoteMetadata.fromDbMap(currentNoteData);
      }
      return null;
    }

    final String now = DateTime.now().toUtc().toIso8601String();
    final Map<String, dynamic> rowToUpdate = {
      DatabaseHelper.columnIdS: noteIdS, // Crucial for WHERE clause
      DatabaseHelper.columnUpdatedAt: now,
    };

    String finalTitleForMeta = "";

    if (title != null) {
      finalTitleForMeta = title.trim().isEmpty ? "Untitled Note" : title.trim();
      rowToUpdate[DatabaseHelper.columnTitle] = finalTitleForMeta;
    } else {
      // Fetch current title if not updating it, to return correct metadata
      final currentNote = await dbHelper.queryFullNote(noteIdS);
      finalTitleForMeta = currentNote?[DatabaseHelper.columnTitle]?.toString() ?? "Untitled Note";
    }

    if (content != null) {
      rowToUpdate[DatabaseHelper.columnContent] = content.trim();
    }

    if (kDebugMode) print("NoteStorageService: Updating local note id_s: $noteIdS with data: $rowToUpdate");
    final rowsAffected = await dbHelper.update(rowToUpdate);

    if (rowsAffected > 0) {
      final updatedMeta = NoteMetadata(id: noteIdS, title: finalTitleForMeta, updatedAt: DateTime.parse(now).toUtc(), isLocal: true);
      if (kDebugMode) print("NoteStorageService: Local note $noteIdS updated. Metadata: ID=${updatedMeta.id}, Title=${updatedMeta.title}");
      return updatedMeta;
    } else {
      if (kDebugMode) print("NoteStorageService: Local note $noteIdS update failed (rowsAffected: $rowsAffected). Note might not exist.");
      return null;
    }
  }

  Future<void> deleteLocalNote(String noteIdS) async {
    if (kDebugMode) print("NoteStorageService: Deleting local note id_s: $noteIdS");
    await dbHelper.delete(noteIdS);
    if (kDebugMode) print("NoteStorageService: Local note $noteIdS deleted from database.");
  }

  // --- Online (Server) Operations ---
  // TODO: Define your API base URL and paths more globally.
  // For now, they are passed as arguments. Consider a config class or constants.
  static const String _baseApiNotePath = '/api/v1/notes/'; // Example

  Future<List<NoteMetadata>> getAllOnlineNotes(String serverUrl, String token) async {
    if (serverUrl.trim().isEmpty) throw ArgumentError("Server URL cannot be empty.");
    if (token.trim().isEmpty) throw ArgumentError("Access token cannot be empty for this operation.");

    final String path = _baseApiNotePath;

    try {
      final List<dynamic> data = await _getRequestList(serverUrl, path, token: token);
      if (kDebugMode) print("getAllOnlineNotes received ${data.length} items from server.");
      return data.map((item) {
        if (item is Map<String, dynamic>) {
          try {
            return NoteMetadata.fromJsonOnline(item);
          } catch (e) {
            if (kDebugMode) print("getAllOnlineNotes: Error parsing item: $item. Error: $e");
            // Return a placeholder or skip
            return NoteMetadata(id: 'parse_error_${_uuid.v4()}', title: 'Invalid Data Received', updatedAt: DateTime.now().toUtc(), isLocal: false);
          }
        } else {
          if (kDebugMode) print("getAllOnlineNotes: Skipping non-map item: $item");
          return NoteMetadata(id: 'invalid_item_type_${_uuid.v4()}', title: 'Invalid Item Type', updatedAt: DateTime.now().toUtc(), isLocal: false);
        }
      }).where((note) => !note.id.startsWith('parse_error_') && !note.id.startsWith('invalid_item_type_') ).toList();
    } catch (e) {
      if (kDebugMode) print("Error fetching all online notes: $e");
      if (e is HttpException) rethrow;
      throw HttpException("Failed to fetch online notes. ${e.toString()}");
    }
  }

  Future<Map<String, dynamic>?> getOnlineFullNote(String noteId, String serverUrl, String token) async {
    if (serverUrl.trim().isEmpty) throw ArgumentError("Server URL cannot be empty.");
    if (token.trim().isEmpty) throw ArgumentError("Access token cannot be empty for this operation.");
    if (noteId.trim().isEmpty) throw ArgumentError("Note ID cannot be empty.");

    final String path = '$_baseApiNotePath$noteId/'; // Ensure trailing slash if your API requires it

    try {
      if (kDebugMode) print("getOnlineFullNote: Fetching note $noteId from $serverUrl$path");
      final responseMap = await _getRequestMap(serverUrl, path, token: token);
      if (kDebugMode && responseMap != null) print("getOnlineFullNote: Successfully fetched note $noteId. Data: $responseMap");
      else if (kDebugMode && responseMap == null) print("getOnlineFullNote: Note $noteId not found or empty response from server.");
      return responseMap;
    } catch (e) {
      if (kDebugMode) print("Error fetching online note $noteId: $e");
      if (e is HttpException) rethrow;
      throw HttpException("Failed to fetch online note $noteId. ${e.toString()}");
    }
  }

  Future<NoteMetadata> createOnlineNote({
    required String title,
    required String content,
    required String serverUrl,
    required String token,
  }) async {
    if (serverUrl.trim().isEmpty) throw ArgumentError("Server URL cannot be empty.");
    if (token.trim().isEmpty) throw ArgumentError("Access token cannot be empty for this operation.");

    final String titleToSend = title.trim().isEmpty ? "Untitled Note" : title.trim();
    final Map<String, dynamic> body = {
      'title': titleToSend,
      'content': content.trim(),
      // Server should set timestamps (created_at, updated_at)
    };

    final String path = _baseApiNotePath+"create";

    try {
      if (kDebugMode) print("createOnlineNote: Creating note with title '$titleToSend' at $serverUrl$path");
      final Map<String, dynamic> data = await _postRequestMap(
        serverUrl,
        path,
        body,
        token: token,
      );
      if (kDebugMode) print("createOnlineNote: Successfully created note. Response data: $data");
      return NoteMetadata.fromJsonOnline(data);
    } catch (e) {
      if (kDebugMode) {
        print("Error creating online note: $e");
        print("Problematic data sent for createOnlineNote: $body");
      }
      if (e is HttpException) rethrow;
      throw HttpException("Failed to create online note. ${e.toString()}");
    }
  }

  Future<NoteMetadata?> updateOnlineNote({
    required String noteId,
    String? title,
    String? content,
    required String serverUrl,
    required String token,
  }) async {
    if (serverUrl.trim().isEmpty) throw ArgumentError("Server URL cannot be empty.");
    if (token.trim().isEmpty) throw ArgumentError("Access token cannot be empty for this operation.");
    if (noteId.trim().isEmpty) throw ArgumentError("Note ID cannot be empty.");

    if (title == null && content == null) {
      if (kDebugMode) print("UpdateOnlineNote: No changes provided for note $noteId.");
      final currentOnlineData = await getOnlineFullNote(noteId, serverUrl, token);
      if (currentOnlineData != null) {
        return NoteMetadata.fromJsonOnline(currentOnlineData);
      }
      return null;
    }

    final Map<String, dynamic> body = {};
    if (title != null) {
      body['title'] = title.trim().isEmpty ? "Untitled Note" : title.trim();
    }
    if (content != null) {
      body['content'] = content.trim();
    }
    // Server should handle 'updated_at'

    final String path = '$_baseApiNotePath$noteId/';

    try {
      if (kDebugMode) print("updateOnlineNote: Updating note $noteId with data: $body at $serverUrl$path");
      final Map<String, dynamic> data = await _putRequestMap(
        serverUrl,
        path,
        body,
        token: token,
      );
      if (kDebugMode) print("updateOnlineNote: Successfully updated note $noteId. Response data: $data");
      return NoteMetadata.fromJsonOnline(data);
    } catch (e) {
      if (kDebugMode) {
        print("Error updating online note $noteId: $e");
        print("Problematic data sent for updateOnlineNote: $body");
      }
      if (e is HttpException) rethrow;
      throw HttpException("Failed to update online note $noteId. ${e.toString()}");
    }
  }

  Future<void> deleteOnlineNote(
      String noteId, String serverUrl, String token) async {
    if (serverUrl.trim().isEmpty) throw ArgumentError("Server URL cannot be empty.");
    if (token.trim().isEmpty) throw ArgumentError("Access token cannot be empty for this operation.");
    if (noteId.trim().isEmpty) throw ArgumentError("Note ID cannot be empty.");

    final String path = '$_baseApiNotePath$noteId/';

    try {
      if (kDebugMode) print("deleteOnlineNote: Deleting note $noteId from $serverUrl$path");
      await _deleteRequest(
        serverUrl,
        path,
        token: token,
      );
      if (kDebugMode) print("Successfully sent delete request for online note $noteId.");
    } catch (e) {
      if (kDebugMode) print("Error deleting online note $noteId: $e");
      if (e is HttpException) rethrow;
      throw HttpException("Failed to delete online note $noteId. ${e.toString()}");
    }
  }
}
