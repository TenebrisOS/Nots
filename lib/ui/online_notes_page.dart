import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nots/models/note_metadata.dart';
import 'package:nots/services/note_storage_service.dart';
import 'package:nots/widgets/add_note_dialog.dart';

class OnlineNotesPage extends StatefulWidget {
  final NoteStorageService noteStorage;
  final String serverUrl;
  final String accessToken;
  final bool isOnlineServiceVerified;

  const OnlineNotesPage({
    super.key,
    required this.noteStorage,
    required this.serverUrl,
    required this.accessToken,
    required this.isOnlineServiceVerified,
  });

  @override
  State<OnlineNotesPage> createState() => _OnlineNotesPageState();
}

class _OnlineNotesPageState extends State<OnlineNotesPage> {
  List<NoteMetadata> _onlineNotes = [];
  bool _isLoading = false;
  String? _errorMessage;

  final DateFormat _dateFormatter = DateFormat('MMM dd, yyyy HH:mm');

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
                widget.accessToken != oldWidget.accessToken))) {
      _updateStateBasedOnVerification();
    }
  }

  void _updateStateBasedOnVerification() {
    if (widget.isOnlineServiceVerified) {
      if (widget.serverUrl.isNotEmpty && widget.accessToken.isNotEmpty) {
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
          if (widget.serverUrl.isEmpty || widget.accessToken.isEmpty) {
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
        widget.accessToken.isEmpty) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _onlineNotes = [];
          if (widget.serverUrl.isEmpty || widget.accessToken.isEmpty) {
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
      final notes = await widget.noteStorage.getAllOnlineNotes(
        widget.serverUrl,
        widget.accessToken,
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
    if (!_ensureServiceAvailable()) return;

    if (mounted) setState(() => _isLoading = true);
    final String displayTitle = title.isNotEmpty ? title : "Untitled Note";
    try {
      await widget.noteStorage.createOnlineNote(
        title: title, // Send original title to service
        content: content,
        serverUrl: widget.serverUrl,
        token: widget.accessToken,
      );
      _loadOnlineNotesMetadata(); // Refresh list
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Note '$displayTitle' created online.")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
              Text("Failed to create online note '$displayTitle': ${e.toString()}")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteOnlineNote(String noteId, String noteTitle) async {
    if (!_ensureServiceAvailable()) return;

    if (mounted) setState(() => _isLoading = true);
    try {
      await widget.noteStorage.deleteOnlineNote(
        noteId,
        widget.serverUrl,
        widget.accessToken,
      );
      _loadOnlineNotesMetadata(); // Refresh list after delete
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Note '$noteTitle' deleted from server.")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error deleting note '$noteTitle': ${e.toString()}")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool _ensureServiceAvailable() {
    if (!widget.isOnlineServiceVerified) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  "Online service is not available or connection is unverified.")),
        );
      }
      return false;
    }
    if (widget.serverUrl.isEmpty || widget.accessToken.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Server details are missing. Please check settings.")),
        );
      }
      return false;
    }
    return true;
  }

  Future<void> _viewOnlineNoteDetail(NoteMetadata noteMetadata) async {
    if (!_ensureServiceAvailable()) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Dialog(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text("Loading note..."),
              ],
            ),
          ),
        );
      },
    );

    try {
      final fullNoteData = await widget.noteStorage.getOnlineFullNote(
        noteMetadata.id,
        widget.serverUrl,
        widget.accessToken,
      );

      if (mounted) Navigator.of(context).pop(); // Dismiss loading dialog

      if (fullNoteData != null && mounted) {
        String title = fullNoteData['title']?.toString() ?? noteMetadata.title;
        String content = fullNoteData['content']?.toString() ?? 'Content not available.';
        String createdAtStr = "N/A";
        String updatedAtStr = _dateFormatter.format(noteMetadata.updatedAt.toLocal());

        if (fullNoteData['created_at'] != null) {
          try {
            createdAtStr = _dateFormatter
                .format(DateTime.parse(fullNoteData['created_at']).toLocal());
          } catch (_) {  }
        }
        if (fullNoteData['updated_at'] != null) {
          try {
            updatedAtStr = _dateFormatter
                .format(DateTime.parse(fullNoteData['updated_at']).toLocal());
          } catch (_) { }
        }

        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(title.isNotEmpty ? title : "Untitled Note"),
              content: SingleChildScrollView(
                child: ListBody(
                  children: <Widget>[
                    SelectableText(content),
                    const SizedBox(height: 15),
                    Text(
                      "Created: $createdAtStr",
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      "Last Updated: $updatedAtStr",
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Close'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Could not load details for '${noteMetadata.title}'")),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Dismiss loading dialog on error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error loading note details: ${e.toString()}")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Online Notes"),
        elevation: 1, // Slight elevation for definition
        actions: [
          if (widget.isOnlineServiceVerified &&
              widget.serverUrl.isNotEmpty &&
              widget.accessToken.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _isLoading ? null : _loadOnlineNotesMetadata,
              tooltip: "Refresh Notes",
            ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: widget.isOnlineServiceVerified &&
          widget.serverUrl.isNotEmpty &&
          widget.accessToken.isNotEmpty
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
        // elevation: 2.0, // Default is usually fine
      )
          : null,
    );
  }

  Widget _buildBody() {
    if (_isLoading && _onlineNotes.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0), // Increased padding
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline,
                  color: Theme.of(context).colorScheme.error, size: 48),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.error, fontSize: 16),
              ),
              const SizedBox(height: 24),
              if (widget.isOnlineServiceVerified &&
                  widget.serverUrl.isNotEmpty &&
                  widget.accessToken.isNotEmpty)
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text("Retry"),
                  onPressed: _loadOnlineNotesMetadata,
                  style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)
                  ),
                )
            ],
          ),
        ),
      );
    }

    if (!widget.isOnlineServiceVerified ||
        widget.serverUrl.isEmpty ||
        widget.accessToken.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0), // Increased padding
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off_outlined, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                widget.serverUrl.isEmpty || widget.accessToken.isEmpty
                    ? "Online sync is not configured. Please check settings."
                    : "Server connection not verified or details are incorrect. Please check settings.",
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Theme.of(context).hintColor, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    if (_onlineNotes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0), // Increased padding
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.note_add_outlined, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                "No online notes found. Create one!",
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Theme.of(context).hintColor, fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadOnlineNotesMetadata,
                icon: const Icon(Icons.refresh),
                label: const Text("Refresh"),
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)
                ),
              )
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadOnlineNotesMetadata,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0), // Added padding
        itemCount: _onlineNotes.length,
        itemBuilder: (context, index) {
          final note = _onlineNotes[index];
          final displayTitle = note.title.isNotEmpty ? note.title : "Untitled Note";

          return Card(
            elevation: 2.0, // Add a subtle shadow
            margin: const EdgeInsets.symmetric(vertical: 6.0), // Space between cards
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)), // Slightly rounded corners
            child: ListTile(
              leading: Icon(
                Icons.notes_outlined, // Or Icons.note_alt_outlined
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(
                displayTitle,
                style: const TextStyle(fontWeight: FontWeight.w500), // Slightly bolder title
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                "Updated: ${_dateFormatter.format(note.updatedAt.toLocal())}",
                style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () {
                _viewOnlineNoteDetail(note);
              },
              trailing: IconButton(
                icon: Icon(Icons.delete_outline,
                    color: Theme.of(context).colorScheme.error),
                tooltip: "Delete Note",
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Confirm Delete'),
                        content: Text(
                            'Are you sure you want to delete "$displayTitle" from the server? This action cannot be undone.'),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text('Delete'),
                            style: TextButton.styleFrom(
                                foregroundColor:
                                Theme.of(context).colorScheme.error),
                          ),
                        ],
                      );
                    },
                  );
                  if (confirm == true) {
                    _deleteOnlineNote(note.id, displayTitle);
                  }
                },
              ),
            ),
          );
        },
        separatorBuilder: (context, index) => const SizedBox(height: 0), // Or use Divider()
      ),
    );
  }
}
