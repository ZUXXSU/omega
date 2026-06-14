import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/colors.dart';
import '../../../../app/theme/text_styles.dart';

class AdvancedSettingsScreen extends ConsumerStatefulWidget {
  const AdvancedSettingsScreen({super.key});

  @override
  ConsumerState<AdvancedSettingsScreen> createState() => _State();
}

class _State extends ConsumerState<AdvancedSettingsScreen> {
  bool _mvbox = true;
  bool _sentboxWatch = true;
  bool _bccSelf = false;
  bool _autoDownload = true;
  String _downloadSize = '25 MB';
  bool _showClassicMails = false;
  bool _onlyFetchDcMsgs = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Advanced Settings')),
      body: ListView(
        children: [
          _section('Email Server', [
            SwitchListTile(
              title: const Text('DeltaChat Folder (Mvbox)'),
              subtitle: const Text('Use a dedicated folder for Omega messages'),
              value: _mvbox,
              onChanged: (v) => setState(() => _mvbox = v),
            ),
            SwitchListTile(
              title: const Text('Watch Sent Folder'),
              value: _sentboxWatch,
              onChanged: (v) => setState(() => _sentboxWatch = v),
            ),
            SwitchListTile(
              title: const Text('Send Copy to Self'),
              subtitle: const Text('BCC yourself on every message'),
              value: _bccSelf,
              onChanged: (v) => setState(() => _bccSelf = v),
            ),
          ]),
          _section('Downloads', [
            SwitchListTile(
              title: const Text('Auto Download Media'),
              value: _autoDownload,
              onChanged: (v) => setState(() => _autoDownload = v),
            ),
            if (_autoDownload)
              ListTile(
                title: const Text('Max Download Size'),
                subtitle: Text(_downloadSize),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: _showSizeOptions,
              ),
          ]),
          _section('Behavior', [
            SwitchListTile(
              title: const Text('Show Classic Emails'),
              subtitle: const Text('Show non-Omega emails in chat list'),
              value: _showClassicMails,
              onChanged: (v) => setState(() => _showClassicMails = v),
            ),
            SwitchListTile(
              title: const Text('Only Fetch Omega Messages'),
              subtitle: const Text('Reduce server traffic'),
              value: _onlyFetchDcMsgs,
              onChanged: (v) => setState(() => _onlyFetchDcMsgs = v),
            ),
          ]),
          _section('Diagnostics', [
            ListTile(
              leading: const Icon(Icons.network_check_rounded),
              title: const Text('Connectivity Test'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.article_outlined),
              title: const Text('View Logs'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.send_outlined, color: OmegaColors.error),
              title: const Text('Send Report', style: TextStyle(color: OmegaColors.error)),
              subtitle: const Text('Send anonymized logs to support'),
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

  void _showSizeOptions() {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Max Download Size'),
        children: ['5 MB', '10 MB', '25 MB', '50 MB', '100 MB', 'No limit'].map((opt) =>
          RadioListTile<String>(
            value: opt,
            groupValue: _downloadSize,
            title: Text(opt),
            onChanged: (v) {
              setState(() => _downloadSize = v!);
              Navigator.pop(ctx);
            },
          ),
        ).toList(),
      ),
    );
  }
}
