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

  // ---- Note Storage Integration ----
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

  void _showAddNoteDialog() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    bool isSaving = false;

    showDialog<bool>(
      context: context,
      barrierDismissible: !isSaving,
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
                if (!isSaving) {
                  Navigator.of(dialogContext).pop(false);
                }
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (isSaving) return;

                final title = titleController.text.trim();
                final content = contentController.text.trim();

                if (title.isEmpty && content.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Title or content cannot be empty.')),
                  );
                  return;
                }

                isSaving = true;
                Navigator.of(dialogContext).pop(true);

                try {
                  await _noteStorage.createNote(
                    title: title.isEmpty ? "Untitled Note" : title,
                    content: content,
                  );
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error saving note: $e')),
                    );
                  }
                } finally {
                  isSaving = false;
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    ).then((savedSuccessfully) async {
      titleController.dispose();
      contentController.dispose();

      if (savedSuccessfully == true && mounted) {
        await _loadNotesMetadata();
      }
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
      await _loadNotesMetadata();
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
      _isLoadingNotes
          ? Center(child: CircularProgressIndicator(color: theme.colorScheme.primary))
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
              margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
              child: ListTile(
                title: Text(
                  metadata.title.isEmpty ? "Untitled Note" : metadata.title,
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
                      color: theme.colorScheme.error.withOpacity(0.8)),
                  tooltip: 'Delete Note',
                  onPressed: () => _deleteNote(metadata.id),
                ),
              ),
            );
          },
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
                      Row(children: [
                        Expanded(
                            child: Text('Server hosting',
                                style: theme.textTheme.titleMedium)),
                        Switch(
                          value: serverHostingEnabled,
                          onChanged: (bool value) {
                            setState(() {
                              serverHostingEnabled = value;
                            });
                          },
                        ),
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
