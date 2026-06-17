import 'dart:async';

import 'package:flutter/material.dart';
import 'package:health/core/constants/app_colors.dart';
import 'package:health/domain/entities/notification_entities.dart';
import 'package:health/shared/models/app_models.dart';
import 'package:health/shared/providers/app_state_provider.dart';
import 'package:health/shared/widgets/app_snackbar.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class NotificationSettingsView extends StatefulWidget {
  const NotificationSettingsView({super.key});

  @override
  State<NotificationSettingsView> createState() =>
      _NotificationSettingsViewState();
}

class _NotificationSettingsViewState extends State<NotificationSettingsView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppStateProvider>().loadNotificationSettings();
    });
  }

  Future<void> _toggle(
    AppStateProvider app,
    NotificationSettingsRecord next,
  ) async {
    final ok = await app.saveNotificationSettings(next);
    if (!mounted) return;
    if (!ok && app.notificationError != null) {
      AppSnackBar.show(context, app.notificationError!);
    }
  }

  Future<void> _pickQuietTime(
    AppStateProvider app, {
    required bool isFrom,
  }) async {
    final current = isFrom
        ? app.notificationSettings.quietFrom
        : app.notificationSettings.quietUntil;
    final picked = await showTimePicker(
      context: context,
      initialTime: current ?? const TimeOfDay(hour: 22, minute: 0),
      helpText: isFrom ? 'Bắt đầu giờ yên lặng' : 'Kết thúc giờ yên lặng',
    );
    if (picked == null || !mounted) return;
    final next = isFrom
        ? app.notificationSettings.copyWith(quietFrom: picked)
        : app.notificationSettings.copyWith(quietUntil: picked);
    await _toggle(app, next);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppStateProvider>();
    final s = app.notificationSettings;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      children: [
        _backHeader('Thông báo', () => app.setSettingsView(SettingsView.main)),
        const SizedBox(height: 12),
        _inboxLink(app),
        const SizedBox(height: 16),
        if (app.notificationSettingsLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            ),
          ),
        _sectionTitle('TỔNG QUAN'),
        const SizedBox(height: 8),
        _toggleCard(
          icon: Icons.notifications_active,
          iconColor: AppColors.accent,
          title: 'Cho phép thông báo',
          subtitle: 'Nhận nhắc nhở và cập nhật từ HealthPath',
          value: s.pushEnabled,
          onToggle: () => _toggle(
            app,
            s.copyWith(pushEnabled: !s.pushEnabled),
          ),
        ),
        const SizedBox(height: 10),
        _toggleCard(
          icon: Icons.volume_up,
          iconColor: const Color(0xFFE8A87C),
          title: 'Âm thanh chuông báo',
          subtitle: 'Phát âm khi có thông báo mới (trên thiết bị)',
          value: s.soundEnabled,
          onToggle: () {
            app.setNotificationSettings(
              s.copyWith(soundEnabled: !s.soundEnabled),
            );
          },
        ),
        const SizedBox(height: 20),
        _sectionTitle('LOẠI THÔNG BÁO'),
        const SizedBox(height: 8),
        _toggleCard(
          icon: Icons.wb_sunny_outlined,
          iconColor: AppColors.primary,
          title: 'Nhắc check-in hàng ngày',
          subtitle: 'Ghi nhận tâm trạng và năng lượng',
          value: s.dailyCheckin,
          enabled: s.pushEnabled,
          onToggle: () =>
              _toggle(app, s.copyWith(dailyCheckin: !s.dailyCheckin)),
        ),
        const SizedBox(height: 10),
        _toggleCard(
          icon: Icons.local_fire_department_outlined,
          iconColor: const Color(0xFFD4855A),
          title: 'Cảnh báo streak',
          subtitle: 'Khi sắp mất chuỗi ngày thói quen',
          value: s.streakReminder,
          enabled: s.pushEnabled,
          onToggle: () =>
              _toggle(app, s.copyWith(streakReminder: !s.streakReminder)),
        ),
        const SizedBox(height: 10),
        _toggleCard(
          icon: Icons.groups_outlined,
          iconColor: const Color(0xFF4A90C8),
          title: 'Hoạt động nhóm',
          subtitle: 'Check-in và tương tác trong nhóm',
          value: s.groupActivity,
          enabled: s.pushEnabled,
          onToggle: () =>
              _toggle(app, s.copyWith(groupActivity: !s.groupActivity)),
        ),
        const SizedBox(height: 10),
        _toggleCard(
          icon: Icons.emoji_events_outlined,
          iconColor: const Color(0xFFE8A87C),
          title: 'Thử thách',
          subtitle: 'Tiến độ và cập nhật thử thách nhóm',
          value: s.challengeUpdates,
          enabled: s.pushEnabled,
          onToggle: () =>
              _toggle(app, s.copyWith(challengeUpdates: !s.challengeUpdates)),
        ),
        const SizedBox(height: 10),
        _toggleCard(
          icon: Icons.local_offer_outlined,
          iconColor: const Color(0xFFD63384),
          title: 'Khuyến mãi',
          subtitle: 'Ưu đãi và gói Premium',
          value: s.promotions,
          enabled: s.pushEnabled,
          onToggle: () => _toggle(app, s.copyWith(promotions: !s.promotions)),
        ),
        const SizedBox(height: 20),
        _sectionTitle('KÊNH & GIỜ YÊN LẶNG'),
        const SizedBox(height: 8),
        _toggleCard(
          icon: Icons.smartphone_outlined,
          iconColor: AppColors.primary,
          title: 'Thông báo trong app',
          subtitle: 'Hiện trong hộp thư HealthPath',
          value: s.inAppEnabled,
          enabled: s.pushEnabled,
          onToggle: () =>
              _toggle(app, s.copyWith(inAppEnabled: !s.inAppEnabled)),
        ),
        const SizedBox(height: 10),
        _toggleCard(
          icon: Icons.email_outlined,
          iconColor: const Color(0xFF4A90C8),
          title: 'Email',
          subtitle: 'Gửi bản sao qua email đã đăng ký',
          value: s.emailEnabled,
          enabled: s.pushEnabled,
          onToggle: () =>
              _toggle(app, s.copyWith(emailEnabled: !s.emailEnabled)),
        ),
        const SizedBox(height: 10),
        _quietHoursCard(app, s),
      ],
    );
  }

  Widget _inboxLink(AppStateProvider app) {
    final count = app.unreadNotificationCount;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => app.setSettingsView(SettingsView.notificationInbox),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8A87C).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.inbox_outlined,
                    size: 18, color: Color(0xFFE8A87C)),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Hộp thư thông báo',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                    SizedBox(height: 2),
                    Text('Xem tất cả thông báo đã nhận',
                        style:
                            TextStyle(fontSize: 11, color: Color(0xFF999999))),
                  ],
                ),
              ),
              if (count > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.coral,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    count > 99 ? '99+' : '$count',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right,
                  size: 16, color: Color(0xFFD4D4D4)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _quietHoursCard(AppStateProvider app, NotificationSettingsRecord s) {
    String fmt(TimeOfDay? t) {
      if (t == null) return 'Chưa đặt';
      final h = t.hour.toString().padLeft(2, '0');
      final m = t.minute.toString().padLeft(2, '0');
      return '$h:$m';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bedtime_outlined, size: 18, color: AppColors.muted),
              SizedBox(width: 8),
              Text('Giờ yên lặng',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Không gửi thông báo trong khoảng thời gian này',
            style: TextStyle(fontSize: 11, color: Color(0xFF999999)),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _timeChip(
                  label: 'Từ',
                  value: fmt(s.quietFrom),
                  onTap: s.pushEnabled
                      ? () => _pickQuietTime(app, isFrom: true)
                      : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _timeChip(
                  label: 'Đến',
                  value: fmt(s.quietUntil),
                  onTap: s.pushEnabled
                      ? () => _pickQuietTime(app, isFrom: false)
                      : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _timeChip({
    required String label,
    required String value,
    VoidCallback? onTap,
  }) {
    return Material(
      color: const Color(0xFFF8F8F8),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(fontSize: 10, color: AppColors.muted)),
              const SizedBox(height: 2),
              Text(value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: onTap != null
                        ? AppColors.foreground
                        : const Color(0xFFBDBDBD),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

class NotificationInboxView extends StatefulWidget {
  const NotificationInboxView({super.key});

  @override
  State<NotificationInboxView> createState() => _NotificationInboxViewState();
}

class _NotificationInboxViewState extends State<NotificationInboxView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppStateProvider>().loadNotifications(refresh: true);
    });
  }

  IconData _iconForType(String type) {
    return switch (type) {
      'daily_checkin' => Icons.wb_sunny_outlined,
      'streak_alert' => Icons.local_fire_department_outlined,
      'group_activity' => Icons.groups_outlined,
      'challenge_update' => Icons.emoji_events_outlined,
      'promotion' => Icons.local_offer_outlined,
      _ => Icons.notifications_outlined,
    };
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppStateProvider>();
    final items = app.notifications;
    final fmt = DateFormat('dd/MM HH:mm');

    return RefreshIndicator(
      onRefresh: () =>
          context.read<AppStateProvider>().loadNotifications(refresh: true),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        children: [
          Row(
            children: [
              Expanded(
                child: _backHeader(
                  'Hộp thư',
                  () => app.setSettingsView(SettingsView.notifications),
                ),
              ),
            if (items.any((n) => !n.isRead))
              TextButton(
                onPressed: () => unawaited(app.markAllNotificationsAsRead()),
                child: const Text('Đọc hết', style: TextStyle(fontSize: 12)),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (app.notificationsLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            ),
          )
        else if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 48),
            child: Column(
              children: [
                Icon(Icons.notifications_none,
                    size: 40, color: AppColors.muted.withValues(alpha: 0.5)),
                const SizedBox(height: 12),
                const Text('Chưa có thông báo',
                    style: TextStyle(color: AppColors.muted)),
              ],
            ),
          )
        else
          ...items.map((n) {
            return Dismissible(
              key: ValueKey(n.id),
              direction: DismissDirection.endToStart,
              onDismissed: (_) => unawaited(app.deleteNotificationItem(n.id)),
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: AppColors.destructive.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.delete_outline,
                    color: AppColors.destructive),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    if (!n.isRead) unawaited(app.markNotificationAsRead(n.id));
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: n.isRead
                          ? Colors.white
                          : AppColors.primary.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: n.isRead
                            ? AppColors.border
                            : AppColors.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(_iconForType(n.type), size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                n.title,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: n.isRead
                                      ? FontWeight.w500
                                      : FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                n.body,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.muted,
                                  height: 1.35,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                fmt.format(n.sentAt.toLocal()),
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFFBBBBBB),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!n.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(top: 4),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

Widget _backHeader(String title, VoidCallback onBack) {
  return Row(
    children: [
      GestureDetector(
        onTap: onBack,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border),
          ),
          child: const Icon(Icons.chevron_left, size: 20),
        ),
      ),
      const SizedBox(width: 12),
      Text(title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
    ],
  );
}

Widget _sectionTitle(String title) {
  return Text(
    title,
    style: const TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.bold,
      color: AppColors.mutedForeground,
      letterSpacing: 1,
    ),
  );
}

Widget _toggleCard({
  required IconData icon,
  required Color iconColor,
  required String title,
  required String subtitle,
  required bool value,
  required VoidCallback onToggle,
  bool enabled = true,
}) {
  final active = enabled && value;
  final dimmed = !enabled;
  return Opacity(
    opacity: dimmed ? 0.55 : 1,
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.foreground)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF999999))),
              ],
            ),
          ),
          GestureDetector(
            onTap: enabled ? onToggle : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 48,
              height: 28,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: active ? AppColors.primary : const Color(0xFFD4D4D4),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                alignment: active ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 24,
                  height: 24,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(color: Color(0x22000000), blurRadius: 4)
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
