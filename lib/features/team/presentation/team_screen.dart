import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:health/core/constants/app_colors.dart';
import 'package:health/shared/data/mock_data.dart';
import 'package:health/shared/providers/app_state_provider.dart';
import 'package:health/shared/widgets/hp_button.dart';
import 'package:provider/provider.dart';

class TeamScreen extends StatefulWidget {
  const TeamScreen({super.key});

  @override
  State<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends State<TeamScreen> {
  String _noTeamPage = 'main';
  final _newGroupName = TextEditingController();
  final _joinSearch = TextEditingController();
  final _cheered = <int>{};

  @override
  void dispose() {
    _newGroupName.dispose();
    _joinSearch.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppStateProvider>();
    if (!app.hasTeam) return _buildNoTeamView(app);
    return _teamDashboard(app);
  }

  Widget _buildNoTeamView(AppStateProvider app) {
    if (_noTeamPage == 'create') {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            IconButton(alignment: Alignment.centerLeft, onPressed: () => setState(() => _noTeamPage = 'main'), icon: const Icon(Icons.arrow_back)),
            const Text('Tao nhom moi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(controller: _newGroupName, decoration: const InputDecoration(hintText: 'Ten nhom')),
            const SizedBox(height: 16),
            HpPrimaryButton(
              label: 'Tao nhom',
              onPressed: () {
                if (_newGroupName.text.trim().isEmpty) return;
                app.setHasTeam(true, name: _newGroupName.text.trim());
                setState(() => _noTeamPage = 'main');
              },
            ),
          ],
        ),
      );
    }
    if (_noTeamPage == 'join') {
      final groups = MockData.existingGroups
          .where((g) => g.name.toLowerCase().contains(_joinSearch.text.toLowerCase()))
          .toList();
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Align(alignment: Alignment.centerLeft, child: IconButton(onPressed: () => setState(() => _noTeamPage = 'main'), icon: const Icon(Icons.arrow_back))),
                TextField(controller: _joinSearch, onChanged: (_) => setState(() {}), decoration: const InputDecoration(hintText: 'Tim nhom...', prefixIcon: Icon(Icons.search))),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: groups.length,
              itemBuilder: (_, i) {
                final g = groups[i];
                return Card(
                  child: ListTile(
                    leading: Text(g.emoji, style: const TextStyle(fontSize: 24)),
                    title: Text(g.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${g.members} thanh vien'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      app.setHasTeam(true, name: g.name);
                      setState(() => _noTeamPage = 'main');
                    },
                  ),
                );
              },
            ),
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      children: [
        const Text('Nhom', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 24),
        const Center(child: Icon(Icons.groups, size: 64, color: AppColors.accent)),
        const SizedBox(height: 12),
        const Text('Ban chua co nhom', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
        const Text('Tao nhom moi hoac tham gia nhom da co san', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: AppColors.muted)),
        const SizedBox(height: 24),
        HpPrimaryButton(label: 'Tao nhom moi', onPressed: () => setState(() => _noTeamPage = 'create')),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () => setState(() => _noTeamPage = 'join'),
          child: const Text('Tham gia nhom'),
        ),
      ],
    );
  }

  Widget _teamDashboard(AppStateProvider app) {
    final inviteCode = 'HP-${app.teamName.replaceAll(' ', '').substring(0, app.teamName.length.clamp(0, 4)).toUpperCase()}-2026';
    final habits = app.getActiveHabits();
    final completed = habits.where((h) => app.todayCheckedHabits.contains(h.id)).length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      children: [
        Row(
          children: [
            Expanded(child: Text(app.teamName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
            IconButton(icon: const Icon(Icons.share), onPressed: () => Clipboard.setData(ClipboardData(text: inviteCode))),
          ],
        ),
        Card(
          color: AppColors.accent.withValues(alpha: 0.08),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text('65%', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.accent)),
                const Text('Tien do thu thach 7 ngay', style: TextStyle(fontSize: 12)),
                const SizedBox(height: 8),
                LinearProgressIndicator(value: 0.65, color: AppColors.accent, backgroundColor: Colors.white),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (!app.teamCheckInToday)
          HpPrimaryButton(
            label: 'Check-in hom nay',
            onPressed: () => app.setTeamCheckInToday(true),
          )
        else
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.check_circle, color: AppColors.primary), SizedBox(width: 8), Text('Da check-in hom nay!', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold))]),
          ),
        const SizedBox(height: 16),
        const Text('Bang xep hang', style: TextStyle(fontWeight: FontWeight.bold)),
        ...MockData.teamMembers.map((m) {
          return Card(
            child: ListTile(
              leading: CircleAvatar(child: Text(m.avatar)),
              title: Text(m.name, style: TextStyle(fontWeight: m.isMe ? FontWeight.bold : FontWeight.normal)),
              subtitle: Text('🔥 ${m.streak} ngay'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${m.score}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                  if (!m.isMe)
                    IconButton(
                      icon: Icon(_cheered.contains(m.id) ? Icons.favorite : Icons.favorite_border, color: AppColors.coral, size: 20),
                      onPressed: () => setState(() => _cheered.add(m.id)),
                    ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 8),
        Text('Viec nho hom nay ($completed/${habits.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        ...habits.map((h) {
          final done = app.todayCheckedHabits.contains(h.id);
          return CheckboxListTile(
            value: done,
            onChanged: (_) => app.toggleTodayHabit(h.id, h.text),
            title: Text(h.text, style: TextStyle(fontSize: 13, decoration: done ? TextDecoration.lineThrough : null)),
            activeColor: AppColors.primary,
          );
        }),
        ListTile(
          title: const Text('Ma moi', style: TextStyle(fontSize: 12)),
          subtitle: Text(inviteCode, style: const TextStyle(fontWeight: FontWeight.bold)),
          trailing: IconButton(icon: const Icon(Icons.copy), onPressed: () => Clipboard.setData(ClipboardData(text: inviteCode))),
        ),
      ],
    );
  }
}
