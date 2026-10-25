import 'package:flutter/material.dart';
import 'package:fsf_league_core/fsf_league_core.dart';
import 'package:get/get.dart';

import 'library_controller.dart';

Future<PlayerDraft?> showPlayerFormDialog(
    BuildContext context, {
      required String title,
      PlayerDraft? initial,
      bool showStatus = false,
    }) {
  return showDialog<PlayerDraft>(
    context: context,
    builder: (_) =>
        _PlayerFormDialog(title: title, initial: initial, showStatus: showStatus),
  );
}

class _PlayerFormDialog extends StatefulWidget {
  const _PlayerFormDialog({
    required this.title,
    required this.initial,
    required this.showStatus,
  });

  final String title;
  final PlayerDraft? initial;
  final bool showStatus;

  @override
  State<_PlayerFormDialog> createState() => _PlayerFormDialogState();
}

class _PlayerFormDialogState extends State<_PlayerFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name =
  TextEditingController(text: widget.initial?.name ?? '');
  late final TextEditingController _club =
  TextEditingController(text: widget.initial?.club ?? '');
  late final TextEditingController _price = TextEditingController(
      text: widget.initial == null ? '' : Money.format(widget.initial!.price));
  late Position _position = widget.initial?.position ?? Position.mid;
  late bool _available =
      (widget.initial?.status ?? PlayerStatus.available) == PlayerStatus.available;

  @override
  void dispose() {
    _name.dispose();
    _club.dispose();
    _price.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      PlayerDraft(
        name: _name.text.trim(),
        position: _position,
        club: _club.text.trim(),
        price: Money.parse(_price.text)!,
        status: _available ? PlayerStatus.available : PlayerStatus.unavailable,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _name,
                  autofocus: true,
                  decoration: const InputDecoration(
                      labelText: 'Name', border: OutlineInputBorder()),
                  validator: (v) {
                    final s = (v ?? '').trim();
                    if (s.isEmpty) return 'Required';
                    if (s.length > 40) return 'At most 40 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                SegmentedButton<Position>(
                  segments: [
                    for (final p in Position.values)
                      ButtonSegment(value: p, label: Text(p.code)),
                  ],
                  selected: {_position},
                  onSelectionChanged: (s) => setState(() => _position = s.first),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _club,
                  decoration: const InputDecoration(
                      labelText: 'Club', border: OutlineInputBorder()),
                  validator: (v) {
                    final s = (v ?? '').trim();
                    if (s.isEmpty) return 'Required';
                    if (s.length > 20) return 'At most 20 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _price,
                  keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Price (millions)',
                    helperText: 'For example 7.5',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    final p = Money.parse(v ?? '');
                    return (p == null || p <= 0) ? 'Use a price like 7.5' : null;
                  },
                  onFieldSubmitted: (_) => _submit(),
                ),
                if (widget.showStatus)
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Available'),
                    value: _available,
                    onChanged: (v) => setState(() => _available = v),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }
}

Future<List<PlayerDraft>?> showBulkAddDialog(BuildContext context) {
  return showDialog<List<PlayerDraft>>(
    context: context,
    builder: (_) => const _BulkAddDialog(),
  );
}

class _BulkAddDialog extends StatefulWidget {
  const _BulkAddDialog();

  @override
  State<_BulkAddDialog> createState() => _BulkAddDialogState();
}

class _BulkAddDialogState extends State<_BulkAddDialog> {
  final _text = TextEditingController();
  PlayerListParseResult _result = const PlayerListParseResult([], []);

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final errors = _result.errors;
    final count = _result.drafts.length;
    return AlertDialog(
      title: const Text('Add several players'),
      content: SizedBox(
        width: 560,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('One player per line: name, position, club, price.\n'
                'Example: Saka, MID, ARS, 10.0. Lines copied from a spreadsheet '
                'also work. Lines starting with # are ignored.'),
            const SizedBox(height: 12),
            TextField(
              controller: _text,
              minLines: 8,
              maxLines: 12,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              onChanged: (v) =>
                  setState(() => _result = PlayerListParser.parse(v)),
            ),
            const SizedBox(height: 8),
            if (errors.isNotEmpty)
              Text(
                [...errors.take(6), if (errors.length > 6) '…and ${errors.length - 6} more']
                    .join('\n'),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              )
            else
              Text(count == 0 ? '' : '$count players ready to add.'),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: count == 0 || errors.isNotEmpty
              ? null
              : () => Navigator.pop(context, _result.drafts),
          child: Text(count == 0 ? 'Add' : 'Add $count players'),
        ),
      ],
    );
  }
}

Future<List<LibraryPlayer>?> showLibraryPicker(
    BuildContext context, {
      required Set<String> existingKeys,
    }) {
  return showDialog<List<LibraryPlayer>>(
    context: context,
    builder: (_) => _LibraryPicker(existingKeys: existingKeys),
  );
}

class _LibraryPicker extends StatefulWidget {
  const _LibraryPicker({required this.existingKeys});
  final Set<String> existingKeys;

  @override
  State<_LibraryPicker> createState() => _LibraryPickerState();
}

class _LibraryPickerState extends State<_LibraryPicker> {
  final _lib = Get.find<PlayerLibraryController>();
  final _search = TextEditingController();
  final _selected = <String>{};
  Position? _filter;

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

  bool _inContest(LibraryPlayer p) =>
      widget.existingKeys.contains(PlayerRoster.keyOfParts(p.name, p.club));

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add from library'),
      content: SizedBox(
        width: 560,
        height: 480,
        child: Column(
          children: [
            TextField(
              controller: _search,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search name or club',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('All'),
                  selected: _filter == null,
                  onSelected: (_) => setState(() => _filter = null),
                ),
                for (final p in Position.values)
                  ChoiceChip(
                    label: Text(p.code),
                    selected: _filter == p,
                    onSelected: (_) => setState(() => _filter = p),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Obx(() {
                if (_lib.isLoading.value && _lib.players.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                final error = _lib.loadError.value;
                if (error != null) {
                  return Center(child: Text(error));
                }
                final q = _search.text.trim().toLowerCase();
                final shown = [
                  for (final p in _lib.players)
                    if ((_filter == null || p.position == _filter) &&
                        (q.isEmpty ||
                            p.name.toLowerCase().contains(q) ||
                            p.club.toLowerCase().contains(q)))
                      p,
                ];
                if (shown.isEmpty) {
                  return const Center(
                      child: Text('No players found. Add some in the Players section.'));
                }
                return ListView.builder(
                  itemCount: shown.length,
                  itemBuilder: (context, i) {
                    final p = shown[i];
                    final inContest = _inContest(p);
                    return CheckboxListTile(
                      dense: true,
                      title: Text(p.name),
                      subtitle: Text(
                          '${p.position.code} · ${p.club} · ${Money.format(p.defaultPrice)}'
                              '${inContest ? ' · already in this contest' : ''}'),
                      value: inContest || _selected.contains(p.id),
                      onChanged: inContest
                          ? null
                          : (v) => setState(() {
                        if (v == true) {
                          _selected.add(p.id);
                        } else {
                          _selected.remove(p.id);
                        }
                      }),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: _selected.isEmpty
              ? null
              : () => Navigator.pop(context, [
            for (final p in _lib.players)
              if (_selected.contains(p.id)) p,
          ]),
          child: Text(_selected.isEmpty ? 'Add' : 'Add ${_selected.length}'),
        ),
      ],
    );
  }
}