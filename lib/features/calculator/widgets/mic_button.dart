import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ai_powered_voice_calculator/models/speech_state.dart';

class MicButton extends ConsumerStatefulWidget {
  final MicStatus status;
  final VoidCallback onTap;

  const MicButton({super.key, required this.status, required this.onTap});

  @override
  ConsumerState<MicButton> createState() => _MicButtonState();
}

class _MicButtonState extends ConsumerState<MicButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _scale = Tween<double>(
      begin: 1.0,
      end: 1.18,
    ).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Color get _bgColor {
    return switch (widget.status) {
      MicStatus.listening => const Color(0xFFEF4444),
      MicStatus.processing => const Color(0xFFF59E0B),
      MicStatus.error => const Color(0xFF6B7280),
      MicStatus.idle => const Color(0xFF6366F1),
    };
  }

  IconData get _icon {
    return switch (widget.status) {
      MicStatus.listening => Icons.mic,
      MicStatus.processing => Icons.hourglass_top_rounded,
      MicStatus.error => Icons.mic_off,
      MicStatus.idle => Icons.mic_none_rounded,
    };
  }

  @override
  Widget build(BuildContext context) {
    final isListening = widget.status == MicStatus.listening;

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (_, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              if (isListening)
                Transform.scale(
                  scale: _scale.value * 1.3,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _bgColor.withOpacity(0.15),
                    ),
                  ),
                ),
              if (isListening)
                Transform.scale(
                  scale: _scale.value * 1.15,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _bgColor.withOpacity(0.25),
                    ),
                  ),
                ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _bgColor,
                  boxShadow: [
                    BoxShadow(
                      color: _bgColor.withOpacity(0.4),
                      blurRadius: isListening ? 20 : 8,
                      spreadRadius: isListening ? 4 : 0,
                    ),
                  ],
                ),
                child: Icon(_icon, color: Colors.white, size: 34),
              ),
            ],
          );
        },
      ),
    );
  }
}
