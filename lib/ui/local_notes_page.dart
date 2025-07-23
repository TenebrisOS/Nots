import 'package:flutter/material.dart';
import '../models/note_metadata.dart';
import '../services/note_storage_service.dart';
import '../widgets/add_note_dialog.dart';
class LocalNotesPage extends StatefulWidget {
  final NoteStorageService noteStorage;

  const LocalNotesPage({super.key, required this.noteStorage});

  @override
  State<LocalNotesPage> createState() => _LocalNotesPageState();
}

class _LocalNotesPageState extends State<LocalNotesPage> {
  List<NoteMetadata> _noteMetadatas = [];
  bool _isLoadingNotes = true;

  @override
  void initState() {
    super.initState();
    _loadLocalNotesMetadata();
  }

  Future<void> _loadLocalNotesMetadata() async {
    if (!mounted) return;
    setState(() => _isLoadingNotes = true);

    try {
      final notes = await widget.noteStorage.getAllLocalNoteMetadata();
      if (!mounted) return;
      setState(() {
        _noteMetadatas = notes;
        _isLoadingNotes = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingNotes = false;
        // Optionally, show an error message to the user
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading notes: $e')),
      );
    }
  }

  void _showAddNoteDialog() {
    showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        // dialogContext is the context specifically for the dialog
        return AddNoteDialog(
          onSave: (String title, String content) async {
            // This callback is executed when AddNoteDialog calls widget.onSave
            try {
              await widget.noteStorage.createLocalNote(
                title: title,
                content: content,
              );
              // After AddNoteDialog pops itself on success,
              // or even if it doesn't pop itself and we pop it from here,
              // we reload the notes.
              // Note: AddNoteDialog's _trySaveNote now pops on success.
              if (mounted) {
                await _loadLocalNotesMetadata();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Note saved successfully!'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error saving note: $e'),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                );
              }
              // Rethrow or handle if AddNoteDialog needs to know about the failure
              // to prevent it from popping, but AddNoteDialog handles its loading state.
            }
          },
        );
      },
    ).then((savedSuccessfully) {
      // This 'then' block is called after the dialog is popped.
      // 'savedSuccessfully' comes from Navigator.of(context).pop(true/false) in AddNoteDialog.
      if (savedSuccessfully == true) {
        // Actions here are optional as onSave already reloaded notes.
        print("AddNoteDialog reported successful save and was popped.");
      } else if (savedSuccessfully == false) {
        print("AddNoteDialog was cancelled or reported save failure and was popped.");
      } else {
        print("AddNoteDialog was dismissed (e.g., barrier tap).");
      }
    });
  }

  Future<void> _openLocalNoteDetails(String noteId) async {
    if (!mounted) return;
    // Consider adding a loading indicator for this operation
    try {
      final fullNoteData = await widget.noteStorage.getLocalFullNote(noteId);
      if (fullNoteData != null && mounted) {
        showDialog(
          context: context,
          builder: (BuildContext dialogContext) => AlertDialog(
            title: Text(fullNoteData['title']?.isNotEmpty == true ? fullNoteData['title']! : 'Untitled Note'),
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening note: $e')),
        );
      }
    }
  }

  Future<void> _deleteLocalNote(String noteId) async {
    if (!mounted) return;

    final confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete Local Note?'),
          content: const Text('Are you sure you want to delete this local note? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Delete'),
              style: TextButton.styleFrom(foregroundColor: Colors.redAccent), // Or theme.colorScheme.error
            ),
          ],
        );
      },
    );

    if (confirmDelete == true && mounted) {
      try {
        await widget.noteStorage.deleteLocalNote(noteId);
        await _loadLocalNotesMetadata(); // Refresh list
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Note deleted.'), behavior: SnackBarBehavior.floating),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting note: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoadingNotes) {
      return Center(child: CircularProgressIndicator(color: theme.colorScheme.primary));
    }

    Widget content;
    if (_noteMetadatas.isEmpty) {
      content = Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.note_add_outlined, size: 60, color: theme.hintColor.withOpacity(0.6)),
              const SizedBox(height: 16.0),
              Text(
                '"The faintest ink is more powerful than the strongest memory."',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                    fontFamily: 'Merriweather', color: theme.hintColor.withOpacity(0.8)),
              ),
              const SizedBox(height: 8.0),
              Text(
                "- Chinese Proverb",
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                    fontFamily: 'Merriweather', color: theme.hintColor.withOpacity(0.7)),
              ),
              const SizedBox(height: 24.0),
              ElevatedButton.icon(
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Create Your First Note'),
                onPressed: _showAddNoteDialog,
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)
                ),
              )
            ],
          ),
        ),
      );
    } else {
      content = RefreshIndicator(
        onRefresh: _loadLocalNotesMetadata,
        child: ListView.builder(
          padding: const EdgeInsets.only(top: 8.0, left: 8.0, right: 8.0, bottom: 80.0), // Padding for FAB
          itemCount: _noteMetadatas.length,
          itemBuilder: (context, index) {
            final metadata = _noteMetadatas[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 4.0),
              elevation: 1.5,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                title: Text(
                  metadata.title.isEmpty ? "Untitled Note" : metadata.title,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  'Updated: ${metadata.updatedAt.day}/${metadata.updatedAt.month}/${metadata.updatedAt.year} ${metadata.updatedAt.hour.toString().padLeft(2, '0')}:${metadata.updatedAt.minute.toString().padLeft(2, '0')}',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () => _openLocalNoteDetails(metadata.id),
                trailing: IconButton(
                  icon: Icon(Icons.delete_outline_rounded, color: theme.colorScheme.error.withOpacity(0.85)),
                  tooltip: 'Delete Note',
                  onPressed: () => _deleteLocalNote(metadata.id),
                ),
              ),
            );
          },
        ),
      );
    }

    return Scaffold(
      body: SafeArea(child: content),
      floatingActionButton: _noteMetadatas.isEmpty && !_isLoadingNotes // Only show FAB if list is not empty or not loading
          ? null
          : FloatingActionButton.extended(
        onPressed: _showAddNoteDialog,
        tooltip: 'Add Local Note',
        elevation: 2.0,
        icon: const Icon(Icons.add_rounded),
        label: const Text("New Note"),
      ),
    );
  }
}
