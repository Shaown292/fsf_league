import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fsf_league_core/fsf_league_core.dart';
import 'package:get/get.dart';

import '../../core/formate.dart';
import '../shell/admin_nav.dart';
import '../shell/routes.dart';
import 'contest_controller.dart';
import 'status_chip.dart';

class ContestDetailView extends GetView<ContestsController> {
  const ContestDetailView({super.key, required this.contestId});
  final String contestId;

  Future<bool> _confirm(BuildContext context, String title, String message) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Keep')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Confirm')),
        ],
      ),
    );
    return ok ?? false;
  }

  Future<void> _do(
      BuildContext context,
      Future<String?> Function() action,
      String success,
      ) async {
    final error = await action();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(error ?? success)));
  }

  @override
  Widget build(BuildContext context) {
    final nav = Get.find<AdminNav>();
    return Obx(() {
      final c = controller.byId(contestId);
      if (c == null) {
        return const Center(
            child: Text('Contest not found. It may have been deleted.'));
      }

      final now = DateTime.now();
      final busy = controller.busy.value;
      final isDraft = c.status == ContestStatus.draft;
      final isPublished = c.status == ContestStatus.published;
      final canLock = isPublished && !now.isBefore(c.opensAt) && now.isBefore(c.deadlineAt);
      final canUnpublish = isPublished && now.isBefore(c.opensAt);
      final problems = isDraft ? ContestValidator.publishProblems(c, now) : <String>[];

      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Row(
            children: [
              Expanded(
                  child: Text(c.title,
                      style: Theme.of(context).textTheme.headlineSmall)),
              StatusChip(c),
            ],
          ),
          const SizedBox(height: 4),
          Text('${c.homeTeam} vs ${c.awayTeam}'),
          const SizedBox(height: 16),
          _Info('Kickoff', formatDateTime(c.matchAt)),
          _Info('Entries open', formatDateTime(c.opensAt)),
          _Info('Deadline', formatDateTime(c.deadlineAt)),
          Text('Times shown in ${timezoneLabel()}',
              style: Theme.of(context).textTheme.bodySmall),
          const Divider(height: 32),
          _Info('Budget', Money.format(c.rules.budget)),
          _Info('Squad', '${c.rules.squadSize} players: ${Position.values
                  .map((p) => '${c.rules.positions[p] ?? 0} ${p.code}')
                  .join(' · ')}'),
          _Info('Captain', '×${c.rules.captainMultiplier}'),
          _Info('Max per club',
              c.rules.maxPerClub == 0 ? 'No limit' : '${c.rules.maxPerClub}'),
          _Info('Version', '${c.version}'),
          const Divider(height: 32),
          Text('Players (${c.players.length})',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (c.players.isEmpty)
            const Text('No players yet. Player management arrives in Phase 6.')
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final p in c.players.values)
                  Chip(
                    label: Text(
                        '${p.name} · ${p.position.code} · ${Money.format(p.price)}'),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
          if (isDraft) ...[
            const SizedBox(height: 16),
            if (problems.isEmpty)
              const Text('Ready to publish.')
            else ...[
              Text('Before you can publish:',
                  style: Theme.of(context).textTheme.titleSmall),
              for (final p in problems) Text('• $p'),
            ],
          ],
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              if (isDraft || isPublished)
                OutlinedButton(
                  onPressed: busy
                      ? null
                      : () => nav.push(contestFormRoute(contestId: c.id)),
                  child: const Text('Edit details'),
                ),
              if (isDraft && kDebugMode)
                OutlinedButton(
                  onPressed: busy
                      ? null
                      : () => _do(context, () => controller.loadSamplePlayers(c),
                      'Sample players loaded.'),
                  child: const Text('Load sample players (debug)'),
                ),
              if (isDraft)
                FilledButton(
                  onPressed: busy || problems.isNotEmpty
                      ? null
                      : () async {
                    if (await _confirm(context, 'Publish this contest?',
                        'Players will see it in the app.') &&
                        context.mounted) {
                      await _do(context, () => controller.publish(c),
                          'Published.');
                    }
                  },
                  child: const Text('Publish'),
                ),
              if (canUnpublish)
                OutlinedButton(
                  onPressed: busy
                      ? null
                      : () => _do(context, () => controller.unpublish(c),
                      'Moved back to draft.'),
                  child: const Text('Unpublish'),
                ),
              if (canLock)
                OutlinedButton(
                  onPressed: busy
                      ? null
                      : () async {
                    if (await _confirm(context, 'Lock entries now?',
                        'No one can create or change a team after this.') &&
                        context.mounted) {
                      await _do(context, () => controller.lockNow(c),
                          'Entries are locked.');
                    }
                  },
                  child: const Text('Lock now'),
                ),
              if (isPublished)
                OutlinedButton(
                  onPressed: busy
                      ? null
                      : () async {
                    if (await _confirm(context, 'Cancel this contest?',
                        'It cannot be restarted. Players will see it as cancelled.') &&
                        context.mounted) {
                      await _do(context, () => controller.cancel(c),
                          'Contest cancelled.');
                    }
                  },
                  child: const Text('Cancel contest'),
                ),
              if (isDraft)
                TextButton(
                  onPressed: busy
                      ? null
                      : () async {
                    if (await _confirm(context, 'Delete this draft?',
                        'This cannot be undone.') &&
                        context.mounted) {
                      final error = await controller.deleteDraft(c);
                      if (!context.mounted) return;
                      if (error == null) {
                        nav.pop();
                      } else {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(SnackBar(content: Text(error)));
                      }
                    }
                  },
                  child: const Text('Delete draft'),
                ),
            ],
          ),
        ],
      );
    });
  }
}

class _Info extends StatelessWidget {
  const _Info(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              width: 120,
              child: Text(label, style: Theme.of(context).textTheme.bodySmall)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}