import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/text_styles.dart';

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() => _State();
}

class _State extends ConsumerState<NotificationSettingsScreen> {
  bool _chatNotifications = true;
  bool _groupNotifications = true;
  bool _sound = true;
  bool _vibration = true;
  bool _preview = true;
  bool _badge = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: ListView(
        children: [
          _Section(
            title: 'Messages',
            children: [
              SwitchListTile(
                title: const Text('Chat Notifications'),
                subtitle: const Text('New messages from individual chats'),
                value: _chatNotifications,
                onChanged: (v) => setState(() => _chatNotifications = v),
              ),
              SwitchListTile(
                title: const Text('Group Notifications'),
                subtitle: const Text('New messages from group chats'),
                value: _groupNotifications,
                onChanged: (v) => setState(() => _groupNotifications = v),
              ),
            ],
          ),
          _Section(
            title: 'Alerts',
            children: [
              SwitchListTile(
                title: const Text('Sound'),
                value: _sound,
                onChanged: (v) => setState(() => _sound = v),
              ),
              SwitchListTile(
                title: const Text('Vibration'),
                value: _vibration,
                onChanged: (v) => setState(() => _vibration = v),
              ),
              SwitchListTile(
                title: const Text('Message Preview'),
                subtitle: const Text('Show content in notification'),
                value: _preview,
                onChanged: (v) => setState(() => _preview = v),
              ),
              SwitchListTile(
                title: const Text('Badge Count'),
                subtitle: const Text('Show unread count on app icon'),
                value: _badge,
                onChanged: (v) => setState(() => _badge = v),
              ),
            ],
          ),
          _Section(
            title: 'Do Not Disturb',
            children: [
              ListTile(
                title: const Text('Mute Schedule'),
                subtitle: const Text('Not set'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
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
}
