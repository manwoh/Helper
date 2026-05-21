import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/task.dart';
import '../../services/profile_service.dart';
import '../../widgets/app_shell.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final profileFuture = ProfileService().currentProfile();

    return AppShell(
      title: '找帮手',
      actions: [
        IconButton(
          tooltip: '通知',
          onPressed: () => context.go('/notifications'),
          icon: const Icon(Icons.notifications_none_outlined),
        ),
        IconButton(
          tooltip: '我的资料',
          onPressed: () => context.go('/profile'),
          icon: const Icon(Icons.person_outline),
        ),
      ],
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          FutureBuilder(
            future: profileFuture,
            builder: (context, snapshot) {
              final name = snapshot.data?.displayName ?? '你好';
              return Text(
                '$name，需要什么帮忙？',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              );
            },
          ),
          const SizedBox(height: 6),
          Text(
            '发布需求、找本地帮手、报价聊天并确认完成。',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          _EntryGrid(
            entries: [
              _Entry(
                title: '我要找帮手',
                subtitle: '跑腿、维修、清洁、临时协助',
                icon: Icons.handshake_outlined,
                color: const Color(0xff1976d2),
                onTap: () => context.go('/tasks/new/${TaskKind.help.value}'),
              ),
              _Entry(
                title: '我要找答案',
                subtitle: '学习、职场、电脑手机问题',
                icon: Icons.lightbulb_outline,
                color: const Color(0xff2e7d32),
                onTap: () => context.go('/tasks/new/${TaskKind.answer.value}'),
              ),
              _Entry(
                title: '我要找东西',
                subtitle: '失物、二手、本地线索',
                icon: Icons.search_outlined,
                color: const Color(0xffc77800),
                onTap: () => context.go('/tasks/new/${TaskKind.findItem.value}'),
              ),
              _Entry(
                title: '我要做帮手',
                subtitle: '创建技能资料，浏览附近任务',
                icon: Icons.work_outline,
                color: const Color(0xff6a4fb3),
                onTap: () => context.go('/helper-profile'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Card(
            child: ListTile(
              leading: const Icon(Icons.near_me_outlined),
              title: const Text('浏览附近任务'),
              subtitle: const Text('按分类、地点、最新和加急筛选'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go('/tasks'),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.verified_user_outlined),
              title: const Text('申请认证帮手'),
              subtitle: const Text('提升信任度，后续可接入会员体系'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go('/helper-profile'),
            ),
          ),
        ],
      ),
    );
  }
}

class _EntryGrid extends StatelessWidget {
  const _EntryGrid({required this.entries});

  final List<_Entry> entries;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 560 ? 2 : 1;
        return GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: columns == 2 ? 2.4 : 3.2,
          children: entries.map((entry) => _EntryCard(entry: entry)).toList(),
        );
      },
    );
  }
}

class _EntryCard extends StatelessWidget {
  const _EntryCard({required this.entry});

  final _Entry entry;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: entry.onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: entry.color.withAlpha(31),
                foregroundColor: entry.color,
                child: Icon(entry.icon),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      entry.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(entry.subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _Entry {
  const _Entry({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
}
