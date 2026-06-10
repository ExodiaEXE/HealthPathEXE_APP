import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health/app/app_shell.dart';
import 'package:health/core/config/env_config.dart';
import 'package:health/core/di/app_dependencies.dart';
import 'package:health/core/theme/app_theme.dart';
import 'package:health/shared/models/app_models.dart';
import 'package:health/shared/providers/app_state_provider.dart';
import 'package:provider/provider.dart';

/// Stress-tests tab navigation to guarantee there are NO transient layout
/// exceptions (e.g. "BoxConstraints has a negative minimum" or RenderFlex
/// overflow) flashing on screen while switching bottom-nav items — including
/// while audio is playing during the AnimatedSwitcher fade transition.
void main() {
  late AppStateProvider provider;
  final captured = <String>[];

  Widget buildApp() {
    final deps = AppDependencies.create();
    provider = AppStateProvider(
      jwtAuth: deps.jwtAuth,
      restoreSession: deps.restoreSessionUseCase,
      wellness: deps.wellnessContentUseCase,
      fetchRoutines: deps.fetchRoutinesUseCase,
      syncMoodCheckin: deps.syncMoodCheckinUseCase,
      fetchMoodStats: deps.fetchMoodStatsUseCase,
      fetchTodayMoodCheckin: deps.fetchTodayMoodCheckinUseCase,
      completeTodayRoutine: deps.completeTodayRoutineUseCase,
      fetchTodaySchedule: deps.fetchTodayScheduleUseCase,
      dailyCheckinStore: deps.dailyCheckinStore,
      completedHabitsStore: deps.completedHabitsStore,
    );
    return MultiProvider(
      providers: [
        ...deps.providers().where((p) => p is! ChangeNotifierProvider),
        ChangeNotifierProvider<AppStateProvider>.value(value: provider),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: const AppShell(),
      ),
    );
  }

  void expectNoError(String stage) {
    // Errors are routed to FlutterError.onError (set up in the test body) so we
    // can collect EVERY layout error across the whole flow in a single run.
    final ex = TestWidgetsFlutterBinding.instance.takeException();
    if (ex != null) captured.add('[$stage] $ex');
  }

  testWidgets('switching all tabs (incl. while playing audio) has no layout errors',
      (tester) async {
    EnvConfig.loadForTest();
    captured.clear();
    final prevOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      final summary = details.exceptionAsString().split('\n').first;
      final loc = RegExp(r'[\w/]+\.dart:\d+:\d+')
          .firstMatch(details.toString())
          ?.group(0);
      captured.add('$summary  @ ${loc ?? 'unknown'}');
    };
    addTearDown(() => FlutterError.onError = prevOnError);

    // Match the phone canvas of the web prototype (400 x 850).
    tester.view.physicalSize = const Size(400, 850);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildApp());
    provider.setAuthState(AuthState.authenticated);
    // Give the home screen some content so charts / progress bars render.
    provider.setEnergyLevel(EnergyLevel.medium);
    provider.setSelectedMood(0);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expectNoError('initial home render');

    // Walk every tab back and forth, pumping mid-transition (75ms) so both the
    // outgoing and incoming screens are simultaneously in the tree.
    const tabs = [
      ActiveTab.audio,
      ActiveTab.team,
      ActiveTab.settings,
      ActiveTab.home,
      ActiveTab.settings,
      ActiveTab.audio,
      ActiveTab.home,
    ];
    for (final tab in tabs) {
      provider.navigateTo(tab);
      await tester.pump(); // schedule transition
      await tester.pump(const Duration(milliseconds: 75)); // mid fade
      expectNoError('mid-transition to $tab');
      await tester.pump(const Duration(milliseconds: 200)); // finish fade
      expectNoError('after settle on $tab');
    }

    // Now play audio and switch away while it is actively playing.
    provider.navigateTo(ActiveTab.audio);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expectNoError('audio tab loaded');

    // Tap the first track to start playback (mini player + animated bars).
    final firstTrack = find.byType(InkWell).evaluate().isNotEmpty
        ? find.byType(GestureDetector).first
        : find.byType(GestureDetector).first;
    await tester.tap(firstTrack, warnIfMissed: false);
    await tester.pump();
    // Let the audio progress timer + bar animation run a few cycles.
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 150));
      expectNoError('audio playing frame $i');
    }

    // Switch tabs WHILE playing — this is exactly when the red flash was seen.
    for (final tab in [ActiveTab.team, ActiveTab.settings, ActiveTab.home]) {
      provider.navigateTo(tab);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 75));
      expectNoError('switch to $tab while audio playing (mid)');
      await tester.pump(const Duration(milliseconds: 200));
      expectNoError('switch to $tab while audio playing (settled)');
    }

    // Team tab: no-team main, then create-group and join-group sub-views.
    provider.navigateTo(ActiveTab.team);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expectNoError('team no-team main');

    final createCard = find.text('Tạo nhóm mới');
    if (createCard.evaluate().isNotEmpty) {
      await tester.tap(createCard.first, warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expectNoError('team create-group view');
    }
    // Back to team tab to reset internal sub-view, then open join.
    provider.navigateTo(ActiveTab.home);
    await tester.pump(const Duration(milliseconds: 200));
    provider.navigateTo(ActiveTab.team);
    await tester.pump(const Duration(milliseconds: 300));
    final joinCard = find.text('Tham gia nhóm');
    if (joinCard.evaluate().isNotEmpty) {
      await tester.tap(joinCard.first, warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expectNoError('team join-group view');
    }

    // Team dashboard (has a team).
    provider.setHasTeam(true);
    provider.navigateTo(ActiveTab.home);
    await tester.pump(const Duration(milliseconds: 200));
    provider.navigateTo(ActiveTab.team);
    await tester.pump(const Duration(milliseconds: 350));
    expectNoError('team dashboard');

    // Settings sub-views.
    provider.navigateTo(ActiveTab.settings);
    await tester.pump(const Duration(milliseconds: 300));
    expectNoError('settings main');
    for (final view in SettingsView.values) {
      provider.setSettingsView(view);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expectNoError('settings view $view');
    }
    provider.setSettingsView(SettingsView.main);
    await tester.pump(const Duration(milliseconds: 200));

    // Companion screen (pushed route).
    final companionBtn = find.text('Bạn đồng hành');
    if (companionBtn.evaluate().isNotEmpty) {
      await tester.tap(companionBtn.first, warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expectNoError('companion screen open');
      // Pop back.
      final navState = tester.state<NavigatorState>(find.byType(Navigator).first);
      navState.pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expectNoError('companion screen closed');
    }

    // Full payment flow: every step renders without layout error.
    for (final step in PaymentStep.values) {
      provider.setPaymentStep(step);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expectNoError('payment step $step');
      // The processing step schedules a 2s timer that auto-advances; drain it.
      if (step == PaymentStep.processing) {
        await tester.pump(const Duration(milliseconds: 2200));
        expectNoError('payment processing drained');
      }
    }
    provider.setPaymentStep(null);
    await tester.pump(const Duration(milliseconds: 300));
    // Drain any remaining scheduled timers (confetti / processing).
    await tester.pump(const Duration(seconds: 3));
    expectNoError('payment modal closed');

    // Drain any trailing animation frames.
    await tester.pump(const Duration(milliseconds: 600));
    expectNoError('final settle');

    FlutterError.onError = prevOnError;
    if (captured.isNotEmpty) {
      debugPrint('===== CAPTURED LAYOUT ERRORS (${captured.length}) =====');
      for (final c in captured.toSet()) {
        debugPrint(c);
      }
    }
    expect(captured, isEmpty,
        reason: 'Layout errors detected:\n${captured.toSet().join('\n')}');
  });
}
