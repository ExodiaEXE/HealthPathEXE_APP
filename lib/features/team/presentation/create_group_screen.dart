import 'package:flutter/material.dart';
import 'package:health/core/constants/app_colors.dart';
import 'package:health/shared/providers/app_state_provider.dart';
import 'package:health/shared/widgets/app_snackbar.dart';
import 'package:health/shared/widgets/profile_text_field.dart';
import 'package:provider/provider.dart';

/// Màn tạo nhóm — route riêng để không bị rebuild từ AppShell/TeamScreen khi đang gõ.
class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  static const _maxNameLength = 30;
  static const _maxDescriptionLength = 200;

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();
    if (name.isEmpty) {
      _showMessage('Vui lòng nhập tên nhóm');
      return;
    }
    if (name.length > _maxNameLength) {
      _showMessage('Tên nhóm tối đa $_maxNameLength ký tự');
      return;
    }
    if (description.length > _maxDescriptionLength) {
      _showMessage('Mô tả tối đa $_maxDescriptionLength ký tự');
      return;
    }

    setState(() => _submitting = true);
    final app = context.read<AppStateProvider>();
    final ok = await app.createTeam(
      name,
      description: description.isEmpty ? null : description,
    );
    if (!mounted) return;
    setState(() => _submitting = false);

    if (ok) {
      Navigator.of(context).pop(true);
      return;
    }
    if (app.teamError != null) {
      _showMessage(app.teamError!);
    }
  }

  void _showMessage(String message) {
    AppSnackBar.show(context, message);
  }

  Widget _buildGroupHighlightCard() {
    const perks = [
      ('🏆', 'Thử thách tuần cùng nhau'),
      ('📈', 'Bảng xếp hạng động lực'),
      ('🤝', 'Cổ vũ khi bạn bè cần'),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.08),
            AppColors.accent.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary.withValues(alpha: 0.12),
                      ),
                    ),
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.accent.withValues(alpha: 0.14),
                      ),
                      child: const Icon(
                        Icons.groups_rounded,
                        size: 34,
                        color: AppColors.primary,
                      ),
                    ),
                    const Positioned(
                      right: 52,
                      top: 8,
                      child: Text('💪', style: TextStyle(fontSize: 20)),
                    ),
                    const Positioned(
                      left: 52,
                      bottom: 8,
                      child: Text('🌿', style: TextStyle(fontSize: 18)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'Cùng nhau bền bỉ hơn',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.foreground,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Mời bạn bè tham gia sau khi tạo nhóm',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'NHÓM GIÚP BẠN',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.muted,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 10),
          ...perks.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Text(item.$1, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item.$2,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.foreground,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: _submitting
                              ? null
                              : () => Navigator.of(context).pop(),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: const BoxDecoration(
                              color: Color(0xFFF5F5F5),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.chevron_left,
                              size: 20,
                              color: AppColors.foreground,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Tạo nhóm mới',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.foreground,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Center(
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.groups,
                          size: 32,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ProfileTextField(
                      key: const ValueKey('team-create-name'),
                      controller: _nameController,
                      label: 'Tên nhóm',
                      icon: Icons.groups_outlined,
                      placeholder: 'VD: Nhóm Sức Khỏe',
                    ),
                    const SizedBox(height: 16),
                    ProfileTextField(
                      key: const ValueKey('team-create-description'),
                      controller: _descriptionController,
                      label: 'Mô tả nhóm',
                      icon: Icons.notes_outlined,
                      placeholder:
                          'VD: Nhóm cùng nhau rèn luyện sức khỏe và động viên lẫn nhau',
                      helper:
                          'Giúp thành viên hiểu mục tiêu của nhóm (không bắt buộc)',
                      keyboardType: TextInputType.multiline,
                      minLines: 3,
                      maxLines: 5,
                    ),
                    const SizedBox(height: 20),
                    _buildGroupHighlightCard(),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: GestureDetector(
                onTap: _submitting ? null : _submit,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 48,
                  decoration: BoxDecoration(
                    color: _submitting
                        ? AppColors.primary.withValues(alpha: 0.6)
                        : AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _submitting ? 'Đang tạo...' : 'Tạo nhóm',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
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
}
