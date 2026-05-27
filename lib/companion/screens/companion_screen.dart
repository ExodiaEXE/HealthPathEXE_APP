import 'package:flutter/material.dart';
import 'package:health/companion/models/companion_message.dart';
import 'package:health/companion/services/companion_mock_service.dart';
import 'package:health/core/constants/app_colors.dart';
import 'package:health/shared/widgets/hp_tap_scale.dart';

class CompanionScreen extends StatefulWidget {
  const CompanionScreen({super.key});

  @override
  State<CompanionScreen> createState() => _CompanionScreenState();
}

class _CompanionScreenState extends State<CompanionScreen> {
  final _service = CompanionMockService();
  final _messages = <CompanionMessage>[];
  final _input = TextEditingController();
  final _scrollController = ScrollController();
  bool _loading = false;

  static const _quickChips = [
    ('🌿', 'Thủ thỉ'),
    ('🏠', 'Mở nhạc'),
    ('📋', 'Cần nghỉ'),
    ('⚙️', 'Tâm trạng'),
  ];

  @override
  void initState() {
    super.initState();
    _messages.add(CompanionMessage(
      id: 'greeting',
      text:
          'Chào Người dùng, mình là Xanh. Rất vui được gặp lại bạn! Hôm nay của bạn thế nào rồi? Có điều gì muốn chia sẻ không?',
      isUser: false,
      timestamp: DateTime.now(),
    ));
  }

  @override
  void dispose() {
    _input.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send(String text) async {
    if (text.trim().isEmpty || _loading) return;
    setState(() {
      _messages.add(_service.userMessage(text.trim()));
      _loading = true;
      _input.clear();
    });
    _scrollToBottom();
    final reply = await _service.assistantMessage(text);
    if (!mounted) return;
    setState(() {
      _messages.add(reply);
      _loading = false;
    });
    _scrollToBottom();
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildMessages()),
            if (_loading) _buildTypingIndicator(),
            _buildQuickChips(),
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          HpTapScale(
            scale: 0.9,
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Color(0xFFF5F5F5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.chevron_left, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Text('🌿', style: TextStyle(fontSize: 18)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Xanh',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.foreground,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Luôn ở đây với bạn',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessages() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _messages.length,
      itemBuilder: (_, i) {
        final m = _messages[i];
        return _buildMessageBubble(m);
      },
    );
  }

  Widget _buildMessageBubble(CompanionMessage msg) {
    final isUser = msg.isUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!isUser)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🌿', style: TextStyle(fontSize: 10)),
                  const SizedBox(width: 3),
                  Text(
                    'Xanh',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width * 0.75,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isUser
                  ? AppColors.primary
                  : const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(isUser ? 20 : 6),
                bottomRight: Radius.circular(isUser ? 6 : 20),
              ),
            ),
            child: Text(
              msg.text,
              style: TextStyle(
                fontSize: 13,
                color: isUser ? Colors.white : AppColors.foreground,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            _formatTime(msg.timestamp),
            style: const TextStyle(fontSize: 9, color: AppColors.muted),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                return Padding(
                  padding: EdgeInsets.only(right: i < 2 ? 4 : 0),
                  child: _TypingDot(delay: i * 200),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickChips() {
    return Container(
      height: 44,
      padding: const EdgeInsets.only(bottom: 6),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _quickChips.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final chip = _quickChips[i];
          return HpTapScale(
            scale: 0.95,
            onTap: () => _send(chip.$2),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(chip.$1, style: const TextStyle(fontSize: 12)),
                  const SizedBox(width: 4),
                  Text(
                    chip.$2,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.foreground,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _input,
                onSubmitted: _send,
                style: const TextStyle(fontSize: 13),
                decoration: const InputDecoration(
                  hintText: 'Gửi tin nhắn cho Xanh...',
                  hintStyle: TextStyle(
                    fontSize: 13,
                    color: Color(0xFFAAAAAA),
                  ),
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  isDense: true,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          HpTapScale(
            scale: 0.9,
            onTap: () => _send(_input.text),
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send, size: 16, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypingDot extends StatefulWidget {
  const _TypingDot({required this.delay});
  final int delay;

  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        return Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: AppColors.muted.withValues(alpha: 0.4 + 0.6 * _animation.value),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}

