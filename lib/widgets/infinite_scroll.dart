import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/theme.dart';

mixin InfiniteScroll<T extends StatefulWidget> on State<T> {
  final ScrollController scrollController = ScrollController();
  bool loadingMore = false;
  String? loadMoreError;

  bool get hasMore;
  Future<void> loadMorePage();

  void initInfiniteScroll() {
    scrollController.addListener(_onScroll);
  }

  void disposeInfiniteScroll() {
    scrollController.dispose();
  }

  void _onScroll() {
    if (!scrollController.hasClients) return;
    final pos = scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 200) _loadMoreIfNeeded();
  }

  Future<void> _loadMoreIfNeeded() async {
    if (loadingMore || loadMoreError != null || !hasMore) return;
    setState(() => loadingMore = true);
    try {
      await loadMorePage();
    } catch (e) {
      if (mounted) setState(() => loadMoreError = ApiClient.extractError(e));
    } finally {
      if (mounted) setState(() => loadingMore = false);
    }
  }

  void retryLoadMore() {
    setState(() => loadMoreError = null);
    _loadMoreIfNeeded();
  }

  void checkForMore() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!scrollController.hasClients) return;
      final pos = scrollController.position;
      if (pos.pixels >= pos.maxScrollExtent - 200) _loadMoreIfNeeded();
    });
  }
}

class LoadMoreFooter extends StatelessWidget {
  final bool hasMore;
  final bool loadingMore;
  final String? error;
  final VoidCallback onRetry;
  const LoadMoreFooter({
    super.key,
    required this.hasMore,
    required this.loadingMore,
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (loadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ),
      );
    }
    if (error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Center(
          child: TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text("Couldn't load more — tap to retry"),
            style: TextButton.styleFrom(
              foregroundColor: context.palette.textSecondary,
            ),
          ),
        ),
      );
    }
    if (!hasMore) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 3,
                height: 3,
                decoration: BoxDecoration(
                  color: context.palette.textTertiary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                "You're all caught up",
                style: TextStyle(
                  fontSize: 12,
                  color: context.palette.textTertiary,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
