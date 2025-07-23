import 'package:flutter/material.dart';
import '../models/note_metadata.dart';
import '../services/note_storage_service.dart';

class OnlineNotesPage extends StatefulWidget {
  final NoteStorageService noteStorage;
  final String serverUrl;
  final String accessToken;

  const OnlineNotesPage({
    super.key,
    required this.noteStorage,
    required this.serverUrl,
    required this.accessToken,
  });

  @override
  State<OnlineNotesPage> createState() => _OnlineNotesPageState();
}

class _OnlineNotesPageState extends State<OnlineNotesPage> {
  List<NoteMetadata> _onlineNotes = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // No need to check widget.serverUrl.isNotEmpty here for initial loading state
    // _fetchOnlineNotes will handle it.
    _fetchOnlineNotes();
  }

  @override
  void didUpdateWidget(covariant OnlineNotesPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If serverUrl or accessToken changes, refetch
    if (widget.serverUrl != oldWidget.serverUrl || widget.accessToken != oldWidget.accessToken) {
      _fetchOnlineNotes();
    }
  }

  Future<void> _fetchOnlineNotes() async {
    if (!mounted) return;

    if (widget.serverUrl.trim().isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = null; // Clear previous errors
        _onlineNotes = []; // Clear previous notes
        // Message will be handled by the build method's check
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final notes = await widget.noteStorage.getAllOnlineNoteMetadata(widget.serverUrl, widget.accessToken);
      if (!mounted) return;
      setState(() {
        _onlineNotes = notes;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = "Error fetching notes: ${e.toString()}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Case 1: Server URL not configured
    if (widget.serverUrl.trim().isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_off_outlined, // Icon for server not configured
                size: 60,
                color: theme.hintColor.withOpacity(0.7),
              ),
              const SizedBox(height: 16),
              Text(
                'Please configure your server address in Settings to enable online notes.',
                style: theme.textTheme.titleMedium?.copyWith(color: theme.hintColor),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Case 2: Loading
    if (_isLoading) {
      return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: theme.colorScheme.primary),
              const SizedBox(height: 16),
              Text("Fetching online notes...", style: theme.textTheme.bodyMedium)
            ],
          )
      );
    }

    // Case 3: Error Message
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.redAccent, size: 48), // Error icon
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.error),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                onPressed: _fetchOnlineNotes,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.errorContainer,
                  foregroundColor: theme.colorScheme.onErrorContainer,
                ),
              )
            ],
          ),
        ),
      );
    }

    // Case 4: No online notes found (but server is configured and no error)
    if (_onlineNotes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_done_outlined, // Icon for empty state after successful fetch
                size: 60,
                color: theme.hintColor.withOpacity(0.7),
              ),
              const SizedBox(height: 16),
              Text(
                'No online notes found.',
                style: theme.textTheme.titleMedium?.copyWith(color: theme.hintColor),
                textAlign: TextAlign.center,
              ),
              if (widget.serverUrl.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    "Connected to: ${widget.serverUrl}",
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor.withOpacity(0.5)),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      );
    }

    // Case 5: Display list of online notes
    // TODO: Build actual list view for online notes
    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: _onlineNotes.length,
      itemBuilder: (context, index) {
        final note = _onlineNotes[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4.0),
          child: ListTile(
            leading: const Icon(Icons.cloud_queue_outlined), // Icon for each note item
            title: Text(note.title.isEmpty ? "Untitled Online Note" : note.title),
            subtitle: Text("Online - Updated: ${note.updatedAt.toLocal().toString().substring(0, 16)}"),
            // TODO: Add onTap to open note and trailing delete icon
          ),
        );
      },
    );
  }
}
