import 'package:flutter/material.dart';

// A typedef for the callback when a note is saved.
// It passes the title and content back to the caller.
typedef OnSaveNote = void Function(String title, String content);

class AddNoteDialog extends StatefulWidget {
  final OnSaveNote onSave;

  const AddNoteDialog({
    super.key,
    required this.onSave,
  });

  @override
  State<AddNoteDialog> createState() => _AddNoteDialogState();
}

class _AddNoteDialogState extends State<AddNoteDialog> {
  final _formKey = GlobalKey<FormState>(); // For basic validation
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _contentController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _trySaveNote() async {
    if (_formKey.currentState?.validate() ?? false) {
      final title = _titleController.text.trim();
      final content = _contentController.text.trim();

      if (title.isEmpty && content.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Title or content cannot be empty.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      setState(() => _isLoading = true);

      try {
        // Simulate a slight delay if needed, or directly call onSave
        // await Future.delayed(Duration(milliseconds: 300));
        widget.onSave(title, content);
        if (mounted) {
          Navigator.of(context).pop(true); // Pop with success
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add New Local Note'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'Enter note title (optional)',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.sentences,
                validator: (value) {
                  // Example: Basic validation, can be more complex
                  // if (value == null || value.trim().isEmpty) {
                  //   return 'Title cannot be empty if content is also empty.';
                  // }
                  return null; // Return null if valid
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contentController,
                decoration: const InputDecoration(
                  labelText: 'Content',
                  hintText: 'Start typing your note...',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.sentences,
                maxLines: 5,
                minLines: 3,
                validator: (value) {
                  // Example: Basic validation
                  // if (value == null || value.trim().isEmpty) {
                  //    if (_titleController.text.trim().isEmpty) {
                  //      return 'Content cannot be empty if title is also empty.';
                  //    }
                  // }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(false), // Pop with failure/cancel
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          icon: _isLoading
              ? SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.onPrimary),
            ),
          )
              : const Icon(Icons.save_outlined),
          label: Text(_isLoading ? 'Saving...' : 'Save'),
          onPressed: _isLoading ? null : _trySaveNote,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
      ],
    );
  }
}

// Helper function to show the dialog (optional, but convenient)
Future<bool?> showAddNoteDialog(BuildContext context) async {
  String? savedTitle;
  String? savedContent;

  return null; // Placeholder, as we'll call it directly
}
