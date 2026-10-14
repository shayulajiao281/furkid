import 'package:go_router/go_router.dart';
import '../layout/main_shell.dart';
import '../pages/pets_page.dart';
import '../pages/reminders_page.dart';
import '../pages/weight_page.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/pets',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (_, __, shell) => MainShell(navigationShell: shell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/pets', builder: (_, __) => const PetsPage()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/reminders',
              builder: (_, __) => const RemindersPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/weight', builder: (_, __) => const WeightPage()),
          ],
        ),
      ],
    ),
  ],
);
