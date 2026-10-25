import 'package:flutter/material.dart';
import 'package:fsf_league_admin/features/players/player_dialogues.dart';
import 'package:fsf_league_core/fsf_league_core.dart';
import 'package:get/get.dart';

import 'library_controller.dart';

class PlayerLibraryView extends StatefulWidget {
  const PlayerLibraryView({super.key});

  @override
  State<PlayerLibraryView> createState() => _PlayerLibraryViewState();
}

class _PlayerLibraryViewState extends State<PlayerLibraryView> {
  final _lib = Get.find<PlayerLibraryController>();
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _lib.ensureLoaded();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _add() async {
    final d = await showPlayerFormDialog(context, title: 'Add to library');
    if (d == null) return;
    final error = await _lib.upsertAll([LibraryPlayer.fromDraft(d)]);
    _snack(error ?? 'Saved to the library.');
  }

  Future<void> _bulk() async {
    final drafts = await showBulkAddDialog(context);
    if (drafts == null) return;
    final error = await _lib.upsertAll([for (final d in drafts) LibraryPlayer.fromDraft(d)]);
    _snack(error ?? 'Saved ${drafts.length} players (existing ones were updated).');
  }

  Future<void> _edit(LibraryPlayer p) async {
    final d = await showPlayerFormDialog(context,
        title: 'Edit library player', initial: p.toDraft());
    if (d == null) return;
    final error = await _lib.replace(p, LibraryPlayer.fromDraft(d));
    _snack(error ?? 'Saved.');
  }

  Future<void> _delete(LibraryPlayer p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Remove ${p.name}?'),
        content: const Text('Contests that already use this player are not affected.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Remove')),
        ],
      ),
    );
    if (ok != true) return;
    final error = await _lib.remove(p);
    _snack(error ?? 'Removed.');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Player library', style: Theme.of(context).textTheme.headlineSmall),
              const Spacer(),
              Obx(() => OutlinedButton.icon(
                onPressed: _lib.isLoading.value ? null : _lib.reload,
                icon: const Icon(Icons.refresh),
                label: const Text('Reload'),
              )),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                  onPressed: _bulk,
                  icon: const Icon(Icons.playlist_add),
                  label: const Text('Bulk add')),
              const SizedBox(width: 12),
              FilledButton.icon(
                  onPressed: _add,
                  icon: const Icon(Icons.person_add),
                  label: const Text('Add player')),
            ],
          ),
          const SizedBox(height: 4),
          const Text('Reusable players with default prices. Loaded once; '
              'Reload re-reads up to 500 documents.'),
          const SizedBox(height: 12),
          TextField(
            controller: _search,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Search name or club',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Obx(() {
              if (_lib.isLoading.value && _lib.players.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              final error = _lib.loadError.value;
              if (error != null) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(error),
                      const SizedBox(height: 12),
                      FilledButton(onPressed: _lib.reload, child: const Text('Retry')),
                    ],
                  ),
                );
              }
              final q = _search.text.trim().toLowerCase();
              final shown = [
                for (final p in _lib.players)
                  if (q.isEmpty ||
                      p.name.toLowerCase().contains(q) ||
                      p.club.toLowerCase().contains(q))
                    p,
              ];
              if (_lib.players.isEmpty) {
                return const Center(child: Text('The library is empty. Add players above.'));
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${shown.length} of ${_lib.players.length} players'
                      '${_lib.truncated.value ? ' (only the first 500 are loaded)' : ''}'),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      itemCount: shown.length,
                      itemBuilder: (context, i) {
                        final p = shown[i];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 4),
                          child: ListTile(
                            dense: true,
                            title: Text(p.name),
                            subtitle: Text(
                                '${p.position.code} · ${p.club} · ${Money.format(p.defaultPrice)}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
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
                        );
                      },
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}