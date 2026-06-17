import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:health/shared/providers/app_state_provider.dart';
import 'package:provider/provider.dart';

/// Re-syncs Google Play subscription when the app returns to foreground.
class SubscriptionSyncHost extends StatefulWidget {
  const SubscriptionSyncHost({super.key, required this.child});

  final Widget child;

  @override
  State<SubscriptionSyncHost> createState() => _SubscriptionSyncHostState();
}

class _SubscriptionSyncHostState extends State<SubscriptionSyncHost>
    with WidgetsBindingObserver {
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_syncFromPlay());
    }
  }

  Future<void> _syncFromPlay() async {
    if (_syncing || kIsWeb || !Platform.isAndroid) return;
    _syncing = true;
    try {
      if (!mounted) return;
      await context.read<AppStateProvider>().syncSubscriptionFromServer();
    } finally {
      _syncing = false;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
