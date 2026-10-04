import 'dart:async';

import 'package:flutter/widgets.dart';

/// Subscribes to a live database query once per [id] (not once per build)
/// and keeps showing the last value while re-subscribing, so rebuilds never
/// re-run queries or flash empty content.
class LiveQuery<T> extends StatefulWidget {
  const LiveQuery({super.key, required this.id, required this.stream, required this.builder});

  /// Identity of the query; a different value re-subscribes.
  final Object? id;
  final Stream<T> Function() stream;
  final Widget Function(BuildContext context, T? data) builder;

  @override
  State<LiveQuery<T>> createState() => _LiveQueryState<T>();
}

class _LiveQueryState<T> extends State<LiveQuery<T>> {
  StreamSubscription<T>? _sub;
  T? _data;

  @override
  void initState() {
    super.initState();
    _subscribe();
  }

  @override
  void didUpdateWidget(LiveQuery<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id) _subscribe();
  }

  void _subscribe() {
    _sub?.cancel();
    _sub = widget.stream().listen((v) {
      if (mounted) setState(() => _data = v);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _data);
}
