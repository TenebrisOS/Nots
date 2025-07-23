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
        fontFamily: 'Merriweather',
      ),
    );
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

  final NoteTxtStorageService _noteStorage = NoteTxtStorageService();
  List<NoteMetadata> _noteMetadatas = [];
  bool _isLoadingNotes = true;

  @override
  void initState() {
    super.initState();
    _loadNotesMetadata();
  }

  Future<void> _loadNotesMetadata() async {
    if (!mounted) return;
    setState(() => _isLoadingNotes = true);

    final notes = await _noteStorage.getAllNoteMetadata();
    notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    if (!mounted) return;
    setState(() {
      _noteMetadatas = notes;
      _isLoadingNotes = false;
    });
  }

  // MODIFIED _showAddNoteDialog TO CORRECTLY REFRESH AFTER SAVE
  void _showAddNoteDialog() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    // No need for isSaving here as async work is moved to .then()

    showDialog<bool>( // Expect a boolean result
      context: context,
      barrierDismissible: true, // Allow dismissal by tapping outside, can be set to false if needed
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Add New Note'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false); // Pop dialog, return false (not saved)
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () { // No async here, just validation and pop
                final title = titleController.text.trim();
                final content = contentController.text.trim();

                if (title.isEmpty && content.isEmpty) {
                  // Show SnackBar using the main page's context or dialogContext.
                  // Using this.context (main page's) for SnackBar is generally safer after pop.
                  // However, if validation fails *before* pop, dialogContext is fine.
                  ScaffoldMessenger.of(this.context).showSnackBar( // Or use dialogContext if preferred for pre-pop messages
                    const SnackBar(
                        content: Text('Title or content cannot be empty.')),
                  );
                  return; // Don't pop, let user correct
                }
                // If valid, pop the dialog and pass 'true'
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    ).then((savedSuccessfully) async { // This block executes AFTER the dialog is popped
      if (!mounted) return; // Ensure widget is still mounted

      if (savedSuccessfully == true) {
        // Only proceed if 'Save' was pressed and returned true
        try {
          // Perform the actual save operation here
          await _noteStorage.createNote(
            title: titleController.text.trim().isEmpty ? "Untitled Note" : titleController.text.trim(),
            content: contentController.text.trim(),
          );

          // AFTER successful save, load the notes again
          if (mounted) { // Re-check mounted status before calling async state update
            await _loadNotesMetadata();
          }

        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error saving note: $e')),
            );
          }
        }
      }

      // Dispose controllers regardless of whether save was successful or dialog was cancelled
      titleController.dispose();
      contentController.dispose();
    });
  }

  Future<void> _openNoteDetails(String noteId) async {
    if (!mounted) return;
    final fullNoteData = await _noteStorage.getFullNote(noteId);
    if (fullNoteData != null && mounted) {
      showDialog(
        context: context,
        builder: (BuildContext dialogContext) => AlertDialog(
          title: Text(fullNoteData['title'] ?? 'Note'),
          content: SingleChildScrollView(
            child: Text(fullNoteData['content'] ?? ''),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not load note content.')),
      );
    }
  }

  Future<void> _deleteNote(String noteId) async {
    if (!mounted) return;
    final confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete Note?'),
          content: const Text(
              'Are you sure you want to delete this note? This action cannot be undone.'),
          actions: [
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
      await _loadNotesMetadata(); // Refresh after delete
    }
  }

  @override
  void dispose() {
    _settingsTextFieldController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    final pages = [
      // Notes Page (Home)
      _isLoadingNotes
          ? Center(child: CircularProgressIndicator(color: theme.colorScheme.primary))
          : _noteMetadatas.isEmpty
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '"The faintest ink is more powerful than the strongest memory." ',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                    fontFamily: 'Merriweather',
                    color: theme.hintColor.withOpacity(0.7)),
              ),
              const SizedBox(height: 8.0),
              Text(
                "- Chinese Proverb", // Or Confucius (attributed)
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                    fontFamily: 'Merriweather',
                    color: theme.hintColor.withOpacity(0.6)),
              )
            ],
          ),
        ),
      )
          : SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadNotesMetadata,
          child: ListView.builder(
            padding: const EdgeInsets.only(
              top: 16.0, // Space from top status bar
              left: 8.0,
              right: 8.0,
              bottom: 8.0,
            ),
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
                        color: theme.colorScheme.error
                            .withOpacity(0.8)),
                    tooltip: 'Delete Note',
                    onPressed: () => _deleteNote(metadata.id),
                  ),
                ),
              );
            },
          ),
        ),
      ),

      // Settings Page
      SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 16.0 : 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Storage',
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
                      // ----- SERVER HOSTING SECTION -----
                      Row(children: [
                        Expanded(
                            child: Text('Server hosting',
                                style: theme.textTheme.titleMedium?.copyWith(color: theme.disabledColor) // Style as disabled
                            )),
                        Switch(
                          value: false, // Keep it visually off
                          onChanged: null, // Disable the switch
                        ),
                      ]),
                      // "Server Host Address" input field (disabled)
                      const SizedBox(height: 12),
                      Text('Server Host Address:',
                          style: theme.textTheme.titleSmall
                              ?.copyWith(color: theme.disabledColor) // Style as disabled
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _settingsTextFieldController, // Controller can remain
                        enabled: false, // Disable the text field
                        decoration: InputDecoration(
                          hintText: 'Disabled', // Show disabled hint
                          border: const OutlineInputBorder(),
                          isDense: true,
                          fillColor: theme.disabledColor.withOpacity(0.05),
                          filled: true,
                        ),
                      ),
                      Padding( // Unavailability note MOVED HERE - AFTER the TextField
                        padding: const EdgeInsets.only(top: 8.0), // Added a bit more top padding for spacing from TextField
                        child: Text(
                          'This feature is currently unavailable.',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: theme.disabledColor),
                        ),
                      ),
                      // ----- END OF SERVER HOSTING SECTION -----
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
                  padding: const EdgeInsets.all(16.0),
                  child: Row(children: [
                    Expanded(
                        child: Text('Enable End-to-End Encryption',
                            style: theme.textTheme.titleMedium
                                ?.copyWith(color: theme.disabledColor))),
                    const Switch(value: false, onChanged: null),
                  ]),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16.0, top: 4.0, right: 16.0),
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
        title: const Text("Settings"),
        backgroundColor: theme.colorScheme.surfaceVariant,
        elevation: 0,
      )
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
        onDestinationSelected: (index) {
          setState(() => currentPageIndex = index);
        },
        selectedIndex: currentPageIndex,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
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
