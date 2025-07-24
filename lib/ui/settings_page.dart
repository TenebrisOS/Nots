import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  final TextEditingController serverHostController;
  final TextEditingController tokenController;
  final bool initialServerHostingEnabled;
  final ValueChanged<bool> onServerHostingChanged;
  final VoidCallback onSettingsChanged;

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
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 16.0 : 24.0,
          vertical: 20.0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Connectivity Section
            Text(
              'Connectivity',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
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
                        child: Text(
                          'Enable Server Hosting',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.disabledColor,
                          ),
                        ),
                      ),
                      const Switch(
                        value: false,
                        onChanged: null, // Disabled
                      ),
                    ]),
                    const SizedBox(height: 12),
                    Text(
                      'Server Host Address:',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.disabledColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: widget.serverHostController,
                      enabled: false,
                      decoration: InputDecoration(
                        hintText: 'Feature unavailable',
                        border: const OutlineInputBorder(),
                        isDense: true,
                        fillColor: theme.disabledColor.withOpacity(0.05),
                        filled: true,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Access Token:',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.disabledColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: widget.tokenController,
                      enabled: false,
                      obscureText: true,
                      decoration: InputDecoration(
                        hintText: 'Feature unavailable',
                        border: const OutlineInputBorder(),
                        isDense: true,
                        fillColor: theme.disabledColor.withOpacity(0.05),
                        filled: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding:
              const EdgeInsets.only(left: 16.0, top: 4.0, right: 16.0),
              child: Text(
                'This feature is currently unavailable.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.disabledColor,
                ),
              ),
            ),
            const SizedBox(height: 28),
            const Divider(),
            const SizedBox(height: 24),

            // Security Section
            Text(
              'Security',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 1.0,
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(children: [
                  Expanded(
                    child: Text(
                      'Enable End-to-End Encryption',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(color: theme.disabledColor),
                    ),
                  ),
                  const Switch(value: false, onChanged: null),
                ]),
              ),
            ),
            Padding(
              padding:
              const EdgeInsets.only(left: 16.0, top: 4.0, right: 16.0),
              child: Text(
                'This feature is currently unavailable.',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.disabledColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
