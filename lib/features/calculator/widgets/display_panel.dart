import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DisplayPanel extends StatelessWidget {
  final String expression;
  final String explanation;
  final String result;
  final bool hasError;
  final bool isLoading;

  const DisplayPanel({
    super.key,
    required this.expression,
    required this.result,
    required this.hasError,
    required this.isLoading,
    this.explanation = '',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF6366F1).withOpacity(0.12),
            const Color(0xFF8B5CF6).withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF6366F1).withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [

          // AI explanation label (what Claude understood)
          if (explanation.isNotEmpty && !isLoading)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF6366F1).withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.auto_awesome,
                          size: 11,
                          color: Color(0xFF6366F1),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'AI understood',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: const Color(0xFF6366F1),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      explanation,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.45),
                        fontStyle: FontStyle.italic,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

          // Expression row
          Text(
            isLoading
                ? 'AI is thinking...'
                : expression.isEmpty
                    ? '0'
                    : expression,
            textAlign: TextAlign.right,
            style: theme.textTheme.titleLarge?.copyWith(
              color: isLoading
                  ? const Color(0xFF6366F1).withOpacity(0.5)
                  : expression.isEmpty
                      ? theme.colorScheme.onSurface.withOpacity(0.2)
                      : theme.colorScheme.onSurface.withOpacity(0.65),
              fontWeight: FontWeight.w400,
              fontSize: 22,
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 12),

          // Result row or loading indicator
          if (isLoading)
            Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: const Color(0xFF6366F1).withOpacity(0.6),
                ),
              ),
            )
          else
            GestureDetector(
              onLongPress: result.isNotEmpty && !hasError
                  ? () {
                      Clipboard.setData(ClipboardData(text: result));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Result copied'),
                          duration: Duration(seconds: 1),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  : null,
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: theme.textTheme.displayMedium!.copyWith(
                  color: hasError
                      ? theme.colorScheme.error
                      : result.isEmpty
                          ? theme.colorScheme.onSurface.withOpacity(0.15)
                          : const Color(0xFF6366F1),
                  fontWeight: FontWeight.w700,
                  fontSize: result.length > 12 ? 36 : 52,
                  height: 1.1,
                ),
                child: Text(
                  result.isEmpty ? '—' : result,
                  textAlign: TextAlign.right,
                ),
              ),
            ),

          if (result.isNotEmpty && !hasError && !isLoading)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Hold to copy',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.3),
                ),
              ),
            ),
        ],
      ),
    );
  }
}