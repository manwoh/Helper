import 'package:flutter/material.dart';

import '../../core/formatters.dart';
import '../../services/notification_service.dart';
import '../../widgets/app_shell.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final service = NotificationService();

    return AppShell(
      title: '通知',
      child: StreamBuilder<List<AppNotification>>(
        stream: service.watchNotifications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final notifications = snapshot.data ?? [];
          if (notifications.isEmpty) {
            return const Center(child: Text('暂无通知'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = notifications[index];
              return Card(
                child: ListTile(
                  leading: Icon(
                    item.isRead
                        ? Icons.notifications_none_outlined
                        : Icons.notifications_active_outlined,
                  ),
                  title: Text(item.title),
                  subtitle: Text('${item.body}\n${formatDate(item.createdAt)}'),
                  isThreeLine: true,
                  onTap: item.isRead ? null : () => service.markRead(item.id),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
