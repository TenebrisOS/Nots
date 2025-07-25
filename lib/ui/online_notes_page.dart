import 'package:flutter/material.dart';
import 'package:nots/models/note_metadata.dart';
import 'package:nots/services/note_storage_service.dart';
import 'package:nots/widgets/add_note_dialog.dart';

class OnlineNotesPage extends StatefulWidget {
  final NoteStorageService noteStorage;
  final String serverUrl;
  final String accessToken; // This widget stores it as accessToken
  final bool isOnlineServiceVerified;

  const OnlineNotesPage({
    super.key,
    required this.noteStorage,
    required this.serverUrl,
    required this.accessToken, // Received as accessToken
    required this.isOnlineServiceVerified,
  });

  @override
  State<OnlineNotesPage> createState() => _OnlineNotesPageState();
}

class _OnlineNotesPageState extends State<OnlineNotesPage> {
  List<NoteMetadata> _onlineNotes = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _updateStateBasedOnVerification();
  }

  @override
  void didUpdateWidget(covariant OnlineNotesPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOnlineServiceVerified != oldWidget.isOnlineServiceVerified ||
        (widget.isOnlineServiceVerified &&
            (widget.serverUrl != oldWidget.serverUrl ||
                widget.accessToken != oldWidget.accessToken))) { // Check widget.accessToken
      _updateStateBasedOnVerification();
    }
  }

  void _updateStateBasedOnVerification() {
    if (widget.isOnlineServiceVerified) {
      if (widget.serverUrl.isNotEmpty && widget.accessToken.isNotEmpty) { // Check widget.accessToken
        _loadOnlineNotesMetadata();
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _onlineNotes = [];
            _errorMessage =
            "Online service is marked as verified, but server details are missing.";
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _onlineNotes = [];
          if (widget.serverUrl.isEmpty || widget.accessToken.isEmpty) { // Check widget.accessToken
            _errorMessage =
            "Online sync is not configured. Please check settings.";
          } else {
            _errorMessage =
            "Server connection not verified or details are incorrect. Please check settings.";
          }
        });
      }
    }
  }

  Future<void> _loadOnlineNotesMetadata() async {
    if (!widget.isOnlineServiceVerified ||
        widget.serverUrl.isEmpty ||
        widget.accessToken.isEmpty) { // Check widget.accessToken
      if (mounted) {
        setState(() {
          _isLoading = false;
          _onlineNotes = [];
          if (widget.serverUrl.isEmpty || widget.accessToken.isEmpty) { // Check widget.accessToken
            _errorMessage =
            "Cannot load notes: Online sync details are missing.";
          } else {
            _errorMessage = "Cannot load notes: Connection not verified.";
          }
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      // Corrected: Pass widget.accessToken as 'token' to the service
      final notes = await widget.noteStorage.getAllOnlineNoteMetadata(
        widget.serverUrl,
        widget.accessToken, // This is the value
      );
      if (mounted) {
        setState(() {
          _onlineNotes = notes;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Error loading online notes: ${e.toString()}";
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _createNewOnlineNote(String title, String content) async {
    if (!widget.isOnlineServiceVerified) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  "Cannot create note: Not connected to server or connection unverified.")),
        );
      }
      return;
    }
    if (mounted) setState(() => _isLoading = true);
    try {
      // Corrected: Pass widget.accessToken as 'token' to the service
      await widget.noteStorage.createOnlineNote(
        title: title,
        content: content,
        serverUrl: widget.serverUrl,
        token: widget.accessToken, // Pass widget.accessToken as the 'token' parameter
      );
      _loadOnlineNotesMetadata(); // Refresh list
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Failed to create online note: ${e.toString()}")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteOnlineNote(String noteId) async {
    if (!widget.isOnlineServiceVerified) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  "Cannot delete note: Not connected to server or connection unverified.")),
        );
      }
      return;
    }
    if (mounted) setState(() => _isLoading = true);
    try {
      // Corrected: Pass widget.accessToken as 'token' to the service
      await widget.noteStorage.deleteOnlineNote(
        noteId,
        widget.serverUrl,
        widget.accessToken, // This is the value
      );
      _loadOnlineNotesMetadata();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Note deleted from server.")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error deleting note: ${e.toString()}")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Online Notes"),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
      ),
      body: _buildBody(),
      floatingActionButton: widget.isOnlineServiceVerified
          ? FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AddNoteDialog(
              onSave: (title, content) {
                _createNewOnlineNote(title, content);
              },
            ),
          );
        },
        icon: const Icon(Icons.add_comment_outlined),
        label: const Text("New Online Note"),
      )
          : null,
    );
  }

  Widget _buildBody() {
    if (_isLoading && _onlineNotes.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null && _onlineNotes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 16),
          ),
        ),
      );
    }

    if (_onlineNotes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            widget.isOnlineServiceVerified
                ? "No online notes found. Create one!"
                : "Online service is not available or not configured correctly. Please check Settings.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).hintColor, fontSize: 16),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadOnlineNotesMetadata,
      child: ListView.builder(
        itemCount: _onlineNotes.length,
        itemBuilder: (context, index) {
          final note = _onlineNotes[index];
          return ListTile(
            title: Text(note.title.isNotEmpty ? note.title : "Untitled Note"),
            subtitle: Text("Updated: ${note.updatedAt.toLocal().toString().substring(0, 16)}"),
            onTap: () {
              // TODO: Implement navigation to note detail page for online notes
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Tapped on online note: ${note.title} (Detail view not implemented yet)")),
              );
            },
            trailing: IconButton(
              icon: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('Confirm Delete'),
                      content: Text('Are you sure you want to delete "${note.title.isNotEmpty ? note.title : "Untitled Note"}" from the server? This action cannot be undone.'),
                      actions: <Widget>[
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('Delete'),
                          style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
                        ),
                      ],
                    );
                  },
                );
                if (confirm == true) {
                  _deleteOnlineNote(note.id);
                }
              },
            ),
          );
        },
      ),
    );
  }
}
