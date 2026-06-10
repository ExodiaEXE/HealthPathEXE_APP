import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:health/core/constants/routine_catalog.dart';
import 'package:health/core/persistence/completed_habits_local_store.dart';
import 'package:health/core/persistence/promoted_habits_local_store.dart';
import 'package:health/core/persistence/custom_weekly_routines_local_store.dart';
import 'package:health/core/persistence/daily_checkin_local_store.dart';
import 'package:health/core/persistence/habit_history_local_store.dart';
import 'package:health/core/persistence/user_profile_local_store.dart';
import 'package:health/core/utils/user_facing_message.dart';
import 'package:health/core/utils/weekly_planner_utils.dart';
import 'package:health/core/security/jwt_auth_service.dart';
import 'package:health/domain/entities/routine_entities.dart';
import 'package:health/domain/entities/weekly_plan_sync_result.dart';
import 'package:health/domain/usecases/auth/restore_session_usecase.dart';
import 'package:health/domain/usecases/mood_checkin/fetch_mood_stats_usecase.dart';
import 'package:health/domain/usecases/mood_checkin/fetch_today_mood_checkin_usecase.dart';
import 'package:health/domain/usecases/mood_checkin/sync_mood_checkin_usecase.dart';
import 'package:health/domain/usecases/routine/fetch_routines_usecase.dart';
import 'package:health/domain/usecases/user_routine/complete_today_routine_usecase.dart';
import 'package:health/domain/usecases/user_routine/fetch_today_schedule_usecase.dart';
import 'package:health/domain/entities/audio_entities.dart';
import 'package:health/domain/entities/group_entities.dart';
import 'package:health/domain/entities/notification_entities.dart';
import 'package:health/domain/usecases/audio/audio_usecases.dart';
import 'package:health/domain/usecases/group/group_usecases.dart';
import 'package:health/domain/usecases/notification/notification_usecases.dart';
import 'package:health/domain/usecases/user_routine/weekly_plan_usecases.dart';
import 'package:health/domain/usecases/wellness/wellness_content_usecase.dart';
import 'package:health/core/persistence/group_local_store.dart';
import 'package:health/core/persistence/team_checkin_local_store.dart';
import 'package:health/features/notifications/services/notification_delivery_coordinator.dart';
import 'package:health/shared/models/app_models.dart';

/// Trạng thái presentation — chỉ gọi use case, không truy cập data trực tiếp.
class AppStateProvider extends ChangeNotifier {
  AppStateProvider({
    required JwtAuthService jwtAuth,
    required RestoreSessionUseCase restoreSession,
    required WellnessContentUseCase wellness,
    required FetchRoutinesUseCase fetchRoutines,
    required SyncMoodCheckinUseCase syncMoodCheckin,
    required FetchMoodStatsUseCase fetchMoodStats,
    required FetchTodayMoodCheckinUseCase fetchTodayMoodCheckin,
    required CompleteTodayRoutineUseCase completeTodayRoutine,
    required FetchTodayScheduleUseCase fetchTodaySchedule,
    DailyCheckinLocalStore? dailyCheckinStore,
    CompletedHabitsLocalStore? completedHabitsStore,
    PromotedHabitsLocalStore? promotedHabitsStore,
    CustomWeeklyRoutinesLocalStore? customWeeklyStore,
    UserProfileLocalStore? userProfileStore,
    HabitHistoryLocalStore? habitHistoryStore,
    GroupLocalStore? groupLocalStore,
    TeamCheckinLocalStore? teamCheckinStore,
    CreateGroupUseCase? createGroup,
    FetchMyGroupsUseCase? fetchMyGroups,
    FetchPublicGroupsUseCase? fetchPublicGroups,
    JoinGroupUseCase? joinGroup,
    FetchGroupMembersUseCase? fetchGroupMembers,
    FetchGroupChallengesUseCase? fetchGroupChallenges,
    LeaveGroupUseCase? leaveGroup,
    CheckInGroupUseCase? checkInGroup,
    FetchRecurringTemplatesUseCase? fetchRecurringTemplates,
    SyncWeeklyPlanUseCase? syncWeeklyPlan,
    FetchAudioTracksUseCase? fetchAudioTracks,
    FetchAudioCategoriesUseCase? fetchAudioCategories,
    GetAudioStreamUrlUseCase? getAudioStreamUrl,
    RecordAudioPlayUseCase? recordAudioPlay,
    ToggleAudioFavoriteUseCase? toggleAudioFavorite,
    FetchNotificationSettingsUseCase? fetchNotificationSettings,
    UpdateNotificationSettingsUseCase? updateNotificationSettings,
    FetchNotificationsUseCase? fetchNotifications,
    GetUnreadNotificationCountUseCase? getUnreadNotificationCount,
    MarkNotificationReadUseCase? markNotificationRead,
    MarkAllNotificationsReadUseCase? markAllNotificationsRead,
    DeleteNotificationUseCase? deleteNotification,
  })  : _jwtAuth = jwtAuth,
        _restoreSession = restoreSession,
        _wellness = wellness,
        _fetchRoutines = fetchRoutines,
        _syncMoodCheckin = syncMoodCheckin,
        _fetchMoodStats = fetchMoodStats,
        _fetchTodayMoodCheckin = fetchTodayMoodCheckin,
        _completeTodayRoutine = completeTodayRoutine,
        _fetchTodaySchedule = fetchTodaySchedule,
        _dailyCheckinStore = dailyCheckinStore ?? DailyCheckinLocalStore(),
        _completedHabitsStore =
            completedHabitsStore ?? CompletedHabitsLocalStore(),
        _promotedHabitsStore =
            promotedHabitsStore ?? PromotedHabitsLocalStore(),
        _customWeeklyStore =
            customWeeklyStore ?? CustomWeeklyRoutinesLocalStore(),
        _userProfileStore = userProfileStore ?? UserProfileLocalStore(),
        _habitHistoryStore = habitHistoryStore ?? HabitHistoryLocalStore(),
        _groupLocalStore = groupLocalStore ?? GroupLocalStore(),
        _teamCheckinStore = teamCheckinStore ?? TeamCheckinLocalStore(),
        _createGroup = createGroup,
        _fetchMyGroups = fetchMyGroups,
        _fetchPublicGroups = fetchPublicGroups,
        _joinGroup = joinGroup,
        _fetchGroupMembers = fetchGroupMembers,
        _fetchGroupChallenges = fetchGroupChallenges,
        _leaveGroup = leaveGroup,
        _checkInGroup = checkInGroup,
        _fetchRecurringTemplates = fetchRecurringTemplates,
        _syncWeeklyPlan = syncWeeklyPlan,
        _fetchAudioTracks = fetchAudioTracks,
        _fetchAudioCategories = fetchAudioCategories,
        _getAudioStreamUrl = getAudioStreamUrl,
        _recordAudioPlay = recordAudioPlay,
        _toggleAudioFavorite = toggleAudioFavorite,
        _fetchNotificationSettings = fetchNotificationSettings,
        _updateNotificationSettings = updateNotificationSettings,
        _fetchNotifications = fetchNotifications,
        _getUnreadNotificationCount = getUnreadNotificationCount,
        _markNotificationRead = markNotificationRead,
        _markAllNotificationsRead = markAllNotificationsRead,
        _deleteNotification = deleteNotification {
    habitHistory = [];
  }

  final JwtAuthService _jwtAuth;
  final RestoreSessionUseCase _restoreSession;
  final WellnessContentUseCase _wellness;
  final FetchRoutinesUseCase _fetchRoutines;
  final SyncMoodCheckinUseCase _syncMoodCheckin;
  final FetchMoodStatsUseCase _fetchMoodStats;
  final FetchTodayMoodCheckinUseCase _fetchTodayMoodCheckin;
  final CompleteTodayRoutineUseCase _completeTodayRoutine;
  final FetchTodayScheduleUseCase _fetchTodaySchedule;
  final DailyCheckinLocalStore _dailyCheckinStore;
  final CompletedHabitsLocalStore _completedHabitsStore;
  final PromotedHabitsLocalStore _promotedHabitsStore;
  final CustomWeeklyRoutinesLocalStore _customWeeklyStore;
  final UserProfileLocalStore _userProfileStore;
  final HabitHistoryLocalStore _habitHistoryStore;
  final GroupLocalStore _groupLocalStore;
  final TeamCheckinLocalStore _teamCheckinStore;
  final CreateGroupUseCase? _createGroup;
  final FetchMyGroupsUseCase? _fetchMyGroups;
  final FetchPublicGroupsUseCase? _fetchPublicGroups;
  final JoinGroupUseCase? _joinGroup;
  final FetchGroupMembersUseCase? _fetchGroupMembers;
  final FetchGroupChallengesUseCase? _fetchGroupChallenges;
  final LeaveGroupUseCase? _leaveGroup;
  final CheckInGroupUseCase? _checkInGroup;
  final FetchRecurringTemplatesUseCase? _fetchRecurringTemplates;
  final SyncWeeklyPlanUseCase? _syncWeeklyPlan;
  final FetchAudioTracksUseCase? _fetchAudioTracks;
  final FetchAudioCategoriesUseCase? _fetchAudioCategories;
  final GetAudioStreamUrlUseCase? _getAudioStreamUrl;
  final RecordAudioPlayUseCase? _recordAudioPlay;
  final ToggleAudioFavoriteUseCase? _toggleAudioFavorite;
  final FetchNotificationSettingsUseCase? _fetchNotificationSettings;
  final UpdateNotificationSettingsUseCase? _updateNotificationSettings;
  final FetchNotificationsUseCase? _fetchNotifications;
  final GetUnreadNotificationCountUseCase? _getUnreadNotificationCount;
  final MarkNotificationReadUseCase? _markNotificationRead;
  final MarkAllNotificationsReadUseCase? _markAllNotificationsRead;
  final DeleteNotificationUseCase? _deleteNotification;

  final Map<String, AudioStreamResult> _audioStreamCache = {};

  static String _normId(String id) => id.toLowerCase();

  AuthState authState = AuthState.login;
  AuthProviderType authProvider = AuthProviderType.email;
  bool get isSocialAuth =>
      authProvider == AuthProviderType.google ||
      authProvider == AuthProviderType.facebook;
  bool isPremium = false;
  ActiveTab activeTab = ActiveTab.home;
  ActiveTab? previousTab;
  EnergyLevel? energyLevel;
  PaymentStep? paymentStep;
  PaymentMethodType? paymentMethod;
  String userName = 'Người dùng';
  String userEmail = 'user@healthpath.vn';
  /// Tên tài khoản từ login/API — dùng khi chưa điền đủ họ + tên hồ sơ.
  String accountUserName = '';
  UserProfile profile = const UserProfile();
  NotificationSettingsRecord notificationSettings =
      const NotificationSettingsRecord();
  List<NotificationRecord> notifications = [];
  int unreadNotificationCount = 0;
  bool notificationSettingsLoading = false;
  bool notificationsLoading = false;
  String? notificationError;
  late List<HabitRecord> habitHistory;
  SettingsView settingsView = SettingsView.main;
  final Set<String> todayCheckedHabits = {};
  final Set<String> habitCompletingIds = {};
  final List<String> promotedRoutineIds = [];
  bool dailyCheckinLocked = false;
  bool teamCheckInToday = false;
  Set<String> _teamWeekCheckInDates = {};
  Map<int, List<RoutineItem>> customRoutines = {};
  String? avatarUrl;
  int? selectedMood;
  String? teamGroupId;
  String teamName = 'Nhóm Exodia';
  String teamInviteCode = '';
  int teamMemberCount = 0;
  List<GroupMemberRecord> teamMembers = [];
  List<GroupRecord> myTeams = [];
  List<GroupRecord> publicGroups = [];
  GroupChallengeRecord? teamActiveChallenge;
  bool teamLoading = false;
  String? teamError;
  List<AudioTrackRecord> audioTracks = [];
  List<AudioCategoryRecord> audioCategories = [];
  String audioCategoryFilter = 'all';
  bool audioLoading = false;
  String? audioError;
  bool get hasTeam => teamGroupId != null && teamGroupId!.isNotEmpty;
  bool get hasAnyTeam => myTeams.isNotEmpty;
  List<SavedPaymentMethod> savedPaymentMethods = [];
  PremiumInfo? premiumInfo;
  bool showSaveCredentials = false;
  ({String email, String password})? savedCredentials;

  List<RoutineModel> routines = [];
  bool routinesLoading = false;
  String? routinesError;
  /// Đang tải dữ liệu trang chủ sau đăng nhập / khôi phục phiên.
  bool homeDataLoading = false;

  int dailyStreak = 0;
  bool moodCheckinSyncing = false;
  String? habitCompleteError;

  bool get hasCustomRoutines => customRoutines.isNotEmpty;

  List<RoutineUiGroup> get routineGroups => RoutineCatalog.groupRoutines(routines);

  bool get hasDailySuggestionFilter =>
      selectedMood != null && energyLevel != null;

  List<RoutineModel> get _availableRoutines =>
      isPremium ? routines : routines.where((r) => !r.isPremium).toList();

  List<RoutineModel> get _suggestionPool {
    final catalog = _availableRoutines;
    if (!hasDailySuggestionFilter) return catalog;
    return RoutineCatalog.pickHomeHighlights(
      catalog,
      energyKey: energyLevel!.name,
      mood: selectedMood,
      limit: catalog.length,
    );
  }

  /// Thói quen hôm nay — 5 đầu (khi đã lọc) + routine user bấm "+" từ gợi ý thêm.
  List<RoutineModel> get homeRoutineHabits {
    final pool = _suggestionPool;
    final base = hasDailySuggestionFilter ? pool.take(5).toList() : <RoutineModel>[];
    final baseIds = base.map((r) => r.id).toSet();
    final promoted = <RoutineModel>[];

    for (final id in promotedRoutineIds) {
      if (baseIds.contains(_normId(id))) continue;
      final match = _routineById(id);
      if (match != null) promoted.add(match);
    }
    final merged = [...base, ...promoted];
    if (isPremium) return merged;
    return merged.where((r) => !r.isPremium).toList();
  }

  /// Gợi ý thêm — luôn 5 routine kế tiếp (bỏ qua những cái đã nằm trong thói quen).
  List<RoutineModel> get homeRoutineExtras {
    final habitIds = {
      ...homeRoutineHabits.map((r) => _normId(r.id)),
      ...todayCustomRoutineIds,
    };
    return _suggestionPool
        .where((r) => !habitIds.contains(_normId(r.id)))
        .take(5)
        .toList();
  }

  /// Routine catalog dùng trong planner 7 ngày.
  List<RoutineModel> get plannerSuggestionPool => _availableRoutines;

  List<RoutineItem> get todayCustomRoutineItems {
    if (!hasCustomRoutines) return const [];
    final todayIdx = WeeklyPlannerUtils.todayWeekIndex;
    return customRoutines[todayIdx] ?? const [];
  }

  Set<String> get todayCustomRoutineIds =>
      todayCustomRoutineItems.map((r) => _normId(r.id)).toSet();

  RoutineModel? _routineById(String id) {
    final key = _normId(id);
    for (final r in routines) {
      if (_normId(r.id) == key) return r;
    }
    return null;
  }

  bool isRoutineInHabits(String id) {
    final norm = _normId(id);
    if (todayCustomRoutineIds.contains(norm)) return true;
    return homeRoutineHabits.any((r) => _normId(r.id) == norm);
  }

  List<RoutineModel> get homeRoutineHighlights => homeRoutineHabits;

  // Delegates tới domain use case — màn hình không import data layer.
  WellnessContentUseCase get wellness => _wellness;

  Future<void> tryRestoreSession() async {
    final restored = await _restoreSession();
    if (restored == null || !restored.success) return;
    final email = restored.userEmail ?? userEmail;
    final savedProvider = await _jwtAuth.loginProviderFor(email);
    await completeAuth(
      email: email,
      name: restored.userName,
      token: restored.token,
      isPremium: restored.isPremium,
      provider: _authProviderFromName(savedProvider),
    );
  }

  AuthProviderType _authProviderFromName(String? name) {
    switch (name) {
      case 'google':
        return AuthProviderType.google;
      case 'facebook':
        return AuthProviderType.facebook;
      default:
        return AuthProviderType.email;
    }
  }

  void navigateTo(ActiveTab tab) {
    previousTab = activeTab;
    activeTab = tab;
    notifyListeners();
  }

  void goBack() {
    if (previousTab != null) {
      activeTab = previousTab!;
      previousTab = null;
    } else {
      activeTab = ActiveTab.home;
    }
    notifyListeners();
  }

  List<RoutineItem> getActiveHabits() {
    final customToday = todayCustomRoutineItems;
    final customIds = todayCustomRoutineIds;

    final fromSuggestions = homeRoutineHabits
        .where((r) => !customIds.contains(_normId(r.id)))
        .map((r) => RoutineItem(
              id: r.id,
              text: r.title,
              category: r.category,
            ));

    return [...customToday, ...fromSuggestions];
  }

  void addRoutineToHabits(String id) {
    final norm = _normId(id);
    if (isRoutineInHabits(norm)) return;
    promotedRoutineIds.add(norm);
    unawaited(_persistPromotedHabits());
    notifyListeners();
    unawaited(_syncTodayHabitHistory());
  }

  Set<String> get _baseHabitIds {
    if (!hasDailySuggestionFilter) return {};
    return _suggestionPool
        .take(5)
        .map((r) => _normId(r.id))
        .toSet();
  }

  void _ensurePromotedIfNotInBase(String id) {
    final norm = _normId(id);
    if (_baseHabitIds.contains(norm)) return;
    if (promotedRoutineIds.contains(norm)) return;
    promotedRoutineIds.add(norm);
  }

  Future<void> _persistPromotedHabits() =>
      _promotedHabitsStore.save(promotedRoutineIds);

  Future<void> _restorePromotedHabitsLocal() async {
    try {
      final saved = await _promotedHabitsStore.loadToday();
      for (final id in saved) {
        if (!promotedRoutineIds.contains(id)) {
          promotedRoutineIds.add(id);
        }
      }
      notifyListeners();
    } catch (e) {
      if (kDebugMode) debugPrint('_restorePromotedHabitsLocal: $e');
    }
  }

  bool isHabitCompleted(String routineId) =>
      todayCheckedHabits.contains(_normId(routineId));

  bool isHabitCompleting(String routineId) =>
      habitCompletingIds.contains(_normId(routineId));

  Future<void> _persistCompletedHabits() =>
      _completedHabitsStore.save(todayCheckedHabits);

  Future<void> _restoreCompletedHabitsLocal() async {
    try {
      await _archiveHabitHistoryFromCompletedStore();
      final saved = await _completedHabitsStore.loadToday();
      todayCheckedHabits.addAll(saved);
      notifyListeners();
    } catch (e) {
      if (kDebugMode) debugPrint('_restoreCompletedHabitsLocal: $e');
    }
  }

  Future<void> _archiveHabitHistoryFromCompletedStore() async {
    final snapshot = await _completedHabitsStore.readPreviousDayIfRollover();
    if (snapshot == null) return;

    final habits = getActiveHabits()
        .map(
          (h) => HabitItem(
            id: h.id,
            text: h.text,
            done: snapshot.ids.contains(_normId(h.id)),
          ),
        )
        .toList();
    if (habits.isEmpty && snapshot.ids.isEmpty) return;

    HabitRecord? existing;
    for (final r in habitHistory) {
      if (r.date == snapshot.date) {
        existing = r;
        break;
      }
    }

    final record = HabitRecord(
      date: snapshot.date,
      habits: habits,
      energyLevel: existing?.energyLevel,
      rating: existing?.rating,
    );
    final idx = habitHistory.indexWhere((h) => h.date == snapshot.date);
    if (idx >= 0) {
      habitHistory = [...habitHistory]..[idx] = record;
    } else {
      habitHistory = [...habitHistory, record];
    }
    _pruneHabitHistory();
    await _persistHabitHistory();
  }

  void _pruneHabitHistory() {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    final cutoffKey = _dateStr(cutoff);
    habitHistory =
        habitHistory.where((r) => r.date.compareTo(cutoffKey) >= 0).toList();
  }

  Future<void> completeTodayHabit(String routineId) async {
    final id = _normId(routineId);
    if (isHabitCompleted(id) || isHabitCompleting(id)) return;

    final routine = _routineById(id);
    final isCustomTask = id.startsWith('custom-');

    if (!isCustomTask &&
        routine != null &&
        routine.isPremium &&
        !isPremium) {
      habitCompleteError = 'Routine Premium — nâng cấp để hoàn thành.';
      notifyListeners();
      return;
    }

    habitCompletingIds.add(id);
    habitCompleteError = null;
    notifyListeners();

    try {
      final minutes = routine?.durationMinutes ?? 5;
      var saved = false;
      String? error;

      if (_completeTodayRoutine.isOnline && !isCustomTask) {
        final result = await _completeTodayRoutine(
          routineId: id,
          durationMinutes: minutes,
        );
        saved = result.success;
        error = result.errorMessage;
        if (result.errorCode == 'PREMIUM_REQUIRED') {
          error = 'Routine Premium — nâng cấp để hoàn thành.';
        }
      } else {
        saved = true;
      }

      if (saved) {
        todayCheckedHabits.add(id);
        _ensurePromotedIfNotInBase(id);
        await _persistCompletedHabits();
        await _persistPromotedHabits();
        await _syncTodayHabitHistory();
        if (teamGroupId != null && teamGroupId!.isNotEmpty) {
          unawaited(refreshTeamDashboard());
        }
      } else if (error != null) {
        habitCompleteError = error;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('completeTodayHabit: $e');
      habitCompleteError = 'Không lưu được thói quen. Thử lại sau.';
    } finally {
      habitCompletingIds.remove(id);
      notifyListeners();
    }
  }

  void clearHabitCompleteError() {
    if (habitCompleteError == null) return;
    habitCompleteError = null;
    notifyListeners();
  }

  Future<void> loadTodayCompletedRoutines() async {
    await _restoreCompletedHabitsLocal();
    await _restorePromotedHabitsLocal();

    if (authState != AuthState.authenticated) return;
    if (!_completeTodayRoutine.isOnline) return;

    try {
      final items = await _fetchTodaySchedule();
      var changed = false;
      var promotedChanged = false;
      for (final item in items) {
        final id = _normId(item.routineId);
        if (item.isCompleted && !todayCheckedHabits.contains(id)) {
          todayCheckedHabits.add(id);
          changed = true;
        }
        if (item.isCompleted || item.status == 'pending' || item.status == 'in_progress') {
          final before = promotedRoutineIds.length;
          _ensurePromotedIfNotInBase(id);
          if (promotedRoutineIds.length > before) promotedChanged = true;
        }
      }
      if (changed) await _persistCompletedHabits();
      if (promotedChanged) await _persistPromotedHabits();
      notifyListeners();
      await _syncTodayHabitHistory();
    } catch (e) {
      if (kDebugMode) debugPrint('loadTodayCompletedRoutines: $e');
    }
  }

  void _resetPromotedRoutines() {
    if (promotedRoutineIds.isEmpty) return;
    promotedRoutineIds.clear();
    unawaited(_promotedHabitsStore.clear());
    notifyListeners();
  }

  void _maybeLockDailyCheckin() {
    if (selectedMood == null || energyLevel == null || dailyCheckinLocked) {
      return;
    }
    dailyCheckinLocked = true;
    unawaited(_dailyCheckinStore.save(locked: true));
    notifyListeners();
  }

  String _todayDateStr() {
    return _dateStr(DateTime.now());
  }

  String _dateStr(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  DateTime get currentWeekMonday =>
      TeamCheckinLocalStore.currentWeekMonday();

  DateTime get _lastWeekMonday => currentWeekMonday.subtract(const Duration(days: 7));

  List<String> get currentWeekDateKeys => List.generate(
        7,
        (i) => _dateStr(currentWeekMonday.add(Duration(days: i))),
      );

  /// Hoàn thành / tổng routine từng ngày trong tuần hiện tại (T2–CN).
  List<({int completed, int total})> get currentWeekDailyRoutineStats {
    final byDate = {for (final r in habitHistory) r.date: r};
    return currentWeekDateKeys.map((key) {
      final record = byDate[key];
      if (record == null) return (completed: 0, total: 0);
      final total = record.habits.length;
      final completed = record.habits.where((h) => h.done).length;
      return (completed: completed, total: total);
    }).toList();
  }

  /// % thử thách 7 ngày — cùng công thức với bảng xếp hạng (điểm danh + routine).
  double get currentWeekChallengeProgress {
    return (myWeeklyLeaderboardPoints / 100.0).clamp(0.0, 1.0);
  }

  int get currentWeekChallengePercent =>
      (currentWeekChallengeProgress * 100).round();

  /// Ô ngày trên thẻ thử thách: có hoàn thành ít nhất 1 routine trong ngày.
  List<bool> get currentWeekChallengeDayDone => currentWeekDailyRoutineStats
      .map((d) => d.total > 0 && d.completed > 0)
      .toList();

  /// Điểm bảng xếp hạng tuần này (0–100).
  /// Mỗi ngày tối đa ~14.3 điểm: ~7.1 từ điểm danh + ~7.1 từ % routine hoàn thành.
  double get myWeeklyLeaderboardPoints {
    const halfDayWeight = 100.0 / 14.0;
    var sum = 0.0;
    final stats = currentWeekDailyRoutineStats;
    for (var i = 0; i < 7; i++) {
      if (_teamWeekCheckInDates.contains(currentWeekDateKeys[i])) {
        sum += halfDayWeight;
      }
      final day = stats[i];
      if (day.total > 0 && day.completed > 0) {
        sum += (day.completed / day.total) * halfDayWeight;
      }
    }
    return sum.clamp(0.0, 100.0);
  }

  int get myWeeklyLeaderboardPointsRounded => myWeeklyLeaderboardPoints.round();

  /// Điểm tuần từ API (0–100), cùng công thức server cho mọi thành viên.
  int weeklyLeaderboardPointsFor(GroupMemberRecord member) =>
      member.weeklyScore.clamp(0, 100);

  /// Số routine hoàn thành mỗi ngày T2→CN của tuần trước (trước thứ Hai tuần hiện tại).
  List<int> get lastWeekRoutineCompletions {
    final lastMonday = _lastWeekMonday;
    final byDate = {for (final r in habitHistory) r.date: r};
    return List.generate(7, (i) {
      final key = _dateStr(lastMonday.add(Duration(days: i)));
      final record = byDate[key];
      if (record == null) return 0;
      return record.habits.where((h) => h.done).length;
    });
  }

  String get lastWeekRoutineRangeLabel {
    final start = _lastWeekMonday;
    final end = start.add(const Duration(days: 6));
    return '${start.day}/${start.month} – ${end.day}/${end.month}';
  }

  bool get hasLastWeekRoutineData =>
      lastWeekRoutineCompletions.any((count) => count > 0);

  HabitRecord? _buildTodayHabitRecord() {
    final habits = getActiveHabits()
        .map(
          (h) => HabitItem(
            id: h.id,
            text: h.text,
            done: isHabitCompleted(h.id),
          ),
        )
        .toList();
    if (habits.isEmpty) return null;

    final today = _todayDateStr();
    HabitRecord? existing;
    for (final r in habitHistory) {
      if (r.date == today) {
        existing = r;
        break;
      }
    }

    return HabitRecord(
      date: today,
      habits: habits,
      energyLevel: energyLevel,
      rating: existing?.rating,
    );
  }

  Future<void> _loadHabitHistory() async {
    try {
      habitHistory = await _habitHistoryStore.load(userEmail);
      await _archiveHabitHistoryFromCompletedStore();
      _pruneHabitHistory();
      await _syncTodayHabitHistory(notify: false);
      notifyListeners();
    } catch (e) {
      if (kDebugMode) debugPrint('_loadHabitHistory: $e');
    }
  }

  Future<void> _persistHabitHistory() async {
    try {
      await _habitHistoryStore.save(userEmail, habitHistory);
    } catch (e) {
      if (kDebugMode) debugPrint('_persistHabitHistory: $e');
    }
  }

  Future<void> _syncTodayHabitHistory({bool notify = true}) async {
    if (authState != AuthState.authenticated) return;
    final record = _buildTodayHabitRecord();
    if (record == null) return;

    final idx = habitHistory.indexWhere((h) => h.date == record.date);
    if (idx >= 0) {
      habitHistory = [...habitHistory]..[idx] = record;
    } else {
      habitHistory = [...habitHistory, record];
    }
    _pruneHabitHistory();
    await _persistHabitHistory();
    if (notify) notifyListeners();
  }

  Future<void> refreshHabitHistory() async {
    await _archiveHabitHistoryFromCompletedStore();
    await _syncTodayHabitHistory();
  }

  void addHabitRecord(HabitRecord record) {
    final idx = habitHistory.indexWhere((h) => h.date == record.date);
    if (idx >= 0) {
      habitHistory = [...habitHistory]..[idx] = record;
    } else {
      habitHistory = [...habitHistory, record];
    }
    notifyListeners();
    unawaited(_persistHabitHistory());
  }

  void updateHistoryRating(String date, int rating) {
    habitHistory = habitHistory
        .map((r) => r.date == date
            ? HabitRecord(
                date: r.date,
                habits: r.habits,
                energyLevel: r.energyLevel,
                rating: rating,
              )
            : r)
        .toList();
    notifyListeners();
    unawaited(_persistHabitHistory());
  }

  void addSavedPaymentMethod(SavedPaymentMethod method) {
    savedPaymentMethods =
        [...savedPaymentMethods.where((p) => p.id != method.id), method];
    notifyListeners();
  }

  void removeSavedPaymentMethod(String id) {
    savedPaymentMethods =
        savedPaymentMethods.where((p) => p.id != id).toList();
    notifyListeners();
  }

  Future<void> completeAuth({
    required String email,
    String? name,
    String? token,
    bool? isPremium,
    AuthProviderType provider = AuthProviderType.email,
  }) async {
    homeDataLoading = true;
    notifyListeners();

    userEmail = email;
    authProvider = provider;
    await _jwtAuth.persistLoginProvider(email: email, provider: provider.name);
    _applyAuthAccountName(name);
    await _restoreProfileForUser(email: email);
    profile = profile.copyWith(email: email);
    _refreshDisplayUserName();
    if (isPremium != null) this.isPremium = isPremium;
    if (token != null && token.isNotEmpty) {
      await _jwtAuth.persistToken(token);
    } else {
      await _jwtAuth.signInMock(email: email);
    }

    await _restoreCompletedHabitsLocal();
    await _restorePromotedHabitsLocal();
    await _restoreCustomRoutinesLocal();
    await restoreTodayCheckin(localOnly: true);

    authState = AuthState.authenticated;
    notifyListeners();

    await loadRoutineCatalog();
    await loadMoodStats();
    await restoreTodayCheckin();
    await loadWeeklyPlanFromApiIfNeeded();
    await loadTodayCompletedRoutines();
    await _loadHabitHistory();

    homeDataLoading = false;
    notifyListeners();

    unawaited(loadTeamState());
    unawaited(loadAudioCatalog());
    unawaited(refreshUnreadNotificationCount());
    unawaited(loadNotificationSettings());
    unawaited(_startNotificationDelivery());
  }

  Future<void> _startNotificationDelivery() async {
    await NotificationDeliveryCoordinator.start(
      onNotification: ingestIncomingNotification,
    );
  }

  bool ingestIncomingNotification(NotificationRecord record) {
    if (record.id.isNotEmpty &&
        notifications.any((n) => n.id == record.id)) {
      return false;
    }
    final isNearDuplicate = notifications.any(
      (n) =>
          n.type == record.type &&
          n.title == record.title &&
          n.body == record.body &&
          n.sentAt.difference(record.sentAt).inMinutes.abs() < 2,
    );
    if (isNearDuplicate) return false;

    notifications = [record, ...notifications];
    if (!record.isRead) {
      unreadNotificationCount++;
    }
    notifyListeners();
    return true;
  }

  Future<void> loadAudioCatalog({String? category}) async {
    final fetchTracks = _fetchAudioTracks;
    final fetchCategories = _fetchAudioCategories;
    if (fetchTracks == null ||
        fetchCategories == null ||
        !fetchTracks.isOnline) {
      return;
    }
    if (authState != AuthState.authenticated) return;

    final nextCategory = category ?? audioCategoryFilter;
    audioLoading = true;
    audioError = null;
    audioCategoryFilter = nextCategory;
    notifyListeners();

    try {
      final catRes = audioCategories.isEmpty
          ? await fetchCategories()
          : AudioOperationResult(success: true, categories: audioCategories);
      if (!catRes.success) {
        audioError = UserFacingMessage.sanitize(
          catRes.message,
          fallback: 'Không tải được thư viện âm thanh.',
        );
        return;
      }
      if (catRes.categories != null) {
        audioCategories = catRes.categories!;
      }

      final trackRes = await fetchTracks(
        category: nextCategory == 'all' ? null : nextCategory,
      );
      if (!trackRes.success) {
        audioError = UserFacingMessage.sanitize(
          trackRes.message,
          fallback: 'Không tải được thư viện âm thanh.',
        );
        audioTracks = [];
        return;
      }
      audioTracks = trackRes.tracks ?? [];
    } catch (e) {
      if (kDebugMode) debugPrint('loadAudioCatalog: $e');
      audioError = 'Không tải được thư viện âm thanh.';
      audioTracks = [];
    } finally {
      audioLoading = false;
      notifyListeners();
    }
  }

  Future<AudioOperationResult> resolveAudioStream(String trackId) async {
    final getStream = _getAudioStreamUrl;
    if (getStream == null) {
      return AudioOperationResult.fail('Chưa cấu hình kết nối âm thanh.');
    }

    final id = _normId(trackId);
    final cached = _audioStreamCache[id];
    if (cached != null && !cached.isExpired) {
      return AudioOperationResult(success: true, stream: cached);
    }

    final res = await getStream(id);
    if (!res.success || res.stream == null) {
      return AudioOperationResult.fail(
        res.message ?? 'Không lấy được link phát nhạc.',
      );
    }

    _audioStreamCache[id] = res.stream!;
    return AudioOperationResult(success: true, stream: res.stream);
  }

  Future<void> recordAudioListening({
    required String trackId,
    required int playedSeconds,
  }) async {
    final record = _recordAudioPlay;
    if (record == null || playedSeconds < 1) return;
    try {
      await record(trackId: _normId(trackId), playedSeconds: playedSeconds);
    } catch (e) {
      if (kDebugMode) debugPrint('recordAudioListening: $e');
    }
  }

  Future<bool> toggleAudioFavorite(String trackId) async {
    final toggle = _toggleAudioFavorite;
    if (toggle == null) return false;

    final id = _normId(trackId);
    final idx = audioTracks.indexWhere((t) => t.id == id);
    if (idx < 0) return false;

    final current = audioTracks[idx].isFavorited;
    final res = await toggle(trackId: id, isFavorited: current);
    if (!res.success) return false;

    final nextFav = res.isFavorited ?? !current;
    audioTracks = [
      ...audioTracks.sublist(0, idx),
      audioTracks[idx].copyWith(isFavorited: nextFav),
      ...audioTracks.sublist(idx + 1),
    ];
    notifyListeners();
    return true;
  }

  void _clearActiveGroupDetails() {
    teamGroupId = null;
    teamName = 'Nhóm Exodia';
    teamInviteCode = '';
    teamMemberCount = 0;
    teamMembers = [];
    teamActiveChallenge = null;
    teamCheckInToday = false;
    _teamWeekCheckInDates = {};
  }

  void _clearTeamState() {
    myTeams = [];
    _clearActiveGroupDetails();
    publicGroups = [];
    teamError = null;
  }

  void _applyActiveGroup(GroupRecord group) {
    teamGroupId = group.id;
    teamName = group.name;
    teamInviteCode = group.inviteCode;
    teamMemberCount = group.memberCount;
    unawaited(_groupLocalStore.saveActiveGroupId(userEmail, group.id));
  }

  Future<void> loadTeamState() async {
    final fetchMy = _fetchMyGroups;
    if (fetchMy == null || !fetchMy.isOnline) return;
    if (authState != AuthState.authenticated) return;

    teamLoading = true;
    teamError = null;
    notifyListeners();

    try {
      final savedId = await _groupLocalStore.loadActiveGroupId(userEmail);
      final res = await fetchMy();
      if (!res.success) {
        teamError = res.message;
        _clearTeamState();
        return;
      }

      final groups = res.groups ?? [];
      myTeams = groups;
      if (groups.isEmpty) {
        await _groupLocalStore.clearActiveGroupId(userEmail);
        _clearTeamState();
        return;
      }

      _clearActiveGroupDetails();
      if (savedId != null &&
          groups.any((g) => g.id == savedId.toLowerCase())) {
        final group = groups.firstWhere((g) => g.id == savedId.toLowerCase());
        _applyActiveGroup(group);
        await refreshTeamDashboard();
      } else {
        final first = groups.first;
        await _groupLocalStore.saveActiveGroupId(userEmail, first.id);
        _applyActiveGroup(first);
        await refreshTeamDashboard();
      }
    } catch (e) {
      if (kDebugMode) debugPrint('loadTeamState: $e');
      teamError = 'Không tải được thông tin nhóm.';
    } finally {
      teamLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createTeam(String name, {String? description}) async {
    final create = _createGroup;
    if (create == null || !create.isOnline) {
      setHasTeam(true, name: name);
      return true;
    }

    teamLoading = true;
    teamError = null;
    notifyListeners();

    try {
      final res = await create(
        name: name,
        description: description?.trim(),
      );
      if (!res.success || res.group == null) {
        teamError = res.message ?? 'Tạo nhóm thất bại.';
        return false;
      }
      _upsertMyTeam(res.group!);
      _applyActiveGroup(res.group!);
      await refreshTeamDashboard();
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('createTeam: $e');
      teamError = 'Tạo nhóm thất bại.';
      return false;
    } finally {
      teamLoading = false;
      notifyListeners();
    }
  }

  Future<bool> joinTeamById(String groupId) async {
    final join = _joinGroup;
    if (join == null || !join.isOnline) {
      setHasTeam(true, name: teamName);
      return true;
    }

    teamLoading = true;
    teamError = null;
    notifyListeners();

    try {
      final res = await join(groupId: groupId);
      if (!res.success || res.group == null) {
        teamError = res.message ?? 'Tham gia nhóm thất bại.';
        return false;
      }
      _upsertMyTeam(res.group!);
      _applyActiveGroup(res.group!);
      await refreshTeamDashboard();
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('joinTeamById: $e');
      teamError = 'Tham gia nhóm thất bại.';
      return false;
    } finally {
      teamLoading = false;
      notifyListeners();
    }
  }

  Future<void> searchPublicGroups(String query) async {
    final fetchPublic = _fetchPublicGroups;
    if (fetchPublic == null || !fetchPublic.isOnline) return;

    teamLoading = true;
    notifyListeners();
    try {
      final res = await fetchPublic(search: query);
      if (res.success) {
        publicGroups = res.groups ?? [];
      } else {
        teamError = res.message;
        publicGroups = [];
      }
    } catch (e) {
      if (kDebugMode) debugPrint('searchPublicGroups: $e');
      publicGroups = [];
    } finally {
      teamLoading = false;
      notifyListeners();
    }
  }

  void _upsertMyTeam(GroupRecord group) {
    myTeams = [
      ...myTeams.where((g) => g.id != group.id),
      group,
    ];
  }

  Future<void> openTeamGroup(GroupRecord group) async {
    _applyActiveGroup(group);
    await refreshTeamDashboard();
    await _refreshTeamWeeklyStats();
    notifyListeners();
  }

  Future<void> _refreshTeamWeeklyStats() async {
    final groupId = teamGroupId;
    if (groupId == null || groupId.isEmpty) {
      teamCheckInToday = false;
      _teamWeekCheckInDates = {};
      return;
    }
    teamCheckInToday =
        await _teamCheckinStore.hasCheckedInToday(userEmail, groupId);
    _teamWeekCheckInDates =
        await _teamCheckinStore.weekCheckInDates(userEmail, groupId);
  }

  void closeTeamDashboard() {
    _clearActiveGroupDetails();
    notifyListeners();
  }

  Future<String?> leaveCurrentTeam() async {
    final groupId = teamGroupId;
    if (groupId == null || groupId.isEmpty) {
      return 'Không có nhóm đang mở.';
    }

    final leave = _leaveGroup;
    if (leave == null || !leave.isOnline) {
      myTeams.removeWhere((g) => g.id == groupId);
      await _groupLocalStore.clearActiveGroupId(userEmail);
      _clearActiveGroupDetails();
      notifyListeners();
      return null;
    }

    teamLoading = true;
    teamError = null;
    notifyListeners();

    try {
      final res = await leave(groupId: groupId);
      if (!res.success) {
        teamError = res.message;
        return res.message ?? 'Rời nhóm thất bại.';
      }

      myTeams.removeWhere((g) => g.id == groupId);
      await _groupLocalStore.clearActiveGroupId(userEmail);
      _clearActiveGroupDetails();

      final fetchMy = _fetchMyGroups;
      if (fetchMy != null) {
        final listRes = await fetchMy();
        if (listRes.success) {
          myTeams = listRes.groups ?? [];
        }
      }

      if (myTeams.isEmpty) {
        await _groupLocalStore.clearActiveGroupId(userEmail);
      }

      return res.message;
    } catch (e) {
      if (kDebugMode) debugPrint('leaveCurrentTeam: $e');
      return 'Rời nhóm thất bại.';
    } finally {
      teamLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshTeamDashboard() async {
    final groupId = teamGroupId;
    if (groupId == null || groupId.isEmpty) return;

    final membersCase = _fetchGroupMembers;
    final challengesCase = _fetchGroupChallenges;
    if (membersCase != null) {
      final membersRes = await membersCase(groupId: groupId);
      if (membersRes.success) {
        teamMembers = membersRes.members ?? [];
        teamMemberCount = teamMembers.length;
      }
    }

    if (challengesCase != null) {
      final challengeRes = await challengesCase(groupId: groupId);
      if (challengeRes.success) {
        final list = challengeRes.challenges ?? [];
        teamActiveChallenge = list.isNotEmpty
            ? list.firstWhere((c) => c.isActive, orElse: () => list.first)
            : null;
      }
    }

    await _refreshTeamWeeklyStats();
    notifyListeners();
  }

  Future<void> _restoreProfileForUser({required String email}) async {
    try {
      final saved = await _userProfileStore.load(email);
      if (saved != null) {
        profile = saved.copyWith(email: email);
      } else {
        profile = UserProfile(email: email);
      }
      notifyListeners();
    } catch (e) {
      if (kDebugMode) debugPrint('_restoreProfileForUser: $e');
    }
  }

  void _applyAuthAccountName(String? name) {
    final trimmed = name?.trim() ?? '';
    if (trimmed.isNotEmpty) {
      accountUserName = trimmed;
      return;
    }
    final at = userEmail.indexOf('@');
    accountUserName = at > 0 ? userEmail.substring(0, at) : '';
  }

  bool get _hasProfileDisplayName =>
      profile.lastName.trim().isNotEmpty &&
      profile.firstName.trim().isNotEmpty;

  void _refreshDisplayUserName() {
    if (_hasProfileDisplayName) {
      userName = profile.displayName;
    } else if (accountUserName.trim().isNotEmpty) {
      userName = accountUserName.trim();
    } else {
      userName = 'Người dùng';
    }
  }

  Future<void> _restoreCustomRoutinesLocal() async {
    try {
      final saved = await _customWeeklyStore.load();
      if (saved.isNotEmpty) {
        customRoutines = saved;
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) debugPrint('_restoreCustomRoutinesLocal: $e');
    }
  }

  Future<void> loadWeeklyPlanFromApiIfNeeded() async {
    if (customRoutines.isNotEmpty) return;
    final fetchRecurring = _fetchRecurringTemplates;
    if (fetchRecurring == null || !fetchRecurring.isOnline) return;
    if (authState != AuthState.authenticated) return;

    try {
      final templates = await fetchRecurring();
      if (templates.isEmpty) return;
      final fromApi = weeklyPlanFromRecurringTemplates(templates);
      if (fromApi.isEmpty) return;
      customRoutines = fromApi;
      await _customWeeklyStore.save(fromApi);
      notifyListeners();
    } catch (e) {
      if (kDebugMode) debugPrint('loadWeeklyPlanFromApiIfNeeded: $e');
    }
  }

  /// Lưu plan 7 ngày — giữ nguyên ngày đã qua/hôm nay, chỉ cập nhật ngày tương lai.
  Future<WeeklyPlanSyncResult> saveCustomWeeklyPlan(
    Map<int, List<RoutineItem>> draft,
  ) async {
    final merged = <int, List<RoutineItem>>{};
    for (final entry in customRoutines.entries) {
      merged[entry.key] = List<RoutineItem>.from(entry.value);
    }
    for (final entry in draft.entries) {
      if (!WeeklyPlannerUtils.isDayEditable(entry.key)) continue;
      merged[entry.key] = List<RoutineItem>.from(entry.value);
    }
    customRoutines = merged;
    await _customWeeklyStore.save(merged);
    notifyListeners();

    final syncWeekly = _syncWeeklyPlan;
    if (syncWeekly != null && syncWeekly.isOnline) {
      unawaited(_syncWeeklyPlanInBackground(syncWeekly, merged));
    }

    return const WeeklyPlanSyncResult(savedLocally: true);
  }

  Future<void> _syncWeeklyPlanInBackground(
    SyncWeeklyPlanUseCase syncWeekly,
    Map<int, List<RoutineItem>> plan,
  ) async {
    try {
      final result = await syncWeekly(plan);
      if (result.idRemapping.isNotEmpty) {
        await _applyRoutineIdRemapping(result.idRemapping);
      }
      if (kDebugMode && result.errorMessage != null) {
        debugPrint('syncWeeklyPlan: ${result.errorMessage}');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('syncWeeklyPlan: $e');
    }
  }

  Future<void> _applyRoutineIdRemapping(Map<String, String> mapping) async {
    var changed = false;
    final updated = <int, List<RoutineItem>>{};
    for (final entry in customRoutines.entries) {
      updated[entry.key] = entry.value.map((item) {
        final newId = mapping[item.id.toLowerCase()];
        if (newId != null && newId.toLowerCase() != item.id.toLowerCase()) {
          changed = true;
          return item.copyWith(id: newId.toLowerCase());
        }
        return item;
      }).toList();
    }
    if (!changed) return;
    customRoutines = updated;
    await _customWeeklyStore.save(updated);
    notifyListeners();
  }

  /// Khôi phục mood/năng lượng đã chọn trong ngày (local + API).
  Future<void> restoreTodayCheckin({bool localOnly = false}) async {
    try {
      final local = await _dailyCheckinStore.loadToday();
      if (local != null) {
        _applyCheckinSelection(mood: local.mood, energy: local.energy);
        if (local.locked ||
            (local.mood != null && local.energy != null)) {
          dailyCheckinLocked = true;
          notifyListeners();
        }
      }

      if (localOnly || authState != AuthState.authenticated) return;

      final remote = await _fetchTodayMoodCheckin();
      if (remote == null) return;

      final mood = SyncMoodCheckinUseCase.moodIndexFromApi(remote.mood);
      final energy =
          SyncMoodCheckinUseCase.energyFromApi(remote.energyLevel);
      _applyCheckinSelection(mood: mood, energy: energy);
      dailyCheckinLocked = true;
      await _persistTodayCheckin();
      if (remote.streakDay > 0) {
        dailyStreak = remote.streakDay;
        notifyListeners();
      }
      await _syncTodayHabitHistory(notify: false);
    } catch (e) {
      if (kDebugMode) debugPrint('restoreTodayCheckin: $e');
    }
  }

  void _applyCheckinSelection({int? mood, EnergyLevel? energy}) {
    var changed = false;
    if (mood != null && selectedMood != mood) {
      selectedMood = mood;
      changed = true;
    }
    if (energy != null && energyLevel != energy) {
      energyLevel = energy;
      changed = true;
    }
    if (changed) notifyListeners();
  }

  Future<void> _persistTodayCheckin() async {
    await _dailyCheckinStore.save(
      mood: selectedMood,
      energy: energyLevel,
      locked: dailyCheckinLocked ? true : null,
    );
  }

  Future<void> loadMoodStats() async {
    try {
      final stats = await _fetchMoodStats();
      if (stats != null) {
        dailyStreak = stats.currentStreak;
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) debugPrint('loadMoodStats: $e');
    }
  }

  Future<void> loadRoutineCatalog() async {
    if (routinesLoading) return;
    routinesLoading = true;
    routinesError = null;
    notifyListeners();
    try {
      routines = await _fetchRoutines();
    } catch (e) {
      routinesError = 'Không tải được danh sách thói quen.';
      if (kDebugMode) debugPrint('loadRoutineCatalog: $e');
    } finally {
      routinesLoading = false;
      notifyListeners();
    }
  }

  Future<void> _syncMoodCheckinIfReady() async {
    final mood = selectedMood;
    final energy = energyLevel;
    if (mood == null || energy == null) return;
    if (authState != AuthState.authenticated) return;
    if (!_syncMoodCheckin.isOnline) return;
    if (moodCheckinSyncing) return;

    moodCheckinSyncing = true;
    notifyListeners();
    try {
      final record = await _syncMoodCheckin(
        moodIndex: mood,
        energy: energy,
      );
      if (record != null) {
        dailyStreak = record.streakDay;
      } else {
        await loadMoodStats();
      }
    } catch (e) {
      if (kDebugMode) debugPrint('_syncMoodCheckinIfReady: $e');
    } finally {
      moodCheckinSyncing = false;
      notifyListeners();
    }
  }

  void _scheduleMoodCheckinSync() {
    if (selectedMood == null || energyLevel == null) return;
    unawaited(_syncMoodCheckinIfReady());
  }

  Future<void> logout() async {
    await NotificationDeliveryCoordinator.stop();
    await _jwtAuth.clearLoginProvider(userEmail);
    await _jwtAuth.signOut();
    await _dailyCheckinStore.clear();
    await _completedHabitsStore.clear();
    await _promotedHabitsStore.clear();
    await _customWeeklyStore.clear();
    authState = AuthState.login;
    authProvider = AuthProviderType.email;
    isPremium = false;
    activeTab = ActiveTab.home;
    previousTab = null;
    energyLevel = null;
    paymentStep = null;
    paymentMethod = null;
    settingsView = SettingsView.main;
    userName = 'Người dùng';
    userEmail = 'user@healthpath.vn';
    accountUserName = '';
    profile = const UserProfile();
    todayCheckedHabits.clear();
    habitCompletingIds.clear();
    promotedRoutineIds.clear();
    dailyCheckinLocked = false;
    teamCheckInToday = false;
    customRoutines = {};
    avatarUrl = null;
    selectedMood = null;
    unawaited(_groupLocalStore.clearActiveGroupId(userEmail));
    _clearTeamState();
    savedPaymentMethods = [];
    premiumInfo = null;
    showSaveCredentials = false;
    savedCredentials = null;
    routines = [];
    routinesError = null;
    routinesLoading = false;
    homeDataLoading = false;
    dailyStreak = 0;
    moodCheckinSyncing = false;
    habitHistory = [];
    notifications = [];
    unreadNotificationCount = 0;
    notificationError = null;
    notifyListeners();
  }

  void setAuthState(AuthState s) {
    authState = s;
    notifyListeners();
  }

  void setEnergyLevel(EnergyLevel? e) {
    if (dailyCheckinLocked) return;
    energyLevel = e;
    _resetPromotedRoutines();
    notifyListeners();
    unawaited(_persistTodayCheckin());
    _maybeLockDailyCheckin();
    _scheduleMoodCheckinSync();
    unawaited(_syncTodayHabitHistory());
  }

  void setSelectedMood(int? m) {
    if (dailyCheckinLocked) return;
    selectedMood = m;
    _resetPromotedRoutines();
    notifyListeners();
    unawaited(_persistTodayCheckin());
    _maybeLockDailyCheckin();
    _scheduleMoodCheckinSync();
    unawaited(_syncTodayHabitHistory());
  }

  void setPaymentStep(PaymentStep? s) {
    paymentStep = s;
    notifyListeners();
  }

  void setPaymentMethod(PaymentMethodType? m) {
    paymentMethod = m;
    notifyListeners();
  }

  void setSettingsView(SettingsView v) {
    settingsView = v;
    if (v == SettingsView.history) {
      unawaited(refreshHabitHistory());
    }
    notifyListeners();
  }

  void setCustomRoutines(Map<int, List<RoutineItem>> r) {
    unawaited(saveCustomWeeklyPlan(r));
  }

  void setHasTeam(bool v, {String? name}) {
    if (v) {
      final mock = GroupRecord(
        id: 'mock-group',
        name: name ?? 'Nhóm Exodia',
        inviteCode: 'MOCK2026',
        memberCount: 4,
      );
      myTeams = [mock];
      _applyActiveGroup(mock);
    } else {
      _clearTeamState();
    }
    notifyListeners();
  }

  void setIsPremium(bool v) {
    isPremium = v;
    notifyListeners();
  }

  void setPremiumInfo(PremiumInfo? info) {
    premiumInfo = info;
    notifyListeners();
  }

  void setProfile(UserProfile p) {
    profile = p.copyWith(email: userEmail);
    _refreshDisplayUserName();
    notifyListeners();
    unawaited(_userProfileStore.save(userEmail, profile));
  }

  void setNotificationSettings(NotificationSettingsRecord settings) {
    notificationSettings = settings;
    notifyListeners();
  }

  Future<void> loadNotificationSettings() async {
    final fetch = _fetchNotificationSettings;
    if (fetch == null || !fetch.isOnline || authState != AuthState.authenticated) {
      return;
    }
    notificationSettingsLoading = true;
    notificationError = null;
    notifyListeners();
    try {
      final res = await fetch();
      if (res.success && res.settings != null) {
        notificationSettings = res.settings!.copyWith(
          soundEnabled: notificationSettings.soundEnabled,
        );
      } else if (!res.success) {
        notificationError = UserFacingMessage.sanitize(
          res.message,
          fallback: 'Không tải được cài đặt thông báo.',
        );
      }
    } finally {
      notificationSettingsLoading = false;
      notifyListeners();
    }
  }

  Future<bool> saveNotificationSettings(
    NotificationSettingsRecord settings,
  ) async {
    final update = _updateNotificationSettings;
    if (update == null || !update.isOnline) {
      notificationSettings = settings;
      notifyListeners();
      return false;
    }
    notificationSettingsLoading = true;
    notifyListeners();
    try {
      final res = await update(settings);
      if (res.success) {
        notificationSettings = (res.settings ?? settings).copyWith(
          soundEnabled: settings.soundEnabled,
        );
        notifyListeners();
        return true;
      }
      notificationError = UserFacingMessage.sanitize(
        res.message,
        fallback: 'Không lưu được cài đặt thông báo.',
      );
      notifyListeners();
      return false;
    } finally {
      notificationSettingsLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshUnreadNotificationCount() async {
    final fetch = _getUnreadNotificationCount;
    if (fetch == null || !fetch.isOnline || authState != AuthState.authenticated) {
      return;
    }
    final res = await fetch();
    if (res.success) {
      unreadNotificationCount = res.unreadCount;
      notifyListeners();
    }
  }

  Future<void> loadNotifications({bool refresh = false}) async {
    final fetch = _fetchNotifications;
    if (fetch == null || !fetch.isOnline || authState != AuthState.authenticated) {
      return;
    }
    if (notificationsLoading && !refresh) return;
    notificationsLoading = true;
    notificationError = null;
    notifyListeners();
    try {
      final res = await fetch(page: 1, pageSize: 50);
      if (res.success) {
        notifications = res.notifications;
      } else {
        notificationError = UserFacingMessage.sanitize(
          res.message,
          fallback: 'Không tải được thông báo.',
        );
      }
    } finally {
      notificationsLoading = false;
      notifyListeners();
      unawaited(refreshUnreadNotificationCount());
    }
  }

  Future<void> markNotificationAsRead(String id) async {
    final mark = _markNotificationRead;
    if (mark == null) return;
    final idx = notifications.indexWhere((n) => n.id == id);
    if (idx >= 0 && !notifications[idx].isRead) {
      notifications = [
        for (var i = 0; i < notifications.length; i++)
          if (i == idx)
            NotificationRecord(
              id: notifications[i].id,
              type: notifications[i].type,
              title: notifications[i].title,
              body: notifications[i].body,
              isRead: true,
              sentAt: notifications[i].sentAt,
              channel: notifications[i].channel,
              data: notifications[i].data,
            )
          else
            notifications[i],
      ];
      if (unreadNotificationCount > 0) unreadNotificationCount--;
      notifyListeners();
    }
    await mark(id);
    unawaited(refreshUnreadNotificationCount());
  }

  Future<void> markAllNotificationsAsRead() async {
    final mark = _markAllNotificationsRead;
    if (mark == null) return;
    notifications = [
      for (final n in notifications)
        NotificationRecord(
          id: n.id,
          type: n.type,
          title: n.title,
          body: n.body,
          isRead: true,
          sentAt: n.sentAt,
          channel: n.channel,
          data: n.data,
        ),
    ];
    unreadNotificationCount = 0;
    notifyListeners();
    await mark();
  }

  Future<void> deleteNotificationItem(String id) async {
    final del = _deleteNotification;
    if (del == null) return;
    final removed = notifications.where((n) => n.id == id).toList();
    notifications = notifications.where((n) => n.id != id).toList();
    if (removed.isNotEmpty &&
        !removed.first.isRead &&
        unreadNotificationCount > 0) {
      unreadNotificationCount--;
    }
    notifyListeners();
    await del(id);
    unawaited(refreshUnreadNotificationCount());
  }

  void setShowSaveCredentials(bool v) {
    showSaveCredentials = v;
    notifyListeners();
  }

  void setSavedCredentials(({String email, String password})? c) {
    savedCredentials = c;
    notifyListeners();
  }

  Future<String?> setTeamCheckInToday(bool v) async {
    if (!v) return null;
    if (teamCheckInToday) return null;

    final groupId = teamGroupId;
    if (groupId == null || groupId.isEmpty) {
      return 'Không xác định được nhóm. Hãy mở lại nhóm từ Quản lý nhóm.';
    }

    final checkIn = _checkInGroup;
    if (checkIn != null && checkIn.isOnline) {
      final res = await checkIn(groupId: groupId);
      if (!res.success) {
        return res.message ?? 'Điểm danh nhóm thất bại.';
      }
    }

    await _teamCheckinStore.recordCheckIn(userEmail, groupId);
    _teamWeekCheckInDates =
        await _teamCheckinStore.weekCheckInDates(userEmail, groupId);
    teamCheckInToday = true;
    await refreshTeamDashboard();
    notifyListeners();
    return null;
  }
}
