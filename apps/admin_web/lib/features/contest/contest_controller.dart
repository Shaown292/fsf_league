import 'package:fsf_league_core/fsf_league_core.dart';
import 'package:get/get.dart';

import '../../core/admin_failure.dart';
import '../../data/contest_repository.dart';
import '../../data/sample_players.dart';

/// Local cache of the newest contests. Loaded once; every admin action
/// updates it in place, so screens never need to re-read.
class ContestsController extends GetxController {
  ContestsController(this._repo);
  final ContestRepository _repo;

  final contests = <Contest>[].obs;
  final isLoading = false.obs;
  final loadError = RxnString();
  final skipped = 0.obs;
  final busy = false.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    if (isLoading.value) return;
    isLoading.value = true;
    loadError.value = null;
    try {
      final page = await _repo.list();
      contests.assignAll(page.contests);
      skipped.value = page.skipped;
    } on AdminFailure catch (e) {
      loadError.value = e.message;
    } finally {
      isLoading.value = false;
    }
  }

  Contest? byId(String id) {
    for (final c in contests) {
      if (c.id == id) return c;
    }
    return null;
  }

  void _upsert(Contest c) {
    final i = contests.indexWhere((x) => x.id == c.id);
    if (i >= 0) {
      contests[i] = c;
    } else {
      contests.add(c);
    }
    contests.sort((a, b) => b.matchAt.compareTo(a.matchAt));
    contests.refresh();
  }

  // The form shows errors itself, so these two throw AdminFailure.
  Future<Contest> create(Contest draft) async {
    busy.value = true;
    try {
      final created = await _repo.create(draft);
      _upsert(created);
      return created;
    } finally {
      busy.value = false;
    }
  }

  Future<Contest> saveDetails(Contest edited, {required int expectedVersion}) async {
    busy.value = true;
    try {
      final saved =
      await _repo.saveDetails(edited, expectedVersion: expectedVersion);
      _upsert(saved);
      return saved;
    } finally {
      busy.value = false;
    }
  }

  // Detail-page actions return an error message, or null on success.
  Future<String?> _run(Future<Contest> Function() action) async {
    busy.value = true;
    try {
      _upsert(await action());
      return null;
    } on AdminFailure catch (e) {
      return e.message;
    } finally {
      busy.value = false;
    }
  }

  Future<String?> publish(Contest c) => _run(() =>
      _repo.transition(c.id, ContestStatus.published, expectedVersion: c.version));

  Future<String?> unpublish(Contest c) => _run(() =>
      _repo.transition(c.id, ContestStatus.draft, expectedVersion: c.version));

  Future<String?> cancel(Contest c) => _run(() =>
      _repo.transition(c.id, ContestStatus.cancelled, expectedVersion: c.version));

  Future<String?> lockNow(Contest c) =>
      _run(() => _repo.lockNow(c.id, expectedVersion: c.version));

  Future<String?> loadSamplePlayers(Contest c) => _run(() => _repo.replacePlayers(
      c.id, samplePlayers(), expectedVersion: c.version));

  Future<String?> deleteDraft(Contest c) async {
    busy.value = true;
    try {
      await _repo.deleteDraft(c.id, expectedVersion: c.version);
      contests.removeWhere((x) => x.id == c.id);
      return null;
    } on AdminFailure catch (e) {
      return e.message;
    } finally {
      busy.value = false;
    }
  }
}