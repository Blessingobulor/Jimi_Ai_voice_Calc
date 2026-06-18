import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../models/calculation_entry.dart';

const _boxName = 'calculations';

class HistoryNotifier extends StateNotifier<List<CalculationEntry>> {
  late Box<CalculationEntry> _box;
  final _uuid = const Uuid();

  HistoryNotifier() : super([]);

  Future<void> init() async {
    _box = await Hive.openBox<CalculationEntry>(_boxName);
    // Load stored history, newest first
    state = _box.values.toList().reversed.toList();
  }

  Future<void> addEntry({
    required String rawTranscript,
    required String expression,
    required String result,
  }) async {
    final entry = CalculationEntry(
      id: _uuid.v4(),
      rawTranscript: rawTranscript,
      expression: expression,
      result: result,
      timestamp: DateTime.now(),
    );

    await _box.put(entry.id, entry);
    // Prepend so newest is first
    state = [entry, ...state];
  }

  Future<void> deleteEntry(String id) async {
    await _box.delete(id);
    state = state.where((e) => e.id != id).toList();
  }

  Future<void> clearAll() async {
    await _box.clear();
    state = [];
  }
}

// ── Provider ───────────────────────────────────────────────

final historyProvider =
    StateNotifierProvider<HistoryNotifier, List<CalculationEntry>>((ref) {
  return HistoryNotifier();
});