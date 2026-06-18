import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/history_provider.dart';
import '../widgets/history_tile.dart';

// Match home screen design tokens
const _bg        = Color(0xFF070B18);
const _surface   = Color(0xFF0F1629);
const _border    = Color(0xFF1E2A45);
const _violet    = Color(0xFF7C3AED);
const _cyan      = Color(0xFF06B6D4);
const _textPrimary   = Color(0xFFF1F5F9);
const _textSecondary = Color(0xFF64748B);
const _textMuted     = Color(0xFF334155);
const _error     = Color(0xFFEF4444);

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(historyProvider);

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        iconTheme: const IconThemeData(color: _textSecondary),
        title: const Text(
          'History',
          style: TextStyle(
            color: _textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          if (history.isNotEmpty)
            GestureDetector(
              onTap: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    backgroundColor: _surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: _border),
                    ),
                    title: const Text(
                      'Clear all history?',
                      style: TextStyle(color: _textPrimary, fontSize: 16),
                    ),
                    content: const Text(
                      'This will permanently delete all saved calculations.',
                      style: TextStyle(color: _textSecondary, fontSize: 13),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel',
                            style: TextStyle(color: _textSecondary)),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Clear all',
                            style: TextStyle(color: _error)),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await ref.read(historyProvider.notifier).clearAll();
                }
              },
              child: Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _error.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _error.withOpacity(0.2)),
                ),
                child: const Text(
                  'Clear all',
                  style: TextStyle(
                    fontSize: 12,
                    color: _error,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: history.isEmpty
          ? const _EmptyState()
          : Column(
              children: [
                // Summary bar
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: _surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: _violet,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${history.length} calculation${history.length == 1 ? '' : 's'}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: _textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      const Text(
                        'Swipe left to delete  ·  Hold to copy',
                        style: TextStyle(
                          fontSize: 11,
                          color: _textMuted,
                        ),
                      ),
                    ],
                  ),
                ),

                // List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                    itemCount: history.length,
                    itemBuilder: (_, index) {
                      final entry = history[index];
                      return _DarkHistoryTile(
                        entry: entry,
                        onDelete: () => ref
                            .read(historyProvider.notifier)
                            .deleteEntry(entry.id),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

// ── Dark-themed history tile ─────────────────────────────
class _DarkHistoryTile extends StatelessWidget {
  final dynamic entry;
  final VoidCallback onDelete;

  const _DarkHistoryTile({required this.entry, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(entry.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: _error.withOpacity(0.15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _error.withOpacity(0.3)),
        ),
        child: const Icon(Icons.delete_outline_rounded,
            color: _error, size: 20),
      ),
      child: GestureDetector(
        onLongPress: () {
          _copyResult(context, entry.result);
        },
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _border),
          ),
          child: Row(
            children: [
              // Left — expression + spoken transcript
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.expression,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 14,
                        color: _textSecondary,
                        height: 1.3,
                      ),
                    ),
                    if (entry.rawTranscript != entry.expression) ...[
                      const SizedBox(height: 3),
                      Text(
                        '"${entry.rawTranscript}"',
                        style: const TextStyle(
                          fontSize: 11,
                          color: _textMuted,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Right — result + timestamp
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    entry.result,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 18,
                      color: _cyan,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${entry.formattedDate} · ${entry.formattedTime}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: _textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _copyResult(BuildContext context, String result) {
    // ignore: use_build_context_synchronously
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Result copied'),
        duration: const Duration(seconds: 1),
        backgroundColor: _surface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

// ── Empty state ──────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: _surface,
              shape: BoxShape.circle,
              border: Border.all(color: _border),
            ),
            child: const Icon(Icons.history_rounded,
                color: _textMuted, size: 28),
          ),
          const SizedBox(height: 16),
          const Text(
            'No calculations yet',
            style: TextStyle(
              color: _textSecondary,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Speak a calculation on the home screen',
            style: TextStyle(fontSize: 12, color: _textMuted),
          ),
        ],
      ),
    );
  }
}