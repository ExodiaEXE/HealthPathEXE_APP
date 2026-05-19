import 'package:flutter/foundation.dart';
import 'package:health/core/security/jwt_auth_service.dart';
import 'package:health/shared/data/mock_data.dart';
import 'package:health/shared/models/app_models.dart';

class AppStateProvider extends ChangeNotifier {
  AppStateProvider(this._jwtAuth);

  final JwtAuthService _jwtAuth;

  AuthState authState = AuthState.login;
  AuthProviderType authProvider = AuthProviderType.email;
  bool isPremium = false;
  ActiveTab activeTab = ActiveTab.home;
  ActiveTab? previousTab;
  EnergyLevel? energyLevel;
  PaymentStep? paymentStep;
  PaymentMethodType? paymentMethod;
  String userName = 'Nguoi dung';
  String userEmail = 'user@healthpath.vn';
  UserProfile profile = const UserProfile();
  NotifSettings notifSettings = const NotifSettings();
  List<HabitRecord> habitHistory = MockData.generateMockHistory();
  SettingsView settingsView = SettingsView.main;
  final Set<String> todayCheckedHabits = {};
  bool teamCheckInToday = false;
  Map<int, List<RoutineItem>> customRoutines = {};
  String? avatarUrl;
  int? selectedMood;
  bool moodAutoPlay = false;
  bool hasTeam = false;
  String teamName = 'Nhom Exodia';
  List<SavedPaymentMethod> savedPaymentMethods = [];
  PremiumInfo? premiumInfo;
  bool showSaveCredentials = false;
  ({String email, String password})? savedCredentials;

  final int dailyStreak = 5;

  bool get hasCustomRoutines => customRoutines.isNotEmpty;

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
    final energyHabits = energyLevel != null
        ? List<RoutineItem>.from(MockData.habitsByEnergy[energyLevel]!)
        : <RoutineItem>[];

    if (hasCustomRoutines) {
      final todayIdx = (DateTime.now().weekday - 1) % 7;
      final dayRoutine = customRoutines[todayIdx] ?? [];
      final energyIds = energyHabits.map((h) => h.id).toSet();
      final customFiltered =
          dayRoutine.where((r) => !energyIds.contains(r.id)).toList();
      final merged = [...energyHabits, ...customFiltered];
      if (merged.isNotEmpty) return merged;
    }
    return energyHabits;
  }

  void toggleTodayHabit(String id, String text) {
    if (todayCheckedHabits.contains(id)) {
      todayCheckedHabits.remove(id);
    } else {
      todayCheckedHabits.add(id);
    }
    notifyListeners();
  }

  void addHabitRecord(HabitRecord record) {
    final idx = habitHistory.indexWhere((h) => h.date == record.date);
    if (idx >= 0) {
      habitHistory = [...habitHistory]..[idx] = record;
    } else {
      habitHistory = [...habitHistory, record];
    }
    notifyListeners();
  }

  void updateHistoryRating(String date, int rating) {
    habitHistory = habitHistory
        .map((r) => r.date == date ? HabitRecord(
              date: r.date,
              habits: r.habits,
              energyLevel: r.energyLevel,
              rating: rating,
            ) : r)
        .toList();
    notifyListeners();
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

  Future<void> completeAuth({required String email, String? name}) async {
    if (name != null && name.isNotEmpty) userName = name;
    userEmail = email;
    profile = profile.copyWith(email: email);
    await _jwtAuth.signInMock(email: email);
    authState = AuthState.authenticated;
    notifyListeners();
  }

  Future<void> logout() async {
    await _jwtAuth.signOut();
    authState = AuthState.login;
    authProvider = AuthProviderType.email;
    isPremium = false;
    activeTab = ActiveTab.home;
    previousTab = null;
    energyLevel = null;
    paymentStep = null;
    paymentMethod = null;
    settingsView = SettingsView.main;
    userName = 'Nguoi dung';
    userEmail = 'user@healthpath.vn';
    profile = const UserProfile();
    todayCheckedHabits.clear();
    teamCheckInToday = false;
    customRoutines = {};
    avatarUrl = null;
    selectedMood = null;
    moodAutoPlay = false;
    hasTeam = false;
    teamName = 'Nhom Exodia';
    savedPaymentMethods = [];
    premiumInfo = null;
    showSaveCredentials = false;
    savedCredentials = null;
    notifyListeners();
  }

  void setAuthState(AuthState s) {
    authState = s;
    notifyListeners();
  }

  void setEnergyLevel(EnergyLevel? e) {
    energyLevel = e;
    notifyListeners();
  }

  void setSelectedMood(int? m) {
    selectedMood = m;
    notifyListeners();
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
    notifyListeners();
  }

  void setCustomRoutines(Map<int, List<RoutineItem>> r) {
    customRoutines = r;
    notifyListeners();
  }

  void setHasTeam(bool v, {String? name}) {
    hasTeam = v;
    if (name != null) teamName = name;
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
    profile = p;
    notifyListeners();
  }

  void setNotifSettings(NotifSettings n) {
    notifSettings = n;
    notifyListeners();
  }

  void setShowSaveCredentials(bool v) {
    showSaveCredentials = v;
    notifyListeners();
  }

  void setSavedCredentials(({String email, String password})? c) {
    savedCredentials = c;
    notifyListeners();
  }

  void setTeamCheckInToday(bool v) {
    teamCheckInToday = v;
    notifyListeners();
  }
}
