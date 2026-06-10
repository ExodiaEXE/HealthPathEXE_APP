import 'package:flutter/material.dart';
import 'package:health/features/companion/presentation/companion_hub_screen.dart';
import 'package:health/features/companion/presentation/companion_missions_screen.dart';
import 'package:health/features/companion/presentation/companion_room_screen.dart';
import 'package:health/features/companion/presentation/companion_shop_screen.dart';

/// Navigator lồng trong tab Bạn đồng hành — sub-page push/pop không che bottom nav.
class CompanionTabShell extends StatelessWidget {
  const CompanionTabShell({super.key});

  static const hubRoute = '/';
  static const missionsRoute = '/missions';
  static const shopRoute = '/shop';
  static const roomRoute = '/room';

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Navigator(
      initialRoute: hubRoute,
      onGenerateRoute: (settings) {
        final Widget page = switch (settings.name) {
          missionsRoute => const CompanionMissionsScreen(),
          shopRoute => const CompanionShopScreen(),
          roomRoute => const CompanionRoomScreen(),
          _ => const CompanionHubScreen(embeddedInShell: true),
        };
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => page,
        );
      },
      ),
    );
  }
}
