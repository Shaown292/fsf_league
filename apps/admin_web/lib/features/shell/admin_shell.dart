import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fsf_league_admin/features/contests/contest_controller.dart';
import 'package:get/get.dart';

import '../../core/app_mode.dart';
import '../../data/contest_repository.dart';
import '../../data/player_library_repository.dart';
import '../players/library_controller.dart';
import 'admin_nav.dart';
import 'routes.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key, required this.user});
  final User user;

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  late final AdminNav _nav;

  @override
  void initState() {
    super.initState();
    _nav = Get.put(AdminNav());
    _nav.goRoot(dashboardRoute());
    Get.put(ContestsController(Get.find<ContestRepository>()));
    Get.put(PlayerLibraryController(Get.find<PlayerLibraryRepository>()));
  }

  @override
  void dispose() {
    // Clears cached data when the admin signs out.
    Get.delete<PlayerLibraryController>();
    Get.delete<ContestsController>();
    Get.delete<AdminNav>();
    super.dispose();
  }

  void _selectSection(int index) {
    _nav.goRoot(switch (index) {
      0 => dashboardRoute(),
      1 => contestListRoute(),
      _ => playerLibraryRoute(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Obx(
                () => NavigationRail(
              selectedIndex: _nav.section,
              onDestinationSelected: _selectSection,
              labelType: NavigationRailLabelType.all,
              destinations: const [
                NavigationRailDestination(
                    icon: Icon(Icons.dashboard_outlined), label: Text('Dashboard')),
                NavigationRailDestination(
                    icon: Icon(Icons.sports_soccer), label: Text('Contests')),
                NavigationRailDestination(
                    icon: Icon(Icons.groups_outlined), label: Text('Players')),
              ],
              trailing: Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: IconButton(
                      tooltip: 'Sign out',
                      icon: const Icon(Icons.logout),
                      onPressed: FirebaseAuth.instance.signOut,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: Column(
              children: [
                _Header(nav: _nav, email: widget.user.email ?? ''),
                const Divider(height: 1),
                Expanded(
                  child: Obx(() {
                    final routes = _nav.stack.toList();
                    return IndexedStack(
                      index: routes.length - 1,
                      children: [
                        for (final r in routes)
                          KeyedSubtree(key: ObjectKey(r), child: r.builder()),
                      ],
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.nav, required this.email});
  final AdminNav nav;
  final String email;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Obx(
            () => Row(
          children: [
            if (nav.canPop)
              IconButton(
                tooltip: 'Back',
                icon: const Icon(Icons.arrow_back),
                onPressed: nav.pop,
              ),
            Text(nav.current.title, style: Theme.of(context).textTheme.titleLarge),
            const Spacer(),
            if (useEmulator)
              const Padding(
                padding: EdgeInsets.only(right: 12),
                child: Chip(
                  label: Text('EMULATOR'),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            Text(email),
          ],
        ),
      ),
    );
  }
}