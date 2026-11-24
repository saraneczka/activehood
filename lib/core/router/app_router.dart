import 'package:go_router/go_router.dart';

import '../../features/search/presentation/search_screen.dart';

abstract final class AppRoutes {
  static const search = '/';
}

final appRouter = GoRouter(
  initialLocation: AppRoutes.search,
  routes: [
    GoRoute(
      path: AppRoutes.search,
      builder: (context, state) => const SearchScreen(),
    ),
  ],
);
