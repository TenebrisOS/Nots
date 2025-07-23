import 'package:flutter/material.dart';
import '../services/note_storage_service.dart';
import 'local_notes_page.dart';
import 'online_notes_page.dart';
import 'settings_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentPageIndex = 0;
  final NoteStorageService _noteStorage = NoteStorageService(); // Instance of your service

  // Controllers for settings
  final TextEditingController _serverHostController = TextEditingController();
  final TextEditingController _tokenController = TextEditingController();
  bool _serverHostingEnabled = false;

  @override
  void initState() {
    super.initState();
    // TODO: Load _serverHostingEnabled, _serverHostController.text, _tokenController.text
    // from SharedPreferences or secure storage.
    // Example (you'll need to add the shared_preferences package):
    // _loadSettings();
  }

  // Example for loading settings (requires shared_preferences package)
  /*
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _serverHostingEnabled = prefs.getBool('serverHostingEnabled') ?? false;
      _serverHostController.text = prefs.getString('serverHost') ?? '';
      // For token, use flutter_secure_storage
    });
  }

  Future<void> _saveServerHostingEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('serverHostingEnabled', enabled);
  }
  */

  void _handleServerHostingChanged(bool enabled) {
    setState(() {
      _serverHostingEnabled = enabled;
      // If "Online" was selected and now disabled, adjust index
      if (!_serverHostingEnabled && _currentPageIndex == 1) {
        final destinations = _buildDestinations(); // Get current destinations
        // If 'Online' was indeed the second tab (index 1) and now it's gone
        // (meaning destinations.length is 2: Local, Settings),
        // then move to 'Local' (index 0).
        if (destinations.length == 2) {
          _currentPageIndex = 0;
        }
        // This handles the case where there were 3 tabs, Online was active (index 1),
        // and it's removed. The new index for Settings becomes 1.
        // If we want to go to Local instead:
        // _currentPageIndex = 0;
        // If we want to go to Settings (which is now index 1):
        // _currentPageIndex = 1; // This might be desired if user was configuring online and disabled it.
        // For now, defaulting to Local if Online tab is removed while active.
      }
      // TODO: Save _serverHostingEnabled state (e.g., using _saveServerHostingEnabled(enabled);)
    });
  }

  void _handleSettingsChanged() {
    // This function can be called from SettingsPage when text fields change,
    // to trigger a rebuild if OnlineNotesPage needs to react to new server/token values.
    setState(() {
      // Just calling setState will rebuild and pass new values to OnlineNotesPage
    });
    // TODO: Save settings (debounced for text fields)
    // Example (you'll need to add the shared_preferences package):
    // _saveServerHost(); // Create this method to save _serverHostController.text
  }

  @override
  void dispose() {
    _serverHostController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  List<NavigationDestination> _buildDestinations() {
    return [
      const NavigationDestination(
        selectedIcon: Icon(Icons.folder_special_rounded),
        icon: Icon(Icons.folder_special_outlined),
        label: 'Local',
      ),
      if (_serverHostingEnabled) // This condition is crucial
        const NavigationDestination(
          selectedIcon: Icon(Icons.cloud_done_rounded), // Ensure this line exists
          icon: Icon(Icons.cloud_outlined),          // Ensure this line exists
          label: 'Online',
        ),
      const NavigationDestination(
        selectedIcon: Icon(Icons.settings_applications),
        icon: Icon(Icons.settings_outlined),
        label: 'Settings',
      ),
    ];
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final destinations = _buildDestinations();

    List<Widget> pages = [
      LocalNotesPage(noteStorage: _noteStorage),
      if (_serverHostingEnabled)
        OnlineNotesPage(
          noteStorage: _noteStorage,
          serverUrl: _serverHostController.text.trim(),
          accessToken: _tokenController.text.trim(),
        ),
      SettingsPage(
        serverHostController: _serverHostController,
        tokenController: _tokenController,
        initialServerHostingEnabled: _serverHostingEnabled,
        onServerHostingChanged: _handleServerHostingChanged,
        onSettingsChanged: _handleSettingsChanged,
      ),
    ];

    // Safety check for currentPageIndex: If it's out of bounds, reset to 0 or last valid index.
    if (_currentPageIndex >= pages.length) {
      _currentPageIndex = pages.length - 1; // Go to the last available page (usually Settings)
      if (_currentPageIndex < 0) { // Should not happen with current logic
        _currentPageIndex = 0;
      }
    }

    // Determine the index of the settings page for AppBar visibility
    // If server hosting is enabled, Settings is the 3rd tab (index 2)
    // If server hosting is disabled, Settings is the 2nd tab (index 1)
    int settingsPageIndex = _serverHostingEnabled ? 2 : 1;

    return Scaffold(
      appBar: _currentPageIndex == settingsPageIndex
          ? AppBar(
        title: const Text("Settings"),
        backgroundColor: theme.colorScheme.surfaceVariant,
        elevation: 0,
      )
          : null,
      // Note: FAB is now part of LocalNotesPage and will be displayed by it
      body: IndexedStack( // Use IndexedStack to preserve page state
        index: _currentPageIndex,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (index) {
          setState(() {
            // Ensure the selected index is valid for the current number of pages
            if (index < pages.length) {
              _currentPageIndex = index;
            } else {
              // Fallback if somehow an invalid index is selected, though unlikely
              // with destinations and pages being in sync.
              _currentPageIndex = 0;
            }
          });
        },
        selectedIndex: _currentPageIndex,
        destinations: destinations,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
    );
  }
}
