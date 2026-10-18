
import '../contest/contest_detail_view.dart';
import '../contest/contest_form_view.dart';
import '../contest/contest_listview.dart';
import '../dashboard/dashboard_view.dart';
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