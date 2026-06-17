import 'package:flutter/material.dart';
import 'package:health/features/audio/presentation/audio_playback_bridge.dart';
import 'package:health/features/audio/presentation/audio_pip_host.dart';
import 'package:health/features/companion/presentation/companion_tab_shell.dart';
import 'package:health/core/constants/app_colors.dart';
import 'package:health/features/audio/presentation/audio_screen.dart';
import 'package:health/features/audio/presentation/global_audio_mini_player.dart';
import 'package:health/features/auth/presentation/auth_screen.dart';
import 'package:health/features/home/presentation/home_screen.dart';
import 'package:health/features/payment/presentation/payment_modal.dart';
import 'package:health/features/settings/presentation/settings_screen.dart';
import 'package:health/features/subscription/presentation/subscription_sync_host.dart';
import 'package:health/features/team/presentation/team_screen.dart';
import 'package:health/shared/models/app_models.dart';
import 'package:health/shared/providers/app_state_provider.dart';
import 'package:health/shared/widgets/bottom_nav_bar.dart';
import 'package:provider/provider.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key});

  static const _tabPages = [
    HomeScreen(key: ValueKey('tab-home')),
    AudioScreen(key: ValueKey('tab-audio')),
    CompanionTabShell(key: ValueKey('tab-companion')),
    TeamScreen(key: ValueKey('tab-team')),
    SettingsScreen(key: ValueKey('tab-settings')),
  ];

  @override
  Widget build(BuildContext context) {
    return Selector<AppStateProvider, ({AuthState auth, bool loading})>(
      selector: (_, app) =>
          (auth: app.authState, loading: app.homeDataLoading),
      builder: (context, state, _) {
        if (state.auth != AuthState.authenticated) {
          return const AuthScreen();
        }
        if (state.loading) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            ),
          );
        }
        return const SubscriptionSyncHost(
          child: AudioPiPHost(
            child: AudioPlaybackBridge(
              child: _AuthenticatedShell(),
            ),
          ),
        );
      },
    );
  }
}

class _AuthenticatedShell extends StatelessWidget {
  const _AuthenticatedShell();

  @override
  Widget build(BuildContext context) {
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
                    child: Selector<AppStateProvider, ActiveTab>(
                      selector: (_, app) => app.activeTab,
                      builder: (context, activeTab, _) {
                        return IndexedStack(
                          index: activeTab.index,
                          sizing: StackFit.expand,
                          children: AppShell._tabPages,
                        );
                      },
                    ),
                  ),
                  bottomNavigationBar: Selector<AppStateProvider, ActiveTab>(
                    selector: (_, app) => app.activeTab,
                    builder: (context, activeTab, _) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const GlobalAudioMiniPlayer(),
                          HealthBottomNav(
                            activeTab: activeTab,
                            onTabSelected: (tab) {
                              if (tab != ActiveTab.settings) {
                                context
                                    .read<AppStateProvider>()
                                    .setSettingsView(SettingsView.main);
                              }
                              context.read<AppStateProvider>().navigateTo(tab);
                            },
                            onCompanionTap: () {
                              context.read<AppStateProvider>().navigateTo(
                                    ActiveTab.companion,
                                  );
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
            Selector<AppStateProvider, PaymentStep?>(
              selector: (_, app) => app.paymentStep,
              builder: (context, paymentStep, _) {
                if (paymentStep == null) return const SizedBox.shrink();
                return const PaymentModal();
              },
            ),
            Selector<AppStateProvider, bool>(
              selector: (_, app) => app.showSaveCredentials,
              builder: (context, showBanner, _) {
                if (!showBanner) return const SizedBox.shrink();
                final app = context.read<AppStateProvider>();
                return _saveCredentialsBanner(context, app);
              },
            ),
          ],
        );
      },
    );
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
              border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Lưu tài khoản?',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text('Thư điện tử: ${creds.email}',
                    style: const TextStyle(fontSize: 11)),
                const Text('Mật khẩu: ********',
                    style: TextStyle(fontSize: 11)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () =>
                            app.setShowSaveCredentials(false),
                        child: const Text('Lưu'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () =>
                            app.setShowSaveCredentials(false),
                        child: const Text('Không'),
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
