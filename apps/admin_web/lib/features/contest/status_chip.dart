import 'package:flutter/material.dart';
import 'package:fsf_league_core/fsf_league_core.dart';

class StatusChip extends StatelessWidget {
  const StatusChip(this.contest, {super.key});
  final Contest contest;

  @override
  Widget build(BuildContext context) {
    final label = contest.displayLabel(DateTime.now());
    final scheme = Theme.of(context).colorScheme;
    final color = switch (contest.status) {
      ContestStatus.draft => scheme.surfaceContainerHighest,
      ContestStatus.cancelled => scheme.errorContainer,
      ContestStatus.published =>
      label == 'Open' ? scheme.primaryContainer : scheme.tertiaryContainer,
      _ => scheme.secondaryContainer,
    };
    return Chip(
      label: Text(label),
      backgroundColor: color,
      visualDensity: VisualDensity.compact,
    );
  }
}