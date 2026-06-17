import 'package:flutter/material.dart';

/// Defers mounting a [ModelViewer] until after the first frame and tears it
/// down early when the route is deactivated (e.g. user navigates away quickly).
class DeferredModelViewerHost extends StatefulWidget {
  const DeferredModelViewerHost({super.key, required this.builder});

  final Widget Function() builder;

  @override
  State<DeferredModelViewerHost> createState() =>
      _DeferredModelViewerHostState();
}

class _DeferredModelViewerHostState extends State<DeferredModelViewerHost> {
  bool _showViewer = false;
  bool _teardown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _teardown) return;
      setState(() => _showViewer = true);
    });
  }

  @override
  void deactivate() {
    if (_showViewer) {
      _teardown = true;
      // Avoid synchronous setState in deactivate — schedule after frame.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_teardown) return;
        setState(() => _showViewer = false);
      });
    }
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    if (!_showViewer || _teardown) return const SizedBox.shrink();
    return widget.builder();
  }
}
