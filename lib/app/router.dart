import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/create/create_screen.dart';
import '../features/detail/detail_screen.dart';
import '../features/listings/listings_screen.dart';

class AppRoutes {
  static const listings = '/';
  static const create = '/create';

  static const listing = '/listing/:id';

  static String listingPath(int id) => '/listing/$id';
}

final appRouter = GoRouter(
  routes: [
    GoRoute(
      path: AppRoutes.listings,
      name: 'listings',
      builder: (context, state) => const ListingsScreen(),
      routes: [
        GoRoute(
          path: AppRoutes.listing,

          name: 'listing',
          builder: (context, state) {
            final id = int.tryParse(state.pathParameters['id'] ?? '');
            if (id == null) {
              return const _RouteError(
                message: 'That listing id is not valid.',
              );
            }
            return DetailScreen(id: id);
          },
        ),
        GoRoute(
          path: 'create',
          name: 'create',
          builder: (context, state) => const CreateScreen(),
        ),
      ],
    ),
  ],
  errorBuilder: (context, state) =>
      _RouteError(message: 'No page found at ${state.uri.path}'),
);

class _RouteError extends StatelessWidget {
  const _RouteError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Not found')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 12),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => context.go(AppRoutes.listings),
                child: const Text('Back to listings'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
