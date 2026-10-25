
import '../contests/contest_detail_view.dart';
import '../contests/contest_form_view.dart';
import '../contests/contest_listview.dart';
import '../dashboard/dashboard_view.dart';
import '../players/manage_players_view.dart';
import '../players/player_library_view.dart';
import 'admin_nav.dart';

AdminRoute dashboardRoute() =>
    AdminRoute('Dashboard', () => const DashboardView(), section: 0);

AdminRoute contestListRoute() =>
    AdminRoute('Contests', () => const ContestListView(), section: 1);

AdminRoute contestFormRoute({String? contestId}) => AdminRoute(
  contestId == null ? 'New contest' : 'Edit contest',
      () => ContestFormView(contestId: contestId),
);

AdminRoute contestDetailRoute(String id) =>
    AdminRoute('Contest', () => ContestDetailView(contestId: id));

AdminRoute playerLibraryRoute() =>
    AdminRoute('Player library', () => const PlayerLibraryView(), section: 2);

AdminRoute managePlayersRoute(String id) =>
    AdminRoute('Manage players', () => ManagePlayersView(contestId: id));