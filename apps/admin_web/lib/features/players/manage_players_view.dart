import 'package:flutter/material.dart';
import 'package:fsf_league_admin/features/players/player_dialogues.dart';
import 'package:fsf_league_core/fsf_league_core.dart';
import 'package:get/get.dart';

import '../contests/contest_controller.dart';
import '../shell/admin_nav.dart';
import 'library_controller.dart';

class ManagePlayersView extends StatefulWidget {
  const ManagePlayersView({super.key, required this.contestId});
  final String contestId;

  @override
  State<ManagePlayersView> createState() => _ManagePlayersViewState();
}

class _ManagePlayersViewState extends State<ManagePlayersView> {
  final _store = Get.find<ContestsController>();

  // Edits happen on this copy; nothing is written until Save.
  late Map<String, ContestPlayer> _players;
  final _touched = <String>{}; // new or edited here: candidates for the library
  bool _dirty = false;
  bool _saveToLibrary = true;
  bool _saving = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _players = Map.of(
        _store.byId(widget.contestId)?.players ?? const <String, ContestPlayer>{});
    Get.find<AdminNav>().setGuard(_confirmLeave);
  }

  @override
  void dispose() {
    if (Get.isRegistered<AdminNav>()) Get.find<AdminNav>().clearGuard();
    super.dispose();
  }

  Future<bool> _confirmDiscard() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard unsaved changes?'),
        content: const Text('Your player edits have not been saved.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Keep editing')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Discard')),
        ],
      ),
    );
    return ok ?? false;
  }

  Future<bool> _confirmLeave() async {
    if (!_dirty || !mounted) return true;
    return _confirmDiscard();
  }

  void _note(String message) => setState(() => _message = message);

  void _mutate(void Function() change) => setState(() {
    change();
    _dirty = true;
    _message = null;
  });

  /// Returns how many drafts were skipped (duplicates or the player limit).
  int _addDrafts(List<PlayerDraft> drafts, {required bool markTouched}) {
    final keys = {for (final p in _players.values) PlayerRoster.keyOf(p)};
    var skipped = 0;
    _mutate(() {
      for (final d in drafts) {
        final id = PlayerRoster.nextId(_players.keys);
        final player = d.toPlayer(id);
        if (_players.length >= PlayerRoster.maxPlayers ||
            !keys.add(PlayerRoster.keyOf(player))) {
          skipped++;
          continue;
        }
        _players[id] = player;
        if (markTouched) _touched.add(id);
      }
    });
    return skipped;
  }

  Future<void> _addOne() async {
    final d = await showPlayerFormDialog(context, title: 'Add player');
    if (d == null || !mounted) return;
    if (_addDrafts([d], markTouched: true) > 0) {
      _note('Not added: that name and club is already in the list, '
          'or the ${PlayerRoster.maxPlayers}-player limit is reached.');
    }
  }

  Future<void> _bulk() async {
    final drafts = await showBulkAddDialog(context);
    if (drafts == null || !mounted) return;
    final skipped = _addDrafts(drafts, markTouched: true);
    _note(skipped == 0
        ? 'Added ${drafts.length} players.'
        : 'Added ${drafts.length - skipped}; skipped $skipped '
        '(duplicates or the limit).');
  }

  Future<void> _fromLibrary() async {
    final keys = {for (final p in _players.values) PlayerRoster.keyOf(p)};
    final picked = await showLibraryPicker(context, existingKeys: keys);
    if (picked == null || picked.isEmpty || !mounted) return;
    final skipped =
    _addDrafts([for (final l in picked) l.toDraft()], markTouched: false);
    _note(skipped == 0
        ? 'Added ${picked.length} from the library.'
        : 'Added ${picked.length - skipped}; skipped $skipped.');
  }

  Future<void> _edit(ContestPlayer p) async {
    final d = await showPlayerFormDialog(
      context,
      title: 'Edit player',
      showStatus: true,
      initial: PlayerDraft(
        name: p.name,
        position: p.position,
        club: p.club,
        price: p.price,
        status: p.status,
      ),
    );
    if (d == null || !mounted) return;
    final updated = d.toPlayer(p.id);
    final clash = _players.values.any(
            (o) => o.id != p.id && PlayerRoster.keyOf(o) == PlayerRoster.keyOf(updated));
    if (clash) {
      _note('Another player already has that name and club.');
      return;
    }
    _mutate(() {
      _players[p.id] = updated;
      _touched.add(p.id);
    });
  }

  void _toggleAvailable(ContestPlayer p) => _mutate(() {
    _players[p.id] = PlayerDraft(
      name: p.name,
      position: p.position,
      club: p.club,
      price: p.price,
      status: p.status == PlayerStatus.available
          ? PlayerStatus.unavailable
          : PlayerStatus.available,
    ).toPlayer(p.id);
  });

  void _delete(ContestPlayer p) => _mutate(() {
    _players.remove(p.id);
    _touched.remove(p.id);
  });

  Future<void> _discard() async {
    if (!_dirty || !await _confirmDiscard() || !mounted) return;
    final saved = _store.byId(widget.contestId)?.players ?? const <String, ContestPlayer>{};
    setState(() {
      _players = Map.of(saved);
      _touched.clear();
      _dirty = false;
      _message = null;
    });
  }

  Future<void> _save() async {
    final contest = _store.byId(widget.contestId);
    if (contest == null) return;
    final problems = PlayerRoster.problems(_players);
    if (problems.isNotEmpty) {
      _note(problems.first);
      return;
    }

    setState(() {
      _saving = true;
      _message = null;
    });
    final error = await _store.savePlayers(contest, Map.of(_players));
    if (!mounted) return;
    if (error != null) {
      setState(() {
        _saving = false;
        _message = error;
      });
      return;
    }

    var note = 'Players saved.';
    if (_saveToLibrary && _touched.isNotEmpty) {
      final entries = [
        for (final id in _touched)
          if (_players[id] != null) LibraryPlayer.fromPlayer(_players[id]!),
      ];
      final libError = await Get.find<PlayerLibraryController>().upsertAll(entries);
      if (libError != null) {
        note = 'Players saved, but the library update failed: $libError';
      }
    }
    if (!mounted) return;
    setState(() {
      _saving = false;
      _dirty = false;
      _touched.clear();
      _message = note;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final c = _store.byId(widget.contestId);
      if (c == null) {
        return const Center(child: Text('Contest not found. Go back and reload the list.'));
      }
      final readOnly = c.status != ContestStatus.draft;
      final busy = _saving || _store.busy.value;
      final problems = readOnly
          ? <String>[]
          : ContestValidator.publishProblems(
          c.copyWith(players: _players), DateTime.now());

      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(c.title, style: Theme.of(context).textTheme.headlineSmall),
          Text('${_players.length} of ${PlayerRoster.maxPlayers} players'
              '${_dirty ? ' · unsaved changes' : ''}'),
          if (readOnly)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('This contest is no longer a draft, so players are read-only.'),
            ),
          const SizedBox(height: 16),
          if (!readOnly) ...[
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.icon(
                    onPressed: busy ? null : _addOne,
                    icon: const Icon(Icons.person_add),
                    label: const Text('Add player')),
                OutlinedButton.icon(
                    onPressed: busy ? null : _bulk,
                    icon: const Icon(Icons.playlist_add),
                    label: const Text('Bulk add')),
                OutlinedButton.icon(
                    onPressed: busy ? null : _fromLibrary,
                    icon: const Icon(Icons.library_add),
                    label: const Text('From library')),
              ],
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text('Also save new or edited players to the library'),
              value: _saveToLibrary,
              onChanged: (v) => setState(() => _saveToLibrary = v ?? true),
            ),
          ],
          if (_message != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(_message!),
            ),
          if (!readOnly) ...[
            if (problems.isEmpty)
              const Text('Ready to publish.')
            else ...[
              Text('Before you can publish:',
                  style: Theme.of(context).textTheme.titleSmall),
              for (final p in problems) Text('• $p'),
            ],
          ],
          const SizedBox(height: 16),
          for (final pos in Position.values) _section(c, pos, readOnly),
          if (!readOnly) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                FilledButton(
                  onPressed: busy || !_dirty ? null : _save,
                  child: _saving
                      ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Save players'),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: busy || !_dirty ? null : _discard,
                  child: const Text('Discard changes'),
                ),
              ],
            ),
          ],
        ],
      );
    });
  }

  Widget _section(Contest c, Position pos, bool readOnly) {
    final list = _players.values.where((p) => p.position == pos).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    final available = list.where((p) => p.status == PlayerStatus.available).length;
    final need = c.rules.positions[pos] ?? 0;
    final short = available < need;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${pos.code} · ${list.length} (available $available, need at least $need)',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: short ? Theme.of(context).colorScheme.error : null,
            ),
          ),
          const SizedBox(height: 4),
          if (list.isEmpty)
            const Text('None yet.')
          else
            for (final p in list)
              Card(
                margin: const EdgeInsets.only(bottom: 4),
                child: ListTile(
                  dense: true,
                  title: Text(p.name),
                  subtitle: Text('${p.club} · ${Money.format(p.price)}'),
                  trailing: readOnly
                      ? Chip(
                      label: Text(p.status == PlayerStatus.available
                          ? 'Available'
                          : 'Unavailable'),
                      visualDensity: VisualDensity.compact)
                      : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Tooltip(
                        message: 'Available',
                        child: Switch(
                          value: p.status == PlayerStatus.available,
                          onChanged: (_) => _toggleAvailable(p),
                        ),
                      ),
                      IconButton(
                          tooltip: 'Edit',
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => _edit(p)),
                      IconButton(
                          tooltip: 'Remove',
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _delete(p)),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }
}