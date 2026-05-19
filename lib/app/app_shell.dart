import 'package:flutter/material.dart';
import 'package:health/companion/screens/companion_screen.dart';
import 'package:health/core/constants/app_colors.dart';
import 'package:health/features/audio/presentation/audio_screen.dart';
import 'package:health/features/auth/presentation/auth_screen.dart';
import 'package:health/features/home/presentation/home_screen.dart';
import 'package:health/features/payment/presentation/payment_modal.dart';
import 'package:health/features/settings/presentation/settings_screen.dart';
import 'package:health/features/team/presentation/team_screen.dart';
import 'package:health/shared/models/app_models.dart';
import 'package:health/shared/providers/app_state_provider.dart';
import 'package:health/shared/widgets/bottom_nav_bar.dart';
import 'package:health/shared/widgets/hp_page_transition.dart';
import 'package:provider/provider.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppStateProvider>();

    if (app.authState != AuthState.authenticated) {
      return const AuthScreen();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = _contentMaxWidth(constraints.maxWidth);
        return Stack(
          children: [
            Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Scaffold(
                  backgroundColor: AppColors.background,
                  body: SafeArea(
                    bottom: false,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 150),
                      transitionBuilder: HpFadeTransition.builder,
                      child: KeyedSubtree(
                        key: ValueKey(app.activeTab),
                        child: _tabScreen(app.activeTab),
                      ),
                    ),
                  ),
                  bottomNavigationBar: HealthBottomNav(
                    activeTab: app.activeTab,
                    onTabSelected: (tab) {
                      if (tab != ActiveTab.settings) {
                        app.setSettingsView(SettingsView.main);
                      }
                      app.navigateTo(tab);
                    },
                  ),
                  floatingActionButton: FloatingActionButton.small(
                    heroTag: 'companion',
                    elevation: 4,
                    backgroundColor: AppColors.accent,
                    onPressed: () => Navigator.of(context).push(
                      PageRouteBuilder<void>(
                        pageBuilder: (_, __, ___) => const CompanionScreen(),
                        transitionsBuilder: (_, anim, __, child) =>
                            FadeTransition(opacity: anim, child: child),
                        transitionDuration: const Duration(milliseconds: 200),
                      ),
                    ),
                    child: const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 20),
                  ),
                ),
              ),
            ),
            if (app.paymentStep != null) const PaymentModal(),
            if (app.showSaveCredentials) _saveCredentialsBanner(context, app),
          ],
        );
      },
    );
  }

  Widget _tabScreen(ActiveTab tab) {
    return switch (tab) {
      ActiveTab.home => const HomeScreen(),
      ActiveTab.audio => const AudioScreen(),
      ActiveTab.team => const TeamScreen(),
      ActiveTab.settings => const SettingsScreen(),
    };
  }

  double _contentMaxWidth(double screenWidth) {
    if (screenWidth >= 1200) return 480;
    if (screenWidth >= 840) return 440;
    return screenWidth;
  }

  Widget _saveCredentialsBanner(BuildContext context, AppStateProvider app) {
    final creds = app.savedCredentials;
    if (creds == null) return const SizedBox.shrink();
    return Positioned(
      top: MediaQuery.paddingOf(context).top + 8,
      left: 16,
      right: 16,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
        builder: (context, value, child) => Transform.translate(
          offset: Offset(0, -20 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        ),
        child: Material(
          elevation: 12,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Luu tai khoan?', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('Email: ${creds.email}', style: const TextStyle(fontSize: 11)),
                const Text('Mat khau: ********', style: TextStyle(fontSize: 11)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => app.setShowSaveCredentials(false),
                        child: const Text('Luu'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => app.setShowSaveCredentials(false),
                        child: const Text('Khong'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
