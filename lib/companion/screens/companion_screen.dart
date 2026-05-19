import 'package:flutter/material.dart';
import 'package:health/companion/models/companion_message.dart';
import 'package:health/companion/services/companion_mock_service.dart';
import 'package:health/core/constants/app_colors.dart';

/// AI companion chat — reusable screen (not in bottom nav by default).
class CompanionScreen extends StatefulWidget {
  const CompanionScreen({super.key});

  @override
  State<CompanionScreen> createState() => _CompanionScreenState();
}

class _CompanionScreenState extends State<CompanionScreen> {
  final _service = CompanionMockService();
  final _messages = <CompanionMessage>[];
  final _input = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _send(String text) async {
    if (text.trim().isEmpty || _loading) return;
    setState(() {
      _messages.add(_service.userMessage(text.trim()));
      _loading = true;
      _input.clear();
    });
    final reply = await _service.assistantMessage(text);
    if (!mounted) return;
    setState(() {
      _messages.add(reply);
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Companion')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (_, i) {
                final m = _messages[i];
                return Align(
                  alignment: m.isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.75),
                    decoration: BoxDecoration(
                      color: m.isUser ? AppColors.primary : AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(m.text, style: TextStyle(color: m.isUser ? Colors.white : AppColors.foreground, fontSize: 13)),
                  ),
                );
              },
            ),
          ),
          if (_loading) const LinearProgressIndicator(minHeight: 2),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: CompanionMockService.quickChips.map((c) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(label: Text(c, style: const TextStyle(fontSize: 11)), onPressed: () => _send(c)),
                );
              }).toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _input,
                    decoration: const InputDecoration(hintText: 'Nhap tin nhan...'),
                    onSubmitted: _send,
                  ),
                ),
                IconButton(icon: const Icon(Icons.send, color: AppColors.primary), onPressed: () => _send(_input.text)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
