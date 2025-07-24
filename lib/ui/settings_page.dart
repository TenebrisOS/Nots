import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  final TextEditingController serverHostController;
  final TextEditingController tokenController;
  final bool initialServerHostingEnabled;
  final ValueChanged<bool> onServerHostingChanged;
  final VoidCallback onSettingsChanged; // To trigger rebuild on OnlineNotesPage

  const SettingsPage({
    super.key,
    required this.serverHostController,
    required this.tokenController,
    required this.initialServerHostingEnabled,
    required this.onServerHostingChanged,
    required this.onSettingsChanged,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late bool _serverHostingEnabled;

  @override
  void initState() {
    super.initState();
    _serverHostingEnabled = widget.initialServerHostingEnabled;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return SafeArea(
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
                          child: Text('Enable Server Hosting',
                              style: theme.textTheme.titleMedium)),
                      Switch(
                        value: _serverHostingEnabled,
                        onChanged: (bool value) {
                          setState(() {
                            _serverHostingEnabled = value;
                          });
                          widget.onServerHostingChanged(value); // Notify parent
                        },
                      ),
                    ]),
                    const SizedBox(height: 12),
                    Text('Server Host Address:',
                        style: _serverHostingEnabled
                            ? theme.textTheme.titleSmall
                            : theme.textTheme.titleSmall
                            ?.copyWith(color: theme.disabledColor)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: widget.serverHostController,
                      enabled: _serverHostingEnabled,
                      decoration: InputDecoration(
                        hintText: _serverHostingEnabled
                            ? 'e.g., https://your-notes-server.com'
                            : 'Enable hosting to set address',
                        border: const OutlineInputBorder(),
                        isDense: true,
                        fillColor: _serverHostingEnabled
                            ? null
                            : theme.disabledColor.withOpacity(0.05),
                        filled: !_serverHostingEnabled,
                      ),
                      onChanged: (value) {
                        widget.onSettingsChanged();
                        // TODO: Save to shared_preferences (debounced)
                      },
                    ),
                    const SizedBox(height: 16),
                    Text('Access Token:',
                        style: _serverHostingEnabled
                            ? theme.textTheme.titleSmall
                            : theme.textTheme.titleSmall
                            ?.copyWith(color: theme.disabledColor)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: widget.tokenController,
                      enabled: _serverHostingEnabled,
                      obscureText: true,
                      decoration: InputDecoration(
                        hintText: _serverHostingEnabled
                            ? 'Enter your access token'
                            : 'Enable hosting to set token',
                        border: const OutlineInputBorder(),
                        isDense: true,
                        fillColor: _serverHostingEnabled
                            ? null
                            : theme.disabledColor.withOpacity(0.05),
                        filled: !_serverHostingEnabled,
                      ),
                      onChanged: (value) {
                        widget.onSettingsChanged();
                        // TODO: Save to secure storage
                      },
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
    );
  }
}
