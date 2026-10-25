import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fsf_league_core/fsf_league_core.dart';
import 'package:get/get.dart';

import '../../core/admin_failure.dart';
import '../../core/formate.dart';
import '../shell/admin_nav.dart';
import '../shell/routes.dart';
import 'contest_controller.dart';

// A plain StatefulWidget owns the text controllers and disposes them.
class ContestFormView extends StatefulWidget {
  const ContestFormView({super.key, this.contestId});
  final String? contestId;

  @override
  State<ContestFormView> createState() => _ContestFormViewState();
}

class _ContestFormViewState extends State<ContestFormView> {
  final _formKey = GlobalKey<FormState>();
  final _store = Get.find<ContestsController>();
  late final Contest? _existing;

  late final TextEditingController _title;
  late final TextEditingController _home;
  late final TextEditingController _away;
  late final TextEditingController _budget;
  late final TextEditingController _squad;
  late final TextEditingController _gk;
  late final TextEditingController _def;
  late final TextEditingController _mid;
  late final TextEditingController _fwd;
  late final TextEditingController _maxPerClub;

  late DateTime _opensAt;
  late DateTime _deadlineAt;
  late DateTime _matchAt;
  int _captainMultiplier = 2;

  String? _error;
  bool _saving = false;

  bool get _locked =>
      _existing != null && _existing.status != ContestStatus.draft;

  @override
  void initState() {
    super.initState();
    final id = widget.contestId;
    _existing = id == null ? null : _store.byId(id);

    final e = _existing;
    final rules = e?.rules ?? ContestRules.standard5;
    final n = DateTime.now();
    final defaultMatch = DateTime(n.year, n.month, n.day + 1, 20);

    _title = TextEditingController(text: e?.title ?? '');
    _home = TextEditingController(text: e?.homeTeam ?? '');
    _away = TextEditingController(text: e?.awayTeam ?? '');
    _budget = TextEditingController(text: Money.format(rules.budget));
    _squad = TextEditingController(text: '${rules.squadSize}');
    _gk = TextEditingController(text: '${rules.positions[Position.gk] ?? 0}');
    _def = TextEditingController(text: '${rules.positions[Position.def] ?? 0}');
    _mid = TextEditingController(text: '${rules.positions[Position.mid] ?? 0}');
    _fwd = TextEditingController(text: '${rules.positions[Position.fwd] ?? 0}');
    _maxPerClub = TextEditingController(text: '${rules.maxPerClub}');
    _captainMultiplier = rules.captainMultiplier;

    _matchAt = e?.matchAt.toLocal() ?? defaultMatch;
    _deadlineAt = e?.deadlineAt.toLocal() ??
        defaultMatch.subtract(const Duration(hours: 1));
    _opensAt = e?.opensAt.toLocal() ??
        DateTime(n.year, n.month, n.day, n.hour, n.minute);
  }

  @override
  void dispose() {
    for (final c in [
      _title, _home, _away, _budget, _squad, _gk, _def, _mid, _fwd, _maxPerClub,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  int? _int(TextEditingController c) => int.tryParse(c.text.trim());

  Contest? _build() {
    final budget = Money.parse(_budget.text);
    final squad = _int(_squad);
    final gk = _int(_gk);
    final def = _int(_def);
    final mid = _int(_mid);
    final fwd = _int(_fwd);
    final maxPerClub = _int(_maxPerClub);
    if ([budget, squad, gk, def, mid, fwd, maxPerClub].contains(null)) return null;

    return Contest(
      id: _existing?.id ?? '',
      title: _title.text.trim(),
      homeTeam: _home.text.trim(),
      awayTeam: _away.text.trim(),
      matchAt: _matchAt,
      opensAt: _opensAt,
      deadlineAt: _deadlineAt,
      status: _existing?.status ?? ContestStatus.draft,
      version: _existing?.version ?? 0,
      rules: ContestRules(
        budget: budget!,
        squadSize: squad!,
        positions: {
          Position.gk: gk!,
          Position.def: def!,
          Position.mid: mid!,
          Position.fwd: fwd!,
        },
        captainMultiplier: _captainMultiplier,
        maxPerClub: maxPerClub!,
      ),
      players: _existing?.players ?? const <String, ContestPlayer>{},
    );
  }

  void _applyPreset() {
    setState(() {
      _budget.text = '50.0';
      _squad.text = '5';
      _gk.text = '1';
      _def.text = '2';
      _mid.text = '1';
      _fwd.text = '1';
      _captainMultiplier = 2;
      _maxPerClub.text = '0';
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final built = _build();
    if (built == null) {
      setState(() => _error = 'Check the numbers in the form.');
      return;
    }
    final problems = ContestValidator.detailsProblems(built);
    if (problems.isNotEmpty) {
      setState(() => _error = problems.join('\n'));
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    final nav = Get.find<AdminNav>();
    try {
      if (_existing == null) {
        final created = await _store.create(built);
        nav.pop();
        nav.push(contestDetailRoute(created.id));
      } else {
        await _store.saveDetails(built, expectedVersion: _existing.version);
        nav.pop();
      }
    } on AdminFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _num(
      String label,
      TextEditingController c, {
        bool enabled = true,
        String? helper,
      }) {
    return TextFormField(
      controller: c,
      enabled: enabled,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
          labelText: label, helperText: helper, border: const OutlineInputBorder()),
      onChanged: (_) => setState(() {}),
      validator: (v) =>
      int.tryParse((v ?? '').trim()) == null ? 'Enter a number' : null,
    );
  }

  Widget _text(String label, TextEditingController c, {bool enabled = true}) {
    return TextFormField(
      controller: c,
      enabled: enabled,
      decoration:
      InputDecoration(labelText: label, border: const OutlineInputBorder()),
      validator: (v) => (v ?? '').trim().isEmpty ? 'Required' : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.contestId != null && _existing == null) {
      return const Center(
          child: Text('Contest not found. Go back and reload the list.'));
    }

    final total = (_int(_gk) ?? 0) + (_int(_def) ?? 0) + (_int(_mid) ?? 0) + (_int(_fwd) ?? 0);
    final squad = _int(_squad) ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Align(
        alignment: Alignment.topLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_locked)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: Text(
                      'This contest is published. Only the title, kickoff and '
                          'deadline can change.',
                    ),
                  ),
                _text('Title', _title),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _text('Home team', _home, enabled: !_locked)),
                    const SizedBox(width: 16),
                    Expanded(child: _text('Away team', _away, enabled: !_locked)),
                  ],
                ),
                const SizedBox(height: 24),
                Text('Times use your browser time zone (${timezoneLabel()}) '
                    'and are stored in UTC.'),
                const SizedBox(height: 8),
                _DateTimeField(
                  label: 'Entries open',
                  value: _opensAt,
                  enabled: !_locked,
                  onChanged: (v) => setState(() => _opensAt = v),
                ),
                const SizedBox(height: 16),
                _DateTimeField(
                  label: 'Entry deadline',
                  value: _deadlineAt,
                  onChanged: (v) => setState(() => _deadlineAt = v),
                ),
                const SizedBox(height: 16),
                _DateTimeField(
                  label: 'Kickoff',
                  value: _matchAt,
                  onChanged: (v) => setState(() => _matchAt = v),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Text('Rules', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(width: 12),
                    if (!_locked)
                      ActionChip(
                          label: const Text('Standard 5-player'),
                          onPressed: _applyPreset),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _budget,
                  enabled: !_locked,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Budget (millions)',
                    helperText: 'For example 50.0',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => Money.parse(v ?? '') == null
                      ? 'Use a format like 50.0'
                      : null,
                ),
                const SizedBox(height: 16),
                _num('Squad size', _squad, enabled: !_locked),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _num('GK', _gk, enabled: !_locked)),
                    const SizedBox(width: 8),
                    Expanded(child: _num('DEF', _def, enabled: !_locked)),
                    const SizedBox(width: 8),
                    Expanded(child: _num('MID', _mid, enabled: !_locked)),
                    const SizedBox(width: 8),
                    Expanded(child: _num('FWD', _fwd, enabled: !_locked)),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Positions total $total, squad size $squad',
                    style: TextStyle(
                      color: total == squad
                          ? null
                          : Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Captain multiplier'),
                    const SizedBox(width: 16),
                    SegmentedButton<int>(
                      segments: const [
                        ButtonSegment(value: 1, label: Text('1×')),
                        ButtonSegment(value: 2, label: Text('2×')),
                        ButtonSegment(value: 3, label: Text('3×')),
                      ],
                      selected: {_captainMultiplier},
                      onSelectionChanged: _locked
                          ? null
                          : (s) => setState(() => _captainMultiplier = s.first),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _num('Max players per club', _maxPerClub,
                    enabled: !_locked, helper: '0 means no limit'),
                const SizedBox(height: 24),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(_error!,
                        style:
                        TextStyle(color: Theme.of(context).colorScheme.error)),
                  ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton(
                    onPressed: _saving ? null : _submit,
                    child: _saving
                        ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(_existing == null ? 'Create draft' : 'Save changes'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DateTimeField extends StatelessWidget {
  const _DateTimeField({
    required this.label,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final String label;
  final DateTime value;
  final ValueChanged<DateTime> onChanged;
  final bool enabled;

  Future<void> _pick(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: value,
      firstDate: DateTime(2024),
      lastDate: DateTime(2100),
    );
    if (date == null || !context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(value),
    );
    if (time == null) return;
    onChanged(DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? () => _pick(context) : null,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          enabled: enabled,
          suffixIcon: const Icon(Icons.calendar_today),
        ),
        child: Text(formatDateTime(value)),
      ),
    );
  }
}