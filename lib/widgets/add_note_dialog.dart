import 'package:flutter/material.dart';

class AddNoteDialog extends StatefulWidget {
  final Function(String title, String content) onSave;

  const AddNoteDialog({super.key, required this.onSave});

  @override
  State<AddNoteDialog> createState() => _AddNoteDialogState();
}

class _AddNoteDialogState extends State<AddNoteDialog> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add New Note'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView( // Important for smaller screens
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    // Allow empty title, will be handled as "Untitled Note"
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contentController,
                decoration: const InputDecoration(
                  labelText: 'Content',
                  alignLabelWithHint: true, // Good for multi-line
                ),
                maxLines: 5, // Adjust as needed
                validator: (value) {
                  // Content can be empty if desired
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Cancel'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        TextButton(
          child: const Text('Save'),
          onPressed: () {
            // No validation check here, as we allow empty title/content
            // The service layer or backend can handle default titles like "Untitled Note"
            widget.onSave(_titleController.text, _contentController.text);
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
