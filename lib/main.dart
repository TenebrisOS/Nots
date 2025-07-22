import 'package:flutter/material.dart';
import 'notes_system.dart';
import 'note_storage.dart';

void main() => runApp(const App());

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: const NavigationExample(),
        theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.green,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
            fontFamily: 'Merriweather'));
  }
}

class NavigationExample extends StatefulWidget {
  const NavigationExample({super.key});

  @override
  State<NavigationExample> createState() => _NavigationExampleState();
}

class _NavigationExampleState extends State<NavigationExample> {
  int currentPageIndex = 0;
  final TextEditingController _settingsTextFieldController =
  TextEditingController();
  bool serverHostingEnabled = false;

  // ---- Note Storage Integration ----
  final NoteTxtStorageService _noteStorage = NoteTxtStorageService();
  List<NoteMetadata> _noteMetadatas = [];
  bool _isLoadingNotes = true;
  // ---- End Note Storage Integration --- -

  @override
  void initState() {
    super.initState();
    _loadNotesMetadata(); // Load notes when the widget initializes
  }

  Future<void> _loadNotesMetadata() async {
    if (!mounted) return; // Defensive check
    setState(() => _isLoadingNotes = true);
    _noteMetadatas = await _noteStorage.getAllNoteMetadata();
    // Sort them by update date, newest first
    _noteMetadatas.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    if (!mounted) return; // Defensive check
    setState(() => _isLoadingNotes = false);
  }

  void _showAddNoteDialog() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside during save
      builder: (BuildContext dialogContext) { // Use dialogContext for actions inside the dialog
        return AlertDialog(
          title: const Text('Add New Note'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: contentController,
                  decoration: const InputDecoration(labelText: 'Content'),
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 5,
                  minLines: 3,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Use dialogContext
              },
            ),
            TextButton(
              child: const Text('Save'),
              onPressed: () async {
                final title = titleController.text;
                final content = contentController.text;

                if (title.isNotEmpty || content.isNotEmpty) {
                  // Pop the dialog FIRST, using its own context
                  Navigator.of(dialogContext).pop();

                  // Then perform async work and update state of the parent page
                  await _noteStorage.createNote(
                      title: title.isEmpty ? "Untitled Note" : title,
                      content: content);

                  // Check if the _NavigationExampleState widget is still mounted
                  if (mounted) {
                    await _loadNotesMetadata(); // Refresh the list
                  }
                } else {
                  // If validation fails, use the ScaffoldMessenger from the main page's context
                  // or the dialogContext if you want it to appear above the dialog.
                  // For simplicity, using the main page's context (this.context or just context)
                  if (mounted) { // Check if _NavigationExampleState is mounted
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      const SnackBar(
                          content: Text('Title or content cannot be empty.')),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    ).then((_) {
      // This block executes after the dialog is popped,
      // regardless of how it was popped (Save, Cancel, barrier tap if enabled).
      // This is the correct place to dispose controllers created for the dialog.
      titleController.dispose();
      contentController.dispose();
    });
  }

  Future<void> _openNoteDetails(String noteId) async {
    if (!mounted) return;
    final fullNoteData = await _noteStorage.getFullNote(noteId);
    if (fullNoteData != null && mounted) {
      showDialog(
          context: context, // Use the page's context
          builder: (BuildContext dialogContext) => AlertDialog( // dialogContext for this specific dialog
            title: Text(fullNoteData['title'] ?? 'Note'),
            content: SingleChildScrollView(
                child: Text(fullNoteData['content'] ?? '')),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Close'))
            ],
          ));
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not load note content.')),
      );
    }
  }

  Future<void> _deleteNote(String noteId) async {
    if (!mounted) return;
    final confirmDelete = await showDialog<bool>(
      context: context, // Page's context
      builder: (BuildContext dialogContext) { // dialogContext for this specific dialog
        return AlertDialog(
          title: const Text('Delete Note?'),
          content: const Text(
              'Are you sure you want to delete this note? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Delete'),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
            ),
          ],
        );
      },
    );

    if (confirmDelete == true && mounted) {
      await _noteStorage.deleteNote(noteId);
      await _loadNotesMetadata(); // Refresh the list
    }
  }

  @override
  void dispose() {
    _settingsTextFieldController.dispose();
    // _noteMetadatas and _noteStorage don't need explicit disposal unless they hold
    // resources that Dart's garbage collector won't handle (like open streams not managed internally).
    // The TextEditingControllers for the dialog are disposed in the .then() block.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isSmallScreen = MediaQuery.of(context).size.width < 600;

    String currentPageTitle = "Nots"; // Default, not really used if main AppBar is gone
    if (currentPageIndex == 1) {
      currentPageTitle = "Settings";
    }

    final List<Widget> pages = <Widget>[
      /// Home page - MODIFIED TO SHOW NOTES
      _isLoadingNotes
          ? Center(
          child:
          CircularProgressIndicator(color: theme.colorScheme.primary))
          : _noteMetadatas.isEmpty
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'No notes yet. Tap + to add one!',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
                fontFamily: 'Merriweather',
                color: theme.hintColor.withOpacity(0.7)),
          ),
        ),
      )
          : RefreshIndicator(
        onRefresh: _loadNotesMetadata,
        child: ListView.builder(
          padding: const EdgeInsets.all(8.0),
          itemCount: _noteMetadatas.length,
          itemBuilder: (context, index) {
            final metadata = _noteMetadatas[index];
            return Card(
              margin: const EdgeInsets.symmetric(
                  vertical: 6.0, horizontal: 8.0),
              child: ListTile(
                title: Text(
                  metadata.title.isEmpty
                      ? "Untitled Note"
                      : metadata.title,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  'Updated: ${metadata.updatedAt.day}/${metadata.updatedAt.month}/${metadata.updatedAt.year} ${metadata.updatedAt.hour}:${metadata.updatedAt.minute.toString().padLeft(2, '0')}',
                  style: theme.textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () => _openNoteDetails(metadata.id),
                trailing: IconButton(
                  icon: Icon(Icons.delete_outline,
                      color:
                      theme.colorScheme.error.withOpacity(0.8)),
                  tooltip: 'Delete Note',
                  onPressed: () => _deleteNote(metadata.id),
                ),
              ),
            );
          },
        ),
      ),

      /// Settings page
      SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 16.0 : 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Connectivity',
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Card(
                elevation: 1.0,
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: <Widget>[
                        Expanded(
                            child: Text('Server hosting',
                                style: theme.textTheme.titleMedium)),
                        Switch(
                            value: serverHostingEnabled,
                            onChanged: (bool value) {
                              setState(() {
                                serverHostingEnabled = value;
                              });
                            }),
                      ]),
                      const SizedBox(height: 12),
                      Text('Server Host Address:',
                          style: serverHostingEnabled
                              ? theme.textTheme.titleSmall
                              : theme.textTheme.titleSmall
                              ?.copyWith(color: theme.disabledColor)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _settingsTextFieldController,
                        enabled: serverHostingEnabled,
                        decoration: InputDecoration(
                          hintText: serverHostingEnabled
                              ? 'e.g., http(s)://example.com:9999'
                              : 'Disabled',
                          border: const OutlineInputBorder(),
                          isDense: true,
                          fillColor: serverHostingEnabled
                              ? null
                              : theme.disabledColor.withOpacity(0.05),
                          filled: true,
                        ),
                        onChanged: serverHostingEnabled ? (text) {} : null,
                        onSubmitted: serverHostingEnabled ? (text) {} : null,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),
              const Divider(),
              const SizedBox(height: 24),
              Text('Security',
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Card(
                elevation: 1.0,
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 16.0),
                  child: Row(children: <Widget>[
                    Expanded(
                        child: Text('Enable End-to-End Encryption',
                            style: theme.textTheme.titleMedium
                                ?.copyWith(color: theme.disabledColor))),
                    const Switch(value: false, onChanged: null),
                  ]),
                ),
              ),
              Padding(
                padding:
                const EdgeInsets.only(left: 16.0, top: 4.0, right: 16.0),
                child: Text('This feature is currently unavailable.',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.disabledColor)),
              ),
            ],
          ),
        ),
      ),
    ];

    return Scaffold(
      appBar: currentPageIndex == 1
          ? AppBar(
          title: Text(currentPageTitle),
          backgroundColor: theme.colorScheme.surfaceVariant,
          elevation: 0)
          : null,
      floatingActionButton: currentPageIndex == 0
          ? FloatingActionButton(
        onPressed: _showAddNoteDialog,
        tooltip: 'Add a Note',
        elevation: 2.0,
        child: const Icon(Icons.add_rounded),
      )
          : null,
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (int index) {
          setState(() {
            currentPageIndex = index;
          });
        },
        selectedIndex: currentPageIndex,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        elevation: 2.0,
        destinations: const <Widget>[
          NavigationDestination(
              selectedIcon: Icon(Icons.home_filled),
              icon: Icon(Icons.home_outlined),
              label: 'Home'),
          NavigationDestination(
              selectedIcon: Icon(Icons.settings_applications),
              icon: Icon(Icons.settings_outlined),
              label: 'Settings'),
        ],
      ),
      body: pages[currentPageIndex],
    );
  }
}
