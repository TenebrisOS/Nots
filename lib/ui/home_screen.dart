import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nots/services/note_storage_service.dart';
import 'package:nots/ui/local_notes_page.dart';
import 'package:nots/ui/online_notes_page.dart';
import 'package:nots/ui/settings_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentPageIndex = 0;
  final NoteStorageService _noteStorage = NoteStorageService();

  final TextEditingController _serverHostController = TextEditingController();
  final TextEditingController _tokenController = TextEditingController();
  bool _serverHostingEnabled = false;
  bool _isOnlineServiceVerified = false;
  bool _isCheckingStatus = false;

  Timer? _statusCheckDebouncer;
  // final _secureStorage = const FlutterSecureStorage();


  @override
  void initState() {
    super.initState();
    _loadSettings();
    _serverHostController.addListener(_onConnectivitySettingsChanged);
    _tokenController.addListener(_onConnectivitySettingsChanged);
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    bool isEnabled = prefs.getBool('serverHostingEnabled') ?? false;
    _serverHostController.text = prefs.getString('serverHost') ?? '';
    // String? token = await _secureStorage.read(key: 'user_token');
    // _tokenController.text = token ?? '';
    _tokenController.text = prefs.getString('user_token_TEMP') ?? ''; // Using temp for now

    if (mounted) {
      setState(() {
        _serverHostingEnabled = isEnabled;
      });
      if (isEnabled && _serverHostController.text.isNotEmpty && _tokenController.text.isNotEmpty) {
        // Don't await here, let it run in the background
        _performStatusCheck();
      }
    }
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('serverHostingEnabled', _serverHostingEnabled);
    if (_serverHostingEnabled) {
      await prefs.setString('serverHost', _serverHostController.text.trim());
      // await _secureStorage.write(key: 'user_token', value: _tokenController.text.trim());
      await prefs.setString('user_token_TEMP', _tokenController.text.trim());
    } else {
      await prefs.remove('serverHost');
      // await _secureStorage.delete(key: 'user_token');
      await prefs.remove('user_token_TEMP');
    }
    if (kDebugMode) {
      print("Settings saved. Enabled: $_serverHostingEnabled, Host: ${_serverHostController.text}, Token: ${_tokenController.text.isNotEmpty}");
    }
  }

  void _onConnectivitySettingsChanged() {
    if (_serverHostingEnabled) {
      if (_statusCheckDebouncer?.isActive ?? false) _statusCheckDebouncer!.cancel();
      _statusCheckDebouncer = Timer(const Duration(milliseconds: 750), () {
        if (mounted && _serverHostController.text.isNotEmpty && _tokenController.text.isNotEmpty) {
          _performStatusCheck();
        } else if (mounted) {
          // If fields become empty while sync is enabled, mark as not verified
          setState(() {
            _isOnlineServiceVerified = false;
          });
        }
      });
    } else {
      // If server hosting is disabled, ensure verification is false
      if (mounted) {
        setState(() {
          _isOnlineServiceVerified = false;
        });
      }
    }
    _saveSettings(); // Save on any change to these text fields
  }

  Future<void> _performStatusCheck() async {
    if (!_serverHostingEnabled || _serverHostController.text.trim().isEmpty || _tokenController.text.trim().isEmpty) {
      if (mounted) {
        setState(() {
          _isOnlineServiceVerified = false;
          _isCheckingStatus = false; // Ensure loading is off if we don't proceed
        });
      }
      return;
    }

    if (_isCheckingStatus) return;

    if (mounted) {
      setState(() {
        _isCheckingStatus = true;
        // _isOnlineServiceVerified = false; // Optionally reset for immediate feedback
      });
    }

    if (kDebugMode) print("Performing status check for: ${_serverHostController.text.trim()}");

    bool success = await _noteStorage.checkOnlineStatus(
      _serverHostController.text.trim(),
      _tokenController.text.trim(),
    );

    if (mounted) {
      setState(() {
        _isOnlineServiceVerified = success;
        _isCheckingStatus = false;
      });
      if (success) {
        if (kDebugMode) print("Status check SUCCESSFUL!");
      } else {
        if (kDebugMode) print("Status check FAILED.");
      }
    }
  }

  void _handleServerHostingChanged(bool enabled) {
    bool previousState = _serverHostingEnabled;
    if (mounted) {
      setState(() {
        _serverHostingEnabled = enabled;
        if (!enabled) {
          _isOnlineServiceVerified = false;
          if (_statusCheckDebouncer?.isActive ?? false) _statusCheckDebouncer!.cancel();
        }
      });
    }
    _saveSettings();

    // Adjust page index if Online tab is removed
    if (!enabled && previousState) { // Was enabled, now disabled
      final currentDestCount = _buildDestinations().length;
      if (_currentPageIndex >= currentDestCount) {
        if (mounted) {
          setState(() {
            _currentPageIndex = currentDestCount -1;
            if (_currentPageIndex < 0) _currentPageIndex = 0;
          });
        }
      }
    }

    if (enabled && !previousState && _serverHostController.text.isNotEmpty && _tokenController.text.isNotEmpty) {
      _performStatusCheck();
    } else if (enabled && ( _serverHostController.text.isEmpty || _tokenController.text.isEmpty)) {
      // If enabled but fields are empty, it's not verified
      if(mounted) setState(() => _isOnlineServiceVerified = false);
    }
  }

  @override
  void dispose() {
    _serverHostController.removeListener(_onConnectivitySettingsChanged);
    _tokenController.removeListener(_onConnectivitySettingsChanged);
    _statusCheckDebouncer?.cancel();
    super.dispose();
  }

  List<NavigationDestination> _buildDestinations() {
    final destinations = [
      const NavigationDestination(
        selectedIcon: Icon(Icons.folder_special_rounded),
        icon: Icon(Icons.folder_special_outlined),
        label: 'Local',
      ),
    ];

    if (_serverHostingEnabled) {
      destinations.add(
        NavigationDestination(
          selectedIcon: Icon(
            _isOnlineServiceVerified ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
            color: _isOnlineServiceVerified ? null : Theme.of(context).colorScheme.error,
          ),
          icon: Icon(
            _isOnlineServiceVerified ? Icons.cloud_outlined : Icons.cloud_queue_outlined,
            color: _isOnlineServiceVerified ? null : Theme.of(context).colorScheme.error,
          ),
          label: 'Online',
        ),
      );
    }

    destinations.add(
      const NavigationDestination(
        selectedIcon: Icon(Icons.settings_applications),
        icon: Icon(Icons.settings_outlined),
        label: 'Settings',
      ),
    );
    return destinations;
  }

  List<Widget> get _pages {
    final pageList = <Widget>[
      LocalNotesPage(noteStorage: _noteStorage),
    ];

    if (_serverHostingEnabled) {
      pageList.add(
        OnlineNotesPage(
          noteStorage: _noteStorage,
          serverUrl: _serverHostController.text.trim(),
          accessToken: _tokenController.text.trim(),
          isOnlineServiceVerified: _isOnlineServiceVerified,
        ),
      );
    }

    pageList.add(
      SettingsPage(
        serverHostController: _serverHostController,
        tokenController: _tokenController,
        initialServerHostingEnabled: _serverHostingEnabled,
        isCheckingStatus: _isCheckingStatus,
        isOnlineServiceVerified: _isOnlineServiceVerified,
        onServerHostingChanged: _handleServerHostingChanged,
        onSettingsChanged: _onConnectivitySettingsChanged, // For server/token text fields
      ),
    );
    return pageList;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentDestinations = _buildDestinations();
    final currentPages = _pages;

    // Ensure currentPageIndex is valid
    if (_currentPageIndex >= currentPages.length) {
      _currentPageIndex = currentPages.length - 1;
      if (_currentPageIndex < 0) _currentPageIndex = 0;
    }

    int settingsPageIndex = currentPages.length - 1;

    return Scaffold(
      appBar: _currentPageIndex == settingsPageIndex
          ? AppBar(
        title: Row(
          children: [
            const Text("Settings"),
            if (_isCheckingStatus && _serverHostingEnabled && _serverHostController.text.isNotEmpty && _tokenController.text.isNotEmpty) ...[
              const SizedBox(width: 10),
              const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.5)),
            ]
          ],
        ),
        backgroundColor: theme.colorScheme.surfaceVariant,
        elevation: 0,
      )
          : null,
      body: IndexedStack(
        index: _currentPageIndex,
        children: currentPages,
      ),
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (index) {
          if (index < currentDestinations.length) {
            setState(() {
              _currentPageIndex = index;
            });
          }
        },
        selectedIndex: _currentPageIndex,
        destinations: currentDestinations,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
    );
  }
}
