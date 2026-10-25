import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/formate.dart';
import '../shell/admin_nav.dart';
import '../shell/routes.dart';
import 'contest_controller.dart';
import 'status_chip.dart';

class ContestListView extends GetView<ContestsController> {
  const ContestListView({super.key});

  @override
  Widget build(BuildContext context) {
    final nav = Get.find<AdminNav>();
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Contests', style: Theme.of(context).textTheme.headlineSmall),
              const Spacer(),
              Obx(
                    () => OutlinedButton.icon(
                  onPressed: controller.isLoading.value ? null : controller.load,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reload'),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: () => nav.push(contestFormRoute()),
                icon: const Icon(Icons.add),
                label: const Text('New contest'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text('Newest 25 by kickoff. Reloading reads up to 25 documents.'),
          Obx(() => controller.skipped.value == 0
              ? const SizedBox.shrink()
              : Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '${controller.skipped.value} contest(s) could not be read.',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          )),
          const SizedBox(height: 16),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.contests.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              final error = controller.loadError.value;
              if (error != null) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(error),
                      const SizedBox(height: 12),
                      FilledButton(
                          onPressed: controller.load, child: const Text('Retry')),
                    ],
                  ),
                );
              }
              if (controller.contests.isEmpty) {
                return const Center(
                    child: Text('No contests yet. Create your first one.'));
              }
              return ListView.separated(
                itemCount: controller.contests.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final c = controller.contests[i];
                  return Card(
                    child: ListTile(
                      title: Text(c.title),
                      subtitle: Text(
                          '${c.homeTeam} vs ${c.awayTeam} · ${formatDateTime(c.matchAt)}'
                              ' · ${c.players.length} players'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          StatusChip(c),
                          const SizedBox(width: 8),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                      onTap: () => nav.push(contestDetailRoute(c.id)),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}