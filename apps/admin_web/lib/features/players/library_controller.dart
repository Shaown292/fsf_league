import 'package:fsf_league_core/fsf_league_core.dart';
import 'package:get/get.dart';

import '../../core/admin_failure.dart';
import '../../data/player_library_repository.dart';

class PlayerLibraryController extends GetxController {
  PlayerLibraryController(this._repo);
  final PlayerLibraryRepository _repo;

  static const _limit = 500;

  final players = <LibraryPlayer>[].obs;
  final isLoading = false.obs;
  final loaded = false.obs;
  final loadError = RxnString();
  final truncated = false.obs;
  final busy = false.obs;

  Future<void> ensureLoaded() async {
    if (loaded.value || isLoading.value) return;
    await reload();
  }

  Future<void> reload() async {
    if (isLoading.value) return;
    isLoading.value = true;
    loadError.value = null;
    try {
      final list = await _repo.list(limit: _limit);
      players.assignAll(_sorted(list));
      truncated.value = list.length >= _limit;
      loaded.value = true;
    } on AdminFailure catch (e) {
      loadError.value = e.message;
    } finally {
      isLoading.value = false;
    }
  }

  List<LibraryPlayer> _sorted(Iterable<LibraryPlayer> list) =>
      list.toList()..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

  /// Keeps the local copy in step with writes. If the library was never
  /// loaded there is nothing to merge into; the next load reads everything.
  void _merge(List<LibraryPlayer> add, {String? removeId}) {
    if (!loaded.value) return;
    final map = {for (final p in players) p.id: p};
    if (removeId != null) map.remove(removeId);
    for (final p in add) {
      map[p.id] = p;
    }
    players.assignAll(_sorted(map.values));
  }

  Future<String?> upsertAll(List<LibraryPlayer> list) async {
    busy.value = true;
    try {
      await _repo.upsertAll(list);
      _merge(list);
      return null;
    } on AdminFailure catch (e) {
      return e.message;
    } finally {
      busy.value = false;
    }
  }

  /// Editing a name or club changes the id, so the old document is removed.
  Future<String?> replace(LibraryPlayer old, LibraryPlayer updated) async {
    final idChanged = updated.id != old.id;
    if (idChanged && players.any((p) => p.id == updated.id)) {
      return 'A library player with that name and club already exists.';
    }
    busy.value = true;
    try {
      await _repo.upsertAll([updated]);
      if (idChanged) await _repo.delete(old.id);
      _merge([updated], removeId: idChanged ? old.id : null);
      return null;
    } on AdminFailure catch (e) {
      return e.message;
    } finally {
      busy.value = false;
    }
  }

  Future<String?> remove(LibraryPlayer p) async {
    busy.value = true;
    try {
      await _repo.delete(p.id);
      _merge(const [], removeId: p.id);
      return null;
    } on AdminFailure catch (e) {
      return e.message;
    } finally {
      busy.value = false;
    }
  }
}