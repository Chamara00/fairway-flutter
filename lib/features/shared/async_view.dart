import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../core/api_exception.dart';

class StatusView extends StatelessWidget {
  const StatusView({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.onRetry,
    this.retryLabel = 'Try again',
  });

  factory StatusView.error({
    required ApiException error,
    VoidCallback? onRetry,
  }) {
    return StatusView(
      icon: error.isOffline ? Icons.wifi_off : Icons.error_outline,
      title: error.isOffline ? 'No connection' : 'Something went wrong',
      message: error.message,
      onRetry: onRetry,
    );
  }

  factory StatusView.empty({
    String title = 'No listings found',
    String? message,
    VoidCallback? onRetry,
    String retryLabel = 'Clear filters',
  }) {
    return StatusView(
      icon: Icons.search_off,
      title: title,
      message: message,
      onRetry: onRetry,
      retryLabel: retryLabel,
    );
  }

  final IconData icon;
  final String title;
  final String? message;
  final VoidCallback? onRetry;
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.pad * 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: AppTheme.pad),
            Text(
              title,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              const SizedBox(height: 6),
              Text(
                message!,
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: AppTheme.pad * 1.5),
              FilledButton.tonal(onPressed: onRetry, child: Text(retryLabel)),
            ],
          ],
        ),
      ),
    );
  }
}

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator());
}

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key, this.cachedAt, this.onRetry});

  final DateTime? cachedAt;
  final VoidCallback? onRetry;

  String get _label {
    if (cachedAt == null) return 'Offline — showing saved listings';
    final age = DateTime.now().difference(cachedAt!);
    if (age.inMinutes < 1) return 'Offline — saved just now';
    if (age.inHours < 1) return 'Offline — saved ${age.inMinutes}m ago';
    if (age.inDays < 1) return 'Offline — saved ${age.inHours}h ago';
    return 'Offline — saved ${age.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.pad,
          vertical: 10,
        ),
        child: Row(
          children: [
            Icon(Icons.cloud_off, size: 18, color: scheme.onTertiaryContainer),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _label,
                style: TextStyle(
                  fontSize: 12,
                  color: scheme.onTertiaryContainer,
                ),
              ),
            ),
            if (onRetry != null)
              TextButton(
                onPressed: onRetry,
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  foregroundColor: scheme.onTertiaryContainer,
                ),
                child: const Text('Retry'),
              ),
          ],
        ),
      ),
    );
  }
}

class LoadMoreIndicator extends StatelessWidget {
  const LoadMoreIndicator({super.key});

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: AppTheme.pad),
    child: Center(
      child: SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(strokeWidth: 2.5),
      ),
    ),
  );
}
