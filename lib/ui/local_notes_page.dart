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
  List<NoteMetadata> _noteMetadata = [];
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
        _noteMetadata = notes;
        _isLoadingNotes = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingNotes = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading notes: $e')));
    }
  }

  Future<void> _openNoteDialog({
    NoteMetadata? noteMetadata,
    String? content,
  }) async {
    final bool isEditing = noteMetadata != null;

    final result = await Navigator.push<bool?>(
      context,
      MaterialPageRoute(
        builder: (context) => AddNoteDialog(
          noteId: isEditing ? noteMetadata.id : null,
          initialTitle: isEditing ? noteMetadata.title : '',
          initialContent: content,
          onSave: (String title, String content, {String? noteId}) async {
            try {
              if (noteId != null) {
                await widget.noteStorage.updateLocalNote(
                  id: noteId,
                  title: title,
                  content: content,
                );
              } else {
                await widget.noteStorage.createLocalNote(
                  title: title,
                  content: content,
                );
              }
              await _loadLocalNotesMetadata();
              if (mounted) {
                Navigator.of(context).pop(true);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isEditing
                          ? 'Note updated successfully!'
                          : 'Note saved successfully!',
                    ),
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
              rethrow;
            }
          },
        ),
      ),
    );
  }

  Future<void> _openLocalNoteDetails(String noteId) async {
    if (!mounted) return;
    try {
      final fullNoteData = await widget.noteStorage.getLocalFullNote(noteId);
      if (fullNoteData != null && mounted) {
        final noteMetadata = _noteMetadata.firstWhere(
          (note) => note.id == noteId,
        );

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => Scaffold(
              appBar: AppBar(
                title: Text(
                  noteMetadata.title.isNotEmpty
                      ? noteMetadata.title
                      : 'Untitled Note',
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () async {
                      await _openNoteDialog(
                        noteMetadata: noteMetadata,
                        content: fullNoteData['content'],
                      );
                    },
                  ),
                ],
              ),
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  fullNoteData['content'] ?? '',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not load note content.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error opening note: $e')));
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
          content: const Text(
            'Are you sure you want to delete this local note? This action cannot be undone.',
          ),
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
      try {
        await widget.noteStorage.deleteLocalNote(noteId);
        await _loadLocalNotesMetadata();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Note deleted.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error deleting note: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoadingNotes) {
      return Center(
        child: CircularProgressIndicator(color: theme.colorScheme.primary),
      );
    }

    Widget content;
    if (_noteMetadata.isEmpty) {
      content = Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.note_add_outlined, size: 60, color: theme.hintColor),
              const SizedBox(height: 16.0),
              Text(
                '"The faintest ink is more powerful than the strongest memory."',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontFamily: 'Merriweather',
                  color: theme.hintColor,
                ),
              ),
              const SizedBox(height: 8.0),
              Text(
                "- Chinese Proverb",
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontFamily: 'Merriweather',
                  color: theme.hintColor,
                ),
              ),
              const SizedBox(height: 24.0),
              ElevatedButton.icon(
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Create Your First Note'),
                onPressed: () => _openNoteDialog(),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      content = RefreshIndicator(
        onRefresh: _loadLocalNotesMetadata,
        child: ListView.builder(
          padding: const EdgeInsets.only(
            top: 8.0,
            left: 8.0,
            right: 8.0,
            bottom: 80.0,
          ),
          itemCount: _noteMetadata.length,
          itemBuilder: (context, index) {
            final metadata = _noteMetadata[index];
            return Card(
              margin: const EdgeInsets.symmetric(
                vertical: 5.0,
                horizontal: 4.0,
              ),
              elevation: 1.5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 8.0,
                  horizontal: 16.0,
                ),
                title: Text(
                  metadata.title.isEmpty ? "Untitled Note" : metadata.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  'Updated: ${metadata.updatedAt.day}/${metadata.updatedAt.month}/${metadata.updatedAt.year} ${metadata.updatedAt.hour.toString().padLeft(2, '0')}:${metadata.updatedAt.minute.toString().padLeft(2, '0')}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.hintColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () => _openLocalNoteDetails(metadata.id),
                trailing: IconButton(
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    color: theme.colorScheme.error,
                  ),
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
      floatingActionButton: _noteMetadata.isEmpty && !_isLoadingNotes
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _openNoteDialog(),
              tooltip: 'Add Local Note',
              elevation: 2.0,
              icon: const Icon(Icons.add_rounded),
              label: const Text("New Note"),
            ),
    );
  }
}
