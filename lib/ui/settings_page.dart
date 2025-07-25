// lib/ui/settings_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SettingsPage extends StatefulWidget {
  final TextEditingController serverHostController;
  final TextEditingController tokenController;
  final bool initialServerHostingEnabled;
  final bool isCheckingStatus;
  final bool isOnlineServiceVerified;
  final ValueChanged<bool> onServerHostingChanged;
  final VoidCallback onSettingsChanged; // Called by text field listeners in HomeScreen

  static const bool SECURITY_FEATURES_ENABLED = false;

  const SettingsPage({
    super.key,
    required this.serverHostController,
    required this.tokenController,
    required this.initialServerHostingEnabled,
    required this.isCheckingStatus,
    required this.isOnlineServiceVerified,
    required this.onServerHostingChanged,
    required this.onSettingsChanged,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // Listeners are managed in HomeScreen as they trigger logic there.

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    final bool connectivityFieldsEnabled = widget.initialServerHostingEnabled;
    final bool showStatusIndicator = widget.initialServerHostingEnabled &&
        (widget.isCheckingStatus ||
            (widget.serverHostController.text.isNotEmpty &&
                widget.tokenController.text.isNotEmpty));


    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 16.0 : 24.0, vertical: 20.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Connectivity',
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Card(
              elevation: 1.0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Enable Online Sync',
                            style: theme.textTheme.titleMedium,
                          ),
                        ),
                        Switch(
                          value: widget.initialServerHostingEnabled,
                          onChanged: widget.onServerHostingChanged,
                        ),
                      ],
                    ),
                    if (showStatusIndicator) ...[
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (widget.isCheckingStatus)
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          else // Only show icon if not checking and fields were entered
                            Icon(
                              widget.isOnlineServiceVerified ? Icons.check_circle_outline : Icons.error_outline,
                              color: widget.isOnlineServiceVerified ? Colors.green.shade600 : theme.colorScheme.error,
                              size: 18,
                            ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.isCheckingStatus
                                  ? "Verifying connection..."
                                  : widget.isOnlineServiceVerified
                                  ? "Online service connected."
                                  : "Connection failed. Check details or server status.",
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: widget.isCheckingStatus
                                    ? theme.hintColor
                                    : widget.isOnlineServiceVerified
                                    ? Colors.green.shade700
                                    : theme.colorScheme.error,
                                fontStyle: widget.isCheckingStatus ? FontStyle.italic : FontStyle.normal,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ] else if (widget.initialServerHostingEnabled && (widget.serverHostController.text.isEmpty || widget.tokenController.text.isEmpty)) ...[
                      const SizedBox(height: 10),
                      Text(
                        "Enter server address and token to connect.",
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                      )
                    ],
                    const SizedBox(height: 12),
                    Text(
                      'Server Host Address:',
                      style: connectivityFieldsEnabled
                          ? theme.textTheme.titleSmall
                          : theme.textTheme.titleSmall?.copyWith(color: theme.disabledColor),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: widget.serverHostController,
                      enabled: connectivityFieldsEnabled,
                      decoration: InputDecoration(
                        hintText: connectivityFieldsEnabled ? 'e.g., https://your-server.com' : 'Enable online sync first',
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      keyboardType: TextInputType.url,
                      // onChanged handled by listener in HomeScreen via widget.onSettingsChanged
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Access Token:',
                      style: connectivityFieldsEnabled
                          ? theme.textTheme.titleSmall
                          : theme.textTheme.titleSmall?.copyWith(color: theme.disabledColor),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: widget.tokenController,
                      enabled: connectivityFieldsEnabled,
                      decoration: InputDecoration(
                        hintText: connectivityFieldsEnabled ? 'Your secret access token' : 'Enable online sync first',
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      obscureText: true,
                      inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
                      // onChanged handled by listener in HomeScreen via widget.onSettingsChanged
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text('Security',
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Card(
              elevation: 1.0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              child: Padding(
                padding: const EdgeInsets.all(16.0), // <-- This was the line it got cut off before
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Example Security Feature 1: Local Data Encryption
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Encrypt Local Notes',
                            style: SettingsPage.SECURITY_FEATURES_ENABLED
                                ? theme.textTheme.titleMedium
                                : theme.textTheme.titleMedium?.copyWith(color: theme.disabledColor),
                          ),
                        ),
                        Switch(
                          value: false, // Replace with actual state variable if implemented
                          onChanged: SettingsPage.SECURITY_FEATURES_ENABLED
                              ? (bool value) {
                            // setState(() { /* Update local encryption state */ });
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Local encryption setting changed (mock)."))
                            );
                          }
                              : null, // Disabled if SECURITY_FEATURES_ENABLED is false
                        ),
                      ],
                    ),
                    if (!SettingsPage.SECURITY_FEATURES_ENABLED)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0, bottom: 8.0),
                        child: Text(
                          "Local data encryption is currently unavailable.",
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                        ),
                      ),
                    const Divider(height: 20),
                    // Example Security Feature 2: Biometric Lock
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Enable Biometric Lock',
                            style: SettingsPage.SECURITY_FEATURES_ENABLED
                                ? theme.textTheme.titleMedium
                                : theme.textTheme.titleMedium?.copyWith(color: theme.disabledColor),
                          ),
                        ),
                        Switch(
                          value: false, // Replace with actual state variable
                          onChanged: SettingsPage.SECURITY_FEATURES_ENABLED
                              ? (bool value) {
                            // setState(() { /* Update biometric lock state */ });
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Biometric lock setting changed (mock)."))
                            );
                          }
                              : null,
                        ),
                      ],
                    ),
                    if (!SettingsPage.SECURITY_FEATURES_ENABLED)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          "Biometric lock feature is currently unavailable.",
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                        ),
                      ),
                    // Add more security features here as needed
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

