import 'dart:async';

/// Global notifier for category refresh events
/// This allows different parts of the app to notify when categories are updated
class CategoryRefreshNotifier {
  static final CategoryRefreshNotifier _instance = CategoryRefreshNotifier._internal();
  factory CategoryRefreshNotifier() => _instance;
  CategoryRefreshNotifier._internal();

  // Stream controller for category refresh events
  final StreamController<void> _refreshController = StreamController<void>.broadcast();

  // Stream that other widgets can listen to
  Stream<void> get refreshStream => _refreshController.stream;

  /// Notify all listeners that categories should be refreshed
  void notifyRefresh() {
    _refreshController.add(null);
  }

  /// Dispose the notifier
  void dispose() {
    _refreshController.close();
  }
}
