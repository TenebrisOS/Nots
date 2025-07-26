import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService with ChangeNotifier {
  static const String _serverUrlKey = 'server_url';
  static const String _accessTokenKey = 'access_token';
  static const String _currentUsernameKey = 'current_username';

  String _serverUrl = '';
  String _accessToken = '';
  String _currentUsername = '';

  String get serverUrl => _serverUrl;
  String get accessToken => _accessToken;
  String get currentUsername => _currentUsername;

  bool _isLoaded = false;
  bool get isLoaded => _isLoaded;

  SettingsService() {
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _serverUrl = prefs.getString(_serverUrlKey) ?? '';
    _accessToken = prefs.getString(_accessTokenKey) ?? '';
    _currentUsername = prefs.getString(_currentUsernameKey) ?? '';

    _isLoaded = true;

    if (kDebugMode) {
      print("Settings loaded: URL='$_serverUrl', Token='${_accessToken.isNotEmpty ? "SET" : "NOT SET"}', Username='$_currentUsername'");
    }
    notifyListeners();
  }

  Future<void> saveServerUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    _serverUrl = url.trim();
    await prefs.setString(_serverUrlKey, _serverUrl);
    if (kDebugMode) print("Server URL saved: $_serverUrl");
    notifyListeners();
  }

  Future<void> saveAccessToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = token.trim(); // Trim the token just in case
    await prefs.setString(_accessTokenKey, _accessToken);
    if (kDebugMode) print("Access Token saved.");
    notifyListeners();
  }

  Future<void> saveUsername(String username) async { // Method to save username
    final prefs = await SharedPreferences.getInstance();
    _currentUsername = username.trim();
    await prefs.setString(_currentUsernameKey, _currentUsername);
    if (kDebugMode) print("Username saved: $_currentUsername");
    notifyListeners();
  }

  Future<void> clearOnlineSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _serverUrl = '';
    _accessToken = '';
    _currentUsername = ''; // Clear username as well
    await prefs.remove(_serverUrlKey);
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_currentUsernameKey); // Remove username from prefs
    if (kDebugMode) print("Online settings (URL, Token, Username) cleared.");
    notifyListeners();
  }

  Future<void> clearAccessTokenAndUsername() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = '';
    _currentUsername = '';
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_currentUsernameKey);
    if (kDebugMode) print("Access Token and Username cleared (logged out).");
    notifyListeners();
  }

  bool get isUserLoggedIn => _accessToken.isNotEmpty && _currentUsername.isNotEmpty;
}
