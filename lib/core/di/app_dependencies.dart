import 'package:health/core/network/api_client.dart';
import 'package:health/core/persistence/completed_habits_local_store.dart';
import 'package:health/core/persistence/promoted_habits_local_store.dart';
import 'package:health/core/persistence/custom_weekly_routines_local_store.dart';
import 'package:health/core/persistence/group_local_store.dart';
import 'package:health/core/persistence/team_checkin_local_store.dart';
import 'package:health/core/persistence/habit_history_local_store.dart';
import 'package:health/core/persistence/user_profile_local_store.dart';
import 'package:health/core/persistence/daily_checkin_local_store.dart';
import 'package:health/core/security/jwt_auth_service.dart';
import 'package:health/core/security/secure_storage_service.dart';
import 'package:health/data/repositories/audio_repository_impl.dart';
import 'package:health/data/repositories/auth_repository_impl.dart';
import 'package:health/data/repositories/group_repository_impl.dart';
import 'package:health/data/repositories/companion_chat_repository_impl.dart';
import 'package:health/data/repositories/companion_repository_impl.dart';
import 'package:health/data/repositories/mood_checkin_repository_impl.dart';
import 'package:health/data/repositories/notification_repository_impl.dart';
import 'package:health/data/repositories/routine_repository_impl.dart';
import 'package:health/data/repositories/subscription_repository_impl.dart';
import 'package:health/data/repositories/user_routine_repository_impl.dart';
import 'package:health/data/repositories/wellness_repository_impl.dart';
import 'package:health/domain/repositories/auth_repository.dart';
import 'package:health/domain/repositories/companion_repository.dart';
import 'package:health/domain/usecases/companion/companion_usecases.dart';
import 'package:health/domain/repositories/mood_checkin_repository.dart';
import 'package:health/domain/repositories/routine_repository.dart';
import 'package:health/domain/repositories/subscription_repository.dart';
import 'package:health/domain/repositories/user_routine_repository.dart';
import 'package:health/domain/repositories/wellness_repository.dart';
import 'package:health/domain/usecases/auth/change_password_usecase.dart';
import 'package:health/domain/usecases/audio/audio_usecases.dart';
import 'package:health/domain/usecases/group/group_usecases.dart';
import 'package:health/domain/usecases/auth/forgot_password_usecase.dart';
import 'package:health/domain/usecases/auth/login_usecase.dart';
import 'package:health/domain/usecases/auth/register_usecase.dart';
import 'package:health/domain/usecases/auth/reset_password_usecase.dart';
import 'package:health/domain/usecases/auth/resend_verification_otp_usecase.dart';
import 'package:health/domain/usecases/auth/restore_session_usecase.dart';
import 'package:health/domain/usecases/auth/social_login_usecase.dart';
import 'package:health/domain/usecases/auth/user_profile_usecases.dart';
import 'package:health/domain/usecases/auth/verify_register_otp_usecase.dart';
import 'package:health/domain/usecases/companion/companion_chat_usecase.dart';
import 'package:health/domain/usecases/mood_checkin/fetch_mood_stats_usecase.dart';
import 'package:health/domain/usecases/mood_checkin/fetch_today_mood_checkin_usecase.dart';
import 'package:health/domain/usecases/mood_checkin/sync_mood_checkin_usecase.dart';
import 'package:health/domain/usecases/notification/notification_usecases.dart';
import 'package:health/domain/usecases/routine/fetch_routines_usecase.dart';
import 'package:health/domain/usecases/subscription/subscription_usecases.dart';
import 'package:health/domain/usecases/user_routine/complete_today_routine_usecase.dart';
import 'package:health/domain/usecases/user_routine/fetch_today_schedule_usecase.dart';
import 'package:health/domain/usecases/user_routine/weekly_plan_usecases.dart';
import 'package:health/domain/usecases/wellness/wellness_content_usecase.dart';
import 'package:health/features/auth/data/social_auth_service.dart';
import 'package:health/features/subscription/services/play_billing_service.dart';
import 'package:health/features/subscription/services/subscription_billing_coordinator.dart';
import 'package:health/features/companion/providers/companion_provider.dart';
import 'package:health/features/notifications/services/notification_delivery_coordinator.dart';
import 'package:health/shared/providers/app_state_provider.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

/// Gom dependency injection — presentation chỉ nhận interface/use case.
class AppDependencies {
  AppDependencies._({
    required this.storage,
    required this.jwtAuth,
    required this.apiClient,
    required this.authRepository,
    required this.wellnessRepository,
    required this.routineRepository,
    required this.loginUseCase,
    required this.registerUseCase,
    required this.verifyRegisterOtpUseCase,
    required this.resendVerificationOtpUseCase,
    required this.forgotPasswordUseCase,
    required this.changePasswordUseCase,
    required this.resetPasswordUseCase,
    required this.restoreSessionUseCase,
    required this.fetchUserProfileUseCase,
    required this.updateUserProfileUseCase,
    required this.uploadAvatarUseCase,
    required this.subscriptionRepository,
    required this.playBillingService,
    required this.fetchSubscriptionPlansUseCase,
    required this.fetchMySubscriptionUseCase,
    required this.fetchMyTransactionsUseCase,
    required this.verifySubscriptionPurchaseUseCase,
    required this.socialLoginUseCase,
    required this.socialAuthService,
    required this.wellnessContentUseCase,
    required this.fetchRoutinesUseCase,
    required this.moodCheckinRepository,
    required this.syncMoodCheckinUseCase,
    required this.fetchMoodStatsUseCase,
    required this.fetchTodayMoodCheckinUseCase,
    required this.userRoutineRepository,
    required this.completeTodayRoutineUseCase,
    required this.fetchTodayScheduleUseCase,
    required this.dailyCheckinStore,
    required this.completedHabitsStore,
    required this.promotedHabitsStore,
    required this.customWeeklyStore,
    required this.userProfileStore,
    required this.habitHistoryStore,
    required this.groupLocalStore,
    required this.teamCheckinStore,
    required this.createGroupUseCase,
    required this.fetchMyGroupsUseCase,
    required this.fetchPublicGroupsUseCase,
    required this.joinGroupUseCase,
    required this.fetchGroupMembersUseCase,
    required this.fetchGroupChallengesUseCase,
    required this.leaveGroupUseCase,
    required this.checkInGroupUseCase,
    required this.fetchRecurringTemplatesUseCase,
    required this.syncWeeklyPlanUseCase,
    required this.companionRepository,
    required this.companionChatUseCase,
    required this.fetchAudioTracksUseCase,
    required this.fetchAudioCategoriesUseCase,
    required this.getAudioStreamUrlUseCase,
    required this.recordAudioPlayUseCase,
    required this.toggleAudioFavoriteUseCase,
    required this.fetchAudioFavoritesUseCase,
    required this.fetchNotificationSettingsUseCase,
    required this.updateNotificationSettingsUseCase,
    required this.fetchNotificationsUseCase,
    required this.getUnreadNotificationCountUseCase,
    required this.markNotificationReadUseCase,
    required this.markAllNotificationsReadUseCase,
    required this.deleteNotificationUseCase,
  });

  final SecureStorageService storage;
  final JwtAuthService jwtAuth;
  final ApiClient apiClient;
  final AuthRepository authRepository;
  final WellnessRepository wellnessRepository;
  final RoutineRepository routineRepository;
  final LoginUseCase loginUseCase;
  final RegisterUseCase registerUseCase;
  final VerifyRegisterOtpUseCase verifyRegisterOtpUseCase;
  final ResendVerificationOtpUseCase resendVerificationOtpUseCase;
  final ForgotPasswordUseCase forgotPasswordUseCase;
  final ChangePasswordUseCase changePasswordUseCase;
  final ResetPasswordUseCase resetPasswordUseCase;
  final RestoreSessionUseCase restoreSessionUseCase;
  final FetchUserProfileUseCase fetchUserProfileUseCase;
  final UpdateUserProfileUseCase updateUserProfileUseCase;
  final UploadAvatarUseCase uploadAvatarUseCase;
  final SubscriptionRepository subscriptionRepository;
  final PlayBillingService playBillingService;
  final FetchSubscriptionPlansUseCase fetchSubscriptionPlansUseCase;
  final FetchMySubscriptionUseCase fetchMySubscriptionUseCase;
  final FetchMyTransactionsUseCase fetchMyTransactionsUseCase;
  final VerifySubscriptionPurchaseUseCase verifySubscriptionPurchaseUseCase;
  final SocialLoginUseCase socialLoginUseCase;
  final SocialAuthService socialAuthService;
  final WellnessContentUseCase wellnessContentUseCase;
  final FetchRoutinesUseCase fetchRoutinesUseCase;
  final MoodCheckinRepository moodCheckinRepository;
  final SyncMoodCheckinUseCase syncMoodCheckinUseCase;
  final FetchMoodStatsUseCase fetchMoodStatsUseCase;
  final FetchTodayMoodCheckinUseCase fetchTodayMoodCheckinUseCase;
  final UserRoutineRepository userRoutineRepository;
  final CompleteTodayRoutineUseCase completeTodayRoutineUseCase;
  final FetchTodayScheduleUseCase fetchTodayScheduleUseCase;
  final DailyCheckinLocalStore dailyCheckinStore;
  final CompletedHabitsLocalStore completedHabitsStore;
  final PromotedHabitsLocalStore promotedHabitsStore;
  final CustomWeeklyRoutinesLocalStore customWeeklyStore;
  final UserProfileLocalStore userProfileStore;
  final HabitHistoryLocalStore habitHistoryStore;
  final GroupLocalStore groupLocalStore;
  final TeamCheckinLocalStore teamCheckinStore;
  final CreateGroupUseCase createGroupUseCase;
  final FetchMyGroupsUseCase fetchMyGroupsUseCase;
  final FetchPublicGroupsUseCase fetchPublicGroupsUseCase;
  final JoinGroupUseCase joinGroupUseCase;
  final FetchGroupMembersUseCase fetchGroupMembersUseCase;
  final FetchGroupChallengesUseCase fetchGroupChallengesUseCase;
  final LeaveGroupUseCase leaveGroupUseCase;
  final CheckInGroupUseCase checkInGroupUseCase;
  final FetchRecurringTemplatesUseCase fetchRecurringTemplatesUseCase;
  final SyncWeeklyPlanUseCase syncWeeklyPlanUseCase;
  final CompanionRepository companionRepository;
  final CompanionChatUseCase companionChatUseCase;
  final FetchAudioTracksUseCase fetchAudioTracksUseCase;
  final FetchAudioCategoriesUseCase fetchAudioCategoriesUseCase;
  final GetAudioStreamUrlUseCase getAudioStreamUrlUseCase;
  final RecordAudioPlayUseCase recordAudioPlayUseCase;
  final ToggleAudioFavoriteUseCase toggleAudioFavoriteUseCase;
  final FetchAudioFavoritesUseCase fetchAudioFavoritesUseCase;
  final FetchNotificationSettingsUseCase fetchNotificationSettingsUseCase;
  final UpdateNotificationSettingsUseCase updateNotificationSettingsUseCase;
  final FetchNotificationsUseCase fetchNotificationsUseCase;
  final GetUnreadNotificationCountUseCase getUnreadNotificationCountUseCase;
  final MarkNotificationReadUseCase markNotificationReadUseCase;
  final MarkAllNotificationsReadUseCase markAllNotificationsReadUseCase;
  final DeleteNotificationUseCase deleteNotificationUseCase;

  factory AppDependencies.create() {
    final storage = SecureStorageService();
    final jwtAuth = JwtAuthService(storage);
    final apiClient = ApiClient();
    final authRepository = AuthRepositoryImpl(api: apiClient, storage: storage);
    final subscriptionRepository =
        SubscriptionRepositoryImpl(api: apiClient, storage: storage);
    final playBillingService = PlayBillingService();
    final verifySubscriptionPurchaseUseCase =
        VerifySubscriptionPurchaseUseCase(subscriptionRepository);
    SubscriptionBillingCoordinator.configure(
      billing: playBillingService,
      verifyPurchase: verifySubscriptionPurchaseUseCase,
    );
    final wellnessRepository = WellnessRepositoryImpl();
    final routineRepository = RoutineRepositoryImpl(api: apiClient);
    final moodCheckinRepository = MoodCheckinRepositoryImpl(storage: storage);
    final userRoutineRepository = UserRoutineRepositoryImpl(storage: storage);
    final dailyCheckinStore = DailyCheckinLocalStore();
    final completedHabitsStore = CompletedHabitsLocalStore();
    final promotedHabitsStore = PromotedHabitsLocalStore();
    final customWeeklyStore = CustomWeeklyRoutinesLocalStore();
    final userProfileStore = UserProfileLocalStore();
    final habitHistoryStore = HabitHistoryLocalStore();
    final groupLocalStore = GroupLocalStore();
    final teamCheckinStore = TeamCheckinLocalStore();
    final groupRepository = GroupRepositoryImpl(api: apiClient, storage: storage);
    final audioRepository = AudioRepositoryImpl(api: apiClient, storage: storage);
    final notificationRepository =
        NotificationRepositoryImpl(api: apiClient, storage: storage);
    final companionRepository =
        CompanionRepositoryImpl(api: apiClient, storage: storage);
    final companionChatRepository = CompanionChatRepositoryImpl();
    final socialAuthService = createSocialAuthService();
    final fetchRecurringTemplatesUseCase =
        FetchRecurringTemplatesUseCase(userRoutineRepository);
    final syncWeeklyPlanUseCase =
        SyncWeeklyPlanUseCase(userRoutineRepository);
    final registerDeviceTokenUseCase =
        RegisterDeviceTokenUseCase(notificationRepository);
    final removeDeviceTokenUseCase =
        RemoveDeviceTokenUseCase(notificationRepository);

    NotificationDeliveryCoordinator.configure(
      registerToken: registerDeviceTokenUseCase,
      removeToken: removeDeviceTokenUseCase,
      fetchNotifications: FetchNotificationsUseCase(notificationRepository),
      readAccessToken: storage.readAccessToken,
    );

    return AppDependencies._(
      storage: storage,
      jwtAuth: jwtAuth,
      apiClient: apiClient,
      authRepository: authRepository,
      wellnessRepository: wellnessRepository,
      routineRepository: routineRepository,
      loginUseCase: LoginUseCase(authRepository),
      registerUseCase: RegisterUseCase(authRepository),
      verifyRegisterOtpUseCase: VerifyRegisterOtpUseCase(authRepository),
      resendVerificationOtpUseCase: ResendVerificationOtpUseCase(authRepository),
      forgotPasswordUseCase: ForgotPasswordUseCase(authRepository),
      changePasswordUseCase: ChangePasswordUseCase(authRepository),
      resetPasswordUseCase: ResetPasswordUseCase(authRepository),
      restoreSessionUseCase: RestoreSessionUseCase(authRepository),
      fetchUserProfileUseCase: FetchUserProfileUseCase(authRepository),
      updateUserProfileUseCase: UpdateUserProfileUseCase(authRepository),
      uploadAvatarUseCase: UploadAvatarUseCase(authRepository),
      subscriptionRepository: subscriptionRepository,
      playBillingService: playBillingService,
      fetchSubscriptionPlansUseCase:
          FetchSubscriptionPlansUseCase(subscriptionRepository),
      fetchMySubscriptionUseCase:
          FetchMySubscriptionUseCase(subscriptionRepository),
      fetchMyTransactionsUseCase:
          FetchMyTransactionsUseCase(subscriptionRepository),
      verifySubscriptionPurchaseUseCase: verifySubscriptionPurchaseUseCase,
      socialLoginUseCase: SocialLoginUseCase(authRepository),
      socialAuthService: socialAuthService,
      wellnessContentUseCase: WellnessContentUseCase(wellnessRepository),
      fetchRoutinesUseCase: FetchRoutinesUseCase(routineRepository),
      moodCheckinRepository: moodCheckinRepository,
      syncMoodCheckinUseCase: SyncMoodCheckinUseCase(moodCheckinRepository),
      fetchMoodStatsUseCase: FetchMoodStatsUseCase(moodCheckinRepository),
      fetchTodayMoodCheckinUseCase:
          FetchTodayMoodCheckinUseCase(moodCheckinRepository),
      userRoutineRepository: userRoutineRepository,
      completeTodayRoutineUseCase:
          CompleteTodayRoutineUseCase(userRoutineRepository),
      fetchTodayScheduleUseCase:
          FetchTodayScheduleUseCase(userRoutineRepository),
      dailyCheckinStore: dailyCheckinStore,
      completedHabitsStore: completedHabitsStore,
      promotedHabitsStore: promotedHabitsStore,
      customWeeklyStore: customWeeklyStore,
      userProfileStore: userProfileStore,
      habitHistoryStore: habitHistoryStore,
      groupLocalStore: groupLocalStore,
      teamCheckinStore: teamCheckinStore,
      createGroupUseCase: CreateGroupUseCase(groupRepository),
      fetchMyGroupsUseCase: FetchMyGroupsUseCase(groupRepository),
      fetchPublicGroupsUseCase: FetchPublicGroupsUseCase(groupRepository),
      joinGroupUseCase: JoinGroupUseCase(groupRepository),
      fetchGroupMembersUseCase: FetchGroupMembersUseCase(groupRepository),
      fetchGroupChallengesUseCase: FetchGroupChallengesUseCase(groupRepository),
      leaveGroupUseCase: LeaveGroupUseCase(groupRepository),
      checkInGroupUseCase: CheckInGroupUseCase(groupRepository),
      fetchRecurringTemplatesUseCase: fetchRecurringTemplatesUseCase,
      syncWeeklyPlanUseCase: syncWeeklyPlanUseCase,
      companionRepository: companionRepository,
      companionChatUseCase: CompanionChatUseCase(companionChatRepository),
      fetchAudioTracksUseCase: FetchAudioTracksUseCase(audioRepository),
      fetchAudioCategoriesUseCase: FetchAudioCategoriesUseCase(audioRepository),
      getAudioStreamUrlUseCase: GetAudioStreamUrlUseCase(audioRepository),
      recordAudioPlayUseCase: RecordAudioPlayUseCase(audioRepository),
      toggleAudioFavoriteUseCase: ToggleAudioFavoriteUseCase(audioRepository),
      fetchAudioFavoritesUseCase:
          FetchAudioFavoritesUseCase(audioRepository),
      fetchNotificationSettingsUseCase:
          FetchNotificationSettingsUseCase(notificationRepository),
      updateNotificationSettingsUseCase:
          UpdateNotificationSettingsUseCase(notificationRepository),
      fetchNotificationsUseCase:
          FetchNotificationsUseCase(notificationRepository),
      getUnreadNotificationCountUseCase:
          GetUnreadNotificationCountUseCase(notificationRepository),
      markNotificationReadUseCase:
          MarkNotificationReadUseCase(notificationRepository),
      markAllNotificationsReadUseCase:
          MarkAllNotificationsReadUseCase(notificationRepository),
      deleteNotificationUseCase:
          DeleteNotificationUseCase(notificationRepository),
    );
  }

  List<SingleChildWidget> providers() => [
        Provider<SecureStorageService>.value(value: storage),
        Provider<JwtAuthService>.value(value: jwtAuth),
        Provider<ApiClient>.value(value: apiClient),
        Provider<AuthRepository>.value(value: authRepository),
        Provider<SubscriptionRepository>.value(value: subscriptionRepository),
        Provider<PlayBillingService>.value(value: playBillingService),
        Provider<FetchSubscriptionPlansUseCase>.value(
            value: fetchSubscriptionPlansUseCase),
        Provider<FetchMySubscriptionUseCase>.value(
            value: fetchMySubscriptionUseCase),
        Provider<FetchMyTransactionsUseCase>.value(
            value: fetchMyTransactionsUseCase),
        Provider<VerifySubscriptionPurchaseUseCase>.value(
            value: verifySubscriptionPurchaseUseCase),
        Provider<WellnessRepository>.value(value: wellnessRepository),
        Provider<RoutineRepository>.value(value: routineRepository),
        Provider<LoginUseCase>.value(value: loginUseCase),
        Provider<RegisterUseCase>.value(value: registerUseCase),
        Provider<VerifyRegisterOtpUseCase>.value(value: verifyRegisterOtpUseCase),
        Provider<ResendVerificationOtpUseCase>.value(value: resendVerificationOtpUseCase),
        Provider<ForgotPasswordUseCase>.value(value: forgotPasswordUseCase),
        Provider<ChangePasswordUseCase>.value(value: changePasswordUseCase),
        Provider<ResetPasswordUseCase>.value(value: resetPasswordUseCase),
        Provider<RestoreSessionUseCase>.value(value: restoreSessionUseCase),
        Provider<FetchUserProfileUseCase>.value(value: fetchUserProfileUseCase),
        Provider<UpdateUserProfileUseCase>.value(value: updateUserProfileUseCase),
        Provider<UploadAvatarUseCase>.value(value: uploadAvatarUseCase),
        Provider<SocialLoginUseCase>.value(value: socialLoginUseCase),
        Provider<SocialAuthService>.value(value: socialAuthService),
        Provider<WellnessContentUseCase>.value(value: wellnessContentUseCase),
        Provider<FetchRoutinesUseCase>.value(value: fetchRoutinesUseCase),
        Provider<MoodCheckinRepository>.value(value: moodCheckinRepository),
        Provider<SyncMoodCheckinUseCase>.value(value: syncMoodCheckinUseCase),
        Provider<FetchMoodStatsUseCase>.value(value: fetchMoodStatsUseCase),
        Provider<FetchTodayMoodCheckinUseCase>.value(
            value: fetchTodayMoodCheckinUseCase),
        Provider<UserRoutineRepository>.value(value: userRoutineRepository),
        Provider<CompleteTodayRoutineUseCase>.value(
            value: completeTodayRoutineUseCase),
        Provider<FetchTodayScheduleUseCase>.value(
            value: fetchTodayScheduleUseCase),
        Provider<CompanionRepository>.value(value: companionRepository),
        Provider<CompanionChatUseCase>.value(value: companionChatUseCase),
        ChangeNotifierProvider(
          create: (_) => CompanionProvider(
            fetchState: FetchCompanionStateUseCase(companionRepository),
            fetchAssets: FetchCompanionAssetsUseCase(companionRepository),
            feed: FeedCompanionUseCase(companionRepository),
            pet: PetCompanionUseCase(companionRepository),
            fetchMissions: FetchCompanionMissionsUseCase(companionRepository),
            fetchCatalog: FetchCompanionCatalogUseCase(companionRepository),
            purchase: PurchaseCompanionItemUseCase(companionRepository),
            equip: EquipCompanionItemUseCase(companionRepository),
            setRoomTheme: SetCompanionRoomThemeUseCase(companionRepository),
          ),
        ),
        Provider<FetchAudioFavoritesUseCase>.value(
            value: fetchAudioFavoritesUseCase),
        Provider<FetchNotificationSettingsUseCase>.value(
            value: fetchNotificationSettingsUseCase),
        Provider<UpdateNotificationSettingsUseCase>.value(
            value: updateNotificationSettingsUseCase),
        Provider<FetchNotificationsUseCase>.value(
            value: fetchNotificationsUseCase),
        Provider<GetUnreadNotificationCountUseCase>.value(
            value: getUnreadNotificationCountUseCase),
        Provider<MarkNotificationReadUseCase>.value(
            value: markNotificationReadUseCase),
        Provider<MarkAllNotificationsReadUseCase>.value(
            value: markAllNotificationsReadUseCase),
        Provider<DeleteNotificationUseCase>.value(
            value: deleteNotificationUseCase),
        ChangeNotifierProvider(
          create: (ctx) => AppStateProvider(
            jwtAuth: jwtAuth,
            restoreSession: restoreSessionUseCase,
            fetchUserProfile: fetchUserProfileUseCase,
            fetchMySubscription: fetchMySubscriptionUseCase,
            fetchMyTransactions: fetchMyTransactionsUseCase,
            wellness: wellnessContentUseCase,
            fetchRoutines: fetchRoutinesUseCase,
            syncMoodCheckin: syncMoodCheckinUseCase,
            fetchMoodStats: fetchMoodStatsUseCase,
            fetchTodayMoodCheckin: fetchTodayMoodCheckinUseCase,
            completeTodayRoutine: completeTodayRoutineUseCase,
            fetchTodaySchedule: fetchTodayScheduleUseCase,
            dailyCheckinStore: dailyCheckinStore,
            completedHabitsStore: completedHabitsStore,
            promotedHabitsStore: promotedHabitsStore,
            customWeeklyStore: customWeeklyStore,
            userProfileStore: userProfileStore,
            habitHistoryStore: habitHistoryStore,
            groupLocalStore: groupLocalStore,
            teamCheckinStore: teamCheckinStore,
            createGroup: createGroupUseCase,
            fetchMyGroups: fetchMyGroupsUseCase,
            fetchPublicGroups: fetchPublicGroupsUseCase,
            joinGroup: joinGroupUseCase,
            fetchGroupMembers: fetchGroupMembersUseCase,
            fetchGroupChallenges: fetchGroupChallengesUseCase,
            leaveGroup: leaveGroupUseCase,
            checkInGroup: checkInGroupUseCase,
            fetchRecurringTemplates: fetchRecurringTemplatesUseCase,
            syncWeeklyPlan: syncWeeklyPlanUseCase,
            fetchAudioTracks: fetchAudioTracksUseCase,
            fetchAudioCategories: fetchAudioCategoriesUseCase,
            getAudioStreamUrl: getAudioStreamUrlUseCase,
            recordAudioPlay: recordAudioPlayUseCase,
            toggleAudioFavorite: toggleAudioFavoriteUseCase,
            fetchNotificationSettings: fetchNotificationSettingsUseCase,
            updateNotificationSettings: updateNotificationSettingsUseCase,
            fetchNotifications: fetchNotificationsUseCase,
            getUnreadNotificationCount: getUnreadNotificationCountUseCase,
            markNotificationRead: markNotificationReadUseCase,
            markAllNotificationsRead: markAllNotificationsReadUseCase,
            deleteNotification: deleteNotificationUseCase,
          ),
        ),
      ];
}
