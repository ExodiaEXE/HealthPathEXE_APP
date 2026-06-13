import 'dart:async';

import 'package:flutter/material.dart';
import 'package:health/core/widgets/deferred_model_viewer_host.dart';
import 'package:health/domain/entities/companion_entities.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

/// Mascot GLB viewer — Phase 2. Falls back via [onFailed].
class CompanionMascot3D extends StatefulWidget {
  const CompanionMascot3D({
    super.key,
    required this.assets,
    required this.expression,
    this.onTap,
    this.onFailed,
  });

  final CompanionAssets assets;
  final String expression;
  final VoidCallback? onTap;
  final VoidCallback? onFailed;

  @override
  State<CompanionMascot3D> createState() => _CompanionMascot3DState();
}

class _CompanionMascot3DState extends State<CompanionMascot3D> {
  bool _loaded = false;
  bool _failed = false;
  Timer? _timeout;
  Timer? _loadDelay;

  @override
  void initState() {
    super.initState();
    _timeout = Timer(const Duration(seconds: 18), () {
      if (!mounted || _loaded || _failed) return;
      setState(() => _failed = true);
      widget.onFailed?.call();
    });
  }

  @override
  void dispose() {
    _timeout?.cancel();
    _loadDelay?.cancel();
    super.dispose();
  }

  void _markLoaded() {
    if (!mounted || _loaded || _failed) return;
    _timeout?.cancel();
    setState(() => _loaded = true);
  }

  void _onWebViewCreated(Object _) {
    _loadDelay?.cancel();
    _loadDelay = Timer(const Duration(seconds: 2), _markLoaded);
  }

  @override
  Widget build(BuildContext context) {
    final src = widget.assets.effectiveMascotSrc;
    if (_failed || !widget.assets.enable3D || src.isEmpty) {
      return const SizedBox.shrink();
    }

    final anim = widget.assets.animationFor(widget.expression);
    final idle = widget.expression == 'idle';

    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.translucent,
      child: Stack(
        alignment: Alignment.center,
        children: [
          DeferredModelViewerHost(
            builder: () => ModelViewer(
              key: ValueKey('${widget.assets.version}-$anim-$src'),
              src: src,
              alt: 'Mèo Xanh',
              ar: false,
              autoPlay: true,
              autoRotate: idle,
              cameraControls: false,
              disablePan: true,
              disableZoom: true,
              disableTap: true,
              animationName: anim,
              backgroundColor: Colors.transparent,
              loading: Loading.eager,
              onWebViewCreated: _onWebViewCreated,
            ),
          ),
          if (!_loaded)
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ],
      ),
    );
  }
}

/// Room GLB backdrop (optional per theme).
class CompanionRoom3D extends StatelessWidget {
  const CompanionRoom3D({
    super.key,
    required this.url,
  });

  final String url;

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) return const SizedBox.shrink();

    return IgnorePointer(
      child: DeferredModelViewerHost(
        builder: () => ModelViewer(
          src: url,
          alt: 'Phòng',
          ar: false,
          autoPlay: false,
          autoRotate: false,
          cameraControls: false,
          disablePan: true,
          disableZoom: true,
          disableTap: true,
          backgroundColor: Colors.transparent,
          loading: Loading.lazy,
        ),
      ),
    );
  }
}
