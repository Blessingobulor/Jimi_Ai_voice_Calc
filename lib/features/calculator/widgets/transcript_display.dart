import 'package:flutter/material.dart';
import '../../../models/speech_state.dart';

class TranscriptDisplay extends StatelessWidget {
  final String transcript;
  final MicStatus status;

  const TranscriptDisplay({
    super.key,
    required this.transcript,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    String label = switch (status) {
      MicStatus.idle => 'Tap the mic and speak your calculation',
      MicStatus.listening => 'Listening...',
      MicStatus.processing => 'Processing...',
      MicStatus.error => 'Could not access microphone',
    };

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 72),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: status == MicStatus.listening
            ? const Color(0xFFEF4444).withOpacity(0.06)
            : theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: status == MicStatus.listening
              ? const Color(0xFFEF4444).withOpacity(0.3)
              : theme.colorScheme.outline.withOpacity(0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                status == MicStatus.listening
                    ? Icons.graphic_eq
                    : Icons.record_voice_over_outlined,
                size: 14,
                color: status == MicStatus.listening
                    ? const Color(0xFFEF4444)
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: status == MicStatus.listening
                      ? const Color(0xFFEF4444)
                      : theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          if (transcript.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              transcript,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
                fontStyle: FontStyle.italic,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
