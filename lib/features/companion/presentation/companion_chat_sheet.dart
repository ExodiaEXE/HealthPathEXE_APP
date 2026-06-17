import 'package:flutter/material.dart';
import 'package:health/features/companion/presentation/companion_screen.dart';

/// Chat Xanh — bottom sheet từ hub pet.
class CompanionChatSheet extends StatelessWidget {
  const CompanionChatSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: const CompanionScreen(embedInSheet: true),
        );
      },
    );
  }
}
