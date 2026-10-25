import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../shell/admin_nav.dart';
import '../shell/routes.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final nav = Get.find<AdminNav>();
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          _Tile(
            title: 'Contests',
            body: 'View, edit and publish contests.',
            action: 'Open contests',
            onPressed: () => nav.goRoot(contestListRoute()),
          ),
          _Tile(
            title: 'New contest',
            body: 'Set up a match, its times and its rules.',
            action: 'Create',
            onPressed: () => nav.push(contestFormRoute()),
          ),
          _Tile(
            title: 'Player library',
            body: 'Reusable players and default prices.',
            action: 'Open library',
            onPressed: () => nav.goRoot(playerLibraryRoute()),
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.title,
    required this.body,
    required this.action,
    required this.onPressed,
  });

  final String title;
  final String body;
  final String action;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(body),
              const SizedBox(height: 16),
              FilledButton(onPressed: onPressed, child: Text(action)),
            ],
          ),
        ),
      ),
    );
  }
}