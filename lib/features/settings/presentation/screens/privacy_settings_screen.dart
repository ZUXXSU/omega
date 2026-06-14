import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/text_styles.dart';

class PrivacySettingsScreen extends ConsumerStatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  ConsumerState<PrivacySettingsScreen> createState() => _State();
}

class _State extends ConsumerState<PrivacySettingsScreen> {
  bool _readReceipts = true;
  bool _typingIndicators = true;
  bool _biometric = false;
  bool _screenSecurity = false;
  String _lastSeen = 'Everyone';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy & Security')),
      body: ListView(
        children: [
          _section('Privacy', [
            SwitchListTile(
              title: const Text('Read Receipts'),
              subtitle: const Text('Let others know when you\'ve read their messages'),
              value: _readReceipts,
              onChanged: (v) => setState(() => _readReceipts = v),
            ),
            SwitchListTile(
              title: const Text('Typing Indicators'),
              subtitle: const Text('Show when you\'re typing'),
              value: _typingIndicators,
              onChanged: (v) => setState(() => _typingIndicators = v),
            ),
            ListTile(
              title: const Text('Last Seen'),
              subtitle: Text(_lastSeen),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: _showLastSeenOptions,
            ),
          ]),
          _section('Security', [
            SwitchListTile(
              title: const Text('Biometric Lock'),
              subtitle: const Text('Require fingerprint or face to open'),
              value: _biometric,
              onChanged: (v) => setState(() => _biometric = v),
            ),
            SwitchListTile(
              title: const Text('Screen Security'),
              subtitle: const Text('Block screenshots and app switcher preview'),
              value: _screenSecurity,
              onChanged: (v) => setState(() => _screenSecurity = v),
            ),
          ]),
          _section('Contacts', [
            ListTile(
              title: const Text('Blocked Contacts'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {},
            ),
          ]),
          _section('Data', [
            ListTile(
              title: const Text('Clear Local Data'),
              subtitle: const Text('Delete cached media and messages'),
              trailing: const Icon(Icons.delete_outline_rounded),
              onTap: _confirmClearData,
            ),
            ListTile(
              title: const Text('Export Keys'),
              subtitle: const Text('Backup your encryption keys'),
              trailing: const Icon(Icons.download_outlined),
              onTap: () {},
            ),
          ]),
        ],
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(title.toUpperCase(), style: OmegaTextStyles.labelSmall.copyWith(letterSpacing: 1.2)),
        ),
        ...children,
      ],
    );
  }

  void _showLastSeenOptions() {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Last Seen'),
        children: ['Everyone', 'Contacts', 'Nobody'].map((opt) =>
          RadioListTile<String>(
            value: opt,
            groupValue: _lastSeen,
            title: Text(opt),
            onChanged: (v) {
              setState(() => _lastSeen = v!);
              Navigator.pop(ctx);
            },
          ),
        ).toList(),
      ),
    );
  }

  void _confirmClearData() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Local Data'),
        content: const Text('This will delete cached media. Messages will be re-downloaded from your email server.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Clear')),
        ],
      ),
    );
  }
}
