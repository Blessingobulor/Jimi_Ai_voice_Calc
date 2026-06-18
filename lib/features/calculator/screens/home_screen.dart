import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/speech_provider.dart';
import '../../../core/providers/calculator_provider.dart';
import '../../../core/providers/history_provider.dart';
import '../../../models/speech_state.dart';
import '../../history/screens/history_screen.dart';

// ── Design tokens ─────────────────────────────────────────
const _bg = Color(0xFF070B18); // deep navy-black
const _surface = Color(0xFF0F1629); // card surface
const _border = Color(0xFF1E2A45); // subtle border
const _violet = Color(0xFF7C3AED); // primary / idle mic
const _violetDim = Color(0xFF3B1F7A); // dim violet
const _cyan = Color(0xFF06B6D4); // listening / active
const _cyanDim = Color(0xFF0A3A45); // dim cyan
const _textPrimary = Color(0xFFF1F5F9);
const _textSecondary = Color(0xFF64748B);
const _textMuted = Color(0xFF334155);
const _success = Color(0xFF10B981);
const _error = Color(0xFFEF4444);

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  final TextEditingController _manualController = TextEditingController();
  bool _showManual = false;

  // Wave animation controller
  late AnimationController _waveCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _resultCtrl;
  late Animation<double> _resultScale;

  @override
  void initState() {
    super.initState();

    _waveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _resultCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _resultScale = CurvedAnimation(
      parent: _resultCtrl,
      curve: Curves.elasticOut,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(speechProvider.notifier).initialise();
      await ref.read(historyProvider.notifier).init();
    });
  }

  @override
  void dispose() {
    _waveCtrl.dispose();
    _pulseCtrl.dispose();
    _resultCtrl.dispose();
    _manualController.dispose();
    super.dispose();
  }

  Future<void> _toggleMic() async {
    final speechState = ref.read(speechProvider);
    HapticFeedback.mediumImpact();

    if (speechState.isListening) {
      await ref.read(speechProvider.notifier).stopListening();
      return;
    }

    ref.read(calculatorProvider.notifier).clear();
    _resultCtrl.reset();

    await ref
        .read(speechProvider.notifier)
        .startListening(
          onPartial: (_) {},
          onFinal: (transcript) async {
            await ref
                .read(calculatorProvider.notifier)
                .processTranscript(transcript);
            final calcState = ref.read(calculatorProvider);
            if (!calcState.hasError && calcState.result.isNotEmpty) {
              _resultCtrl.forward(from: 0);
              HapticFeedback.lightImpact();
              await ref
                  .read(historyProvider.notifier)
                  .addEntry(
                    rawTranscript: transcript,
                    expression: calcState.displayExpression,
                    result: calcState.result,
                  );
            }
            ref.read(speechProvider.notifier).resetTranscript();
          },
        );
  }

  void _submitManual() {
    final expr = _manualController.text.trim();
    if (expr.isEmpty) return;
    ref.read(calculatorProvider.notifier).processManual(expr);
    final calcState = ref.read(calculatorProvider);
    if (!calcState.hasError && calcState.result.isNotEmpty) {
      _resultCtrl.forward(from: 0);
      ref
          .read(historyProvider.notifier)
          .addEntry(
            rawTranscript: expr,
            expression: calcState.displayExpression,
            result: calcState.result,
          );
    }
    _manualController.clear();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final speechState = ref.watch(speechProvider);
    final calcState = ref.watch(calculatorProvider);
    final history = ref.watch(historyProvider);
    final size = MediaQuery.of(context).size;

    final isListening = speechState.isListening;
    final isProcessing = calcState.isParsingWithAI || speechState.isProcessing;
    final hasResult = calcState.result.isNotEmpty && !calcState.hasError;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _bg,
        body: SafeArea(
          child: Column(
            children: [
              // ── Top bar ──────────────────────────────────
              _TopBar(
                historyCount: history.length,
                showManual: _showManual,
                onHistory: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HistoryScreen()),
                ),
                onToggleMode: () => setState(() => _showManual = !_showManual),
              ),

              // ── Result display ───────────────────────────
              Expanded(
                flex: 3,
                child: _ResultDisplay(
                  calcState: calcState,
                  resultScale: _resultScale,
                  hasResult: hasResult,
                  isProcessing: isProcessing,
                ),
              ),

              // ── Mic orb / manual input ───────────────────
              Expanded(
                flex: 4,
                child: _showManual
                    ? _ManualInput(
                        controller: _manualController,
                        onSubmit: _submitManual,
                      )
                    : _MicOrb(
                        speechState: speechState,
                        isProcessing: isProcessing,
                        waveCtrl: _waveCtrl,
                        pulseCtrl: _pulseCtrl,
                        onTap: _toggleMic,
                        orbSize: math.min(size.width * 0.52, 220),
                      ),
              ),

              // ── Transcript strip ─────────────────────────
              _TranscriptStrip(
                transcript: speechState.transcript,
                isListening: isListening,
                isProcessing: isProcessing,
                explanation: calcState.explanation,
                hasResult: hasResult,
              ),

              // ── Example pills ────────────────────────────
              if (!hasResult && !isListening && !isProcessing) _ExamplePills(),

              // ── Error bar ────────────────────────────────
              if (calcState.hasError && calcState.errorMessage != null)
                _ErrorBar(message: calcState.errorMessage!),
              if (speechState.hasError && speechState.errorMessage != null)
                _ErrorBar(message: speechState.errorMessage!, isMic: true),

              const SizedBox(height: 16),

              // ── Clear / reset ────────────────────────────
              if (hasResult || calcState.hasError)
                _ClearButton(
                  onTap: () {
                    ref.read(calculatorProvider.notifier).clear();
                    ref.read(speechProvider.notifier).resetTranscript();
                    _resultCtrl.reset();
                  },
                ),

              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// TOP BAR
// ─────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final int historyCount;
  final bool showManual;
  final VoidCallback onHistory;
  final VoidCallback onToggleMode;

  const _TopBar({
    required this.historyCount,
    required this.showManual,
    required this.onHistory,
    required this.onToggleMode,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
      child: Row(
        children: [
          // Logo
          const _VoiceCalcLogo(),
          const Spacer(),
          // History
          GestureDetector(
            onTap: onHistory,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _border),
              ),
              child: Row(
                children: [
                  Icon(Icons.history_rounded, size: 15, color: _textSecondary),
                  if (historyCount > 0) ...[
                    const SizedBox(width: 5),
                    Text(
                      '$historyCount',
                      style: const TextStyle(
                        fontSize: 12,
                        color: _textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Mode toggle
          GestureDetector(
            onTap: onToggleMode,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _border),
              ),
              child: Icon(
                showManual ? Icons.mic_rounded : Icons.keyboard_rounded,
                size: 17,
                color: _textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VoiceCalcLogo extends StatelessWidget {
  const _VoiceCalcLogo();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_violet, _cyan],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(7),
          ),
          child: const Icon(
            Icons.graphic_eq_rounded,
            color: Colors.white,
            size: 16,
          ),
        ),
        const SizedBox(width: 9),
        const Text(
          'VoiceCalc',
          style: TextStyle(
            color: _textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [_violet, _cyan]),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Text(
            'AI',
            style: TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────
// RESULT DISPLAY
// ─────────────────────────────────────────────────────────
class _ResultDisplay extends StatelessWidget {
  final CalculatorState calcState;
  final Animation<double> resultScale;
  final bool hasResult;
  final bool isProcessing;

  const _ResultDisplay({
    required this.calcState,
    required this.resultScale,
    required this.hasResult,
    required this.isProcessing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Expression line
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: calcState.displayExpression.isNotEmpty
                ? Text(
                    key: ValueKey(calcState.displayExpression),
                    calcState.displayExpression,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 16,
                      color: _textSecondary,
                      letterSpacing: 0.5,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  )
                : const Text(
                    key: ValueKey('empty'),
                    '— — —',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 16,
                      color: _textMuted,
                      letterSpacing: 4,
                    ),
                  ),
          ),

          const SizedBox(height: 10),

          // Main result number
          GestureDetector(
            onLongPress: hasResult
                ? () {
                    Clipboard.setData(ClipboardData(text: calcState.result));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Result copied'),
                        duration: const Duration(seconds: 1),
                        backgroundColor: _surface,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  }
                : null,
            child: ScaleTransition(
              scale: hasResult
                  ? resultScale
                  : const AlwaysStoppedAnimation(1.0),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: isProcessing
                    ? _ProcessingDots(key: const ValueKey('dots'))
                    : Text(
                        key: ValueKey(
                          calcState.result.isEmpty ? 'zero' : calcState.result,
                        ),
                        calcState.result.isEmpty ? '0' : calcState.result,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: calcState.result.length > 10 ? 40 : 58,
                          fontWeight: FontWeight.w700,
                          color: calcState.hasError
                              ? _error
                              : hasResult
                              ? _textPrimary
                              : _textMuted,
                          letterSpacing: -1,
                          height: 1,
                        ),
                      ),
              ),
            ),
          ),

          if (hasResult)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text(
                'Hold to copy',
                style: TextStyle(fontSize: 10, color: _textMuted),
              ),
            ),
        ],
      ),
    );
  }
}

class _ProcessingDots extends StatefulWidget {
  const _ProcessingDots({super.key});

  @override
  State<_ProcessingDots> createState() => _ProcessingDotsState();
}

class _ProcessingDotsState extends State<_ProcessingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: List.generate(3, (i) {
            final delay = i / 3;
            final v = math.sin((_ctrl.value - delay) * math.pi * 2);
            final opacity = (v * 0.5 + 0.5).clamp(0.2, 1.0);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Opacity(
                opacity: opacity,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: _cyan,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────
// MIC ORB — the signature element
// ─────────────────────────────────────────────────────────
class _MicOrb extends StatelessWidget {
  final SpeechState speechState;
  final bool isProcessing;
  final AnimationController waveCtrl;
  final AnimationController pulseCtrl;
  final VoidCallback onTap;
  final double orbSize;

  const _MicOrb({
    required this.speechState,
    required this.isProcessing,
    required this.waveCtrl,
    required this.pulseCtrl,
    required this.onTap,
    required this.orbSize,
  });

  @override
  Widget build(BuildContext context) {
    final isListening = speechState.isListening;

    return Center(
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: orbSize * 1.6,
          height: orbSize * 1.6,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer wave rings (only when listening)
              if (isListening)
                AnimatedBuilder(
                  animation: waveCtrl,
                  builder: (_, __) => CustomPaint(
                    size: Size(orbSize * 1.6, orbSize * 1.6),
                    painter: _WaveRingPainter(
                      progress: waveCtrl.value,
                      color: _cyan,
                      ringCount: 3,
                    ),
                  ),
                ),

              // Idle glow ring
              if (!isListening && !isProcessing)
                AnimatedBuilder(
                  animation: pulseCtrl,
                  builder: (_, __) {
                    final r = orbSize / 2 + 16 + pulseCtrl.value * 8;
                    return CustomPaint(
                      size: Size(orbSize * 1.6, orbSize * 1.6),
                      painter: _GlowRingPainter(radius: r, color: _violetDim),
                    );
                  },
                ),

              // Core orb
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
                width: orbSize,
                height: orbSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: isListening
                        ? [_cyan.withOpacity(0.25), _cyanDim, _bg]
                        : isProcessing
                        ? [_violet.withOpacity(0.2), _violetDim, _bg]
                        : [_violet.withOpacity(0.15), _violetDim, _bg],
                    stops: const [0.0, 0.55, 1.0],
                  ),
                  border: Border.all(
                    color: isListening ? _cyan : _violet,
                    width: isListening ? 1.5 : 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (isListening ? _cyan : _violet).withOpacity(0.3),
                      blurRadius: isListening ? 40 : 20,
                      spreadRadius: isListening ? 8 : 2,
                    ),
                  ],
                ),
                child: isProcessing
                    ? const Icon(
                        Icons.psychology_rounded,
                        color: _violet,
                        size: 36,
                      )
                    : Icon(
                        isListening
                            ? Icons.mic_rounded
                            : Icons.mic_none_rounded,
                        color: isListening ? _cyan : _violet,
                        size: 38,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Concentric expanding wave rings
class _WaveRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final int ringCount;

  _WaveRingPainter({
    required this.progress,
    required this.color,
    required this.ringCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;
    final minRadius = size.width * 0.32;

    for (int i = 0; i < ringCount; i++) {
      final offset = (progress + i / ringCount) % 1.0;
      final radius = minRadius + (maxRadius - minRadius) * offset;
      final opacity = (1.0 - offset) * 0.5;

      final paint = Paint()
        ..color = color.withOpacity(opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(_WaveRingPainter old) => old.progress != progress;
}

// Static glow ring for idle state
class _GlowRingPainter extends CustomPainter {
  final double radius;
  final Color color;

  _GlowRingPainter({required this.radius, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(_GlowRingPainter old) => old.radius != radius;
}

// ─────────────────────────────────────────────────────────
// MANUAL INPUT
// ─────────────────────────────────────────────────────────
class _ManualInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSubmit;

  const _ManualInput({required this.controller, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Type your calculation',
            style: TextStyle(color: _textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => onSubmit(),
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      color: _textPrimary,
                      fontSize: 16,
                    ),
                    decoration: const InputDecoration(
                      hintText: '250 * 18   or   15% of 4000',
                      hintStyle: TextStyle(color: _textMuted, fontSize: 14),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 18,
                      ),
                    ),
                    cursorColor: _cyan,
                  ),
                ),
                GestureDetector(
                  onTap: onSubmit,
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_violet, _cyan],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// TRANSCRIPT STRIP
// ─────────────────────────────────────────────────────────
class _TranscriptStrip extends StatelessWidget {
  final String transcript;
  final bool isListening;
  final bool isProcessing;
  final String explanation;
  final bool hasResult;

  const _TranscriptStrip({
    required this.transcript,
    required this.isListening,
    required this.isProcessing,
    required this.explanation,
    required this.hasResult,
  });

  @override
  Widget build(BuildContext context) {
    String text = '';
    Color dotColor = _textMuted;

    if (isListening && transcript.isNotEmpty) {
      text = transcript;
      dotColor = _cyan;
    } else if (isListening) {
      text = 'Listening...';
      dotColor = _cyan;
    } else if (isProcessing) {
      text = 'Claude is thinking...';
      dotColor = _violet;
    } else if (hasResult && explanation.isNotEmpty) {
      text = explanation;
      dotColor = _success;
    } else {
      text = 'Tap the orb to speak your calculation';
      dotColor = _textMuted;
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Container(
        key: ValueKey(text),
        margin: const EdgeInsets.fromLTRB(20, 8, 20, 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isListening ? _cyan.withOpacity(0.3) : _border,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: dotColor,
                boxShadow: [
                  BoxShadow(color: dotColor.withOpacity(0.6), blurRadius: 6),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 13,
                  color: isListening ? _textPrimary : _textSecondary,
                  fontStyle: isListening ? FontStyle.italic : FontStyle.normal,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// EXAMPLE PILLS
// ─────────────────────────────────────────────────────────
class _ExamplePills extends StatelessWidget {
  static const _examples = [
    'two fifty times eighteen',
    '15% of 4000 naira',
    'split 45k between 4',
    'add 7.5% VAT to 12000',
    'change from 5000 after 3750',
    'half of 300',
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 0, 8),
            child: Text(
              'TRY SAYING',
              style: TextStyle(
                fontSize: 10,
                color: _textMuted,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(
            height: 34,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: _examples.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) => Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _border),
                ),
                child: Text(
                  '"${_examples[i]}"',
                  style: const TextStyle(
                    fontSize: 11,
                    color: _textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// ERROR BAR
// ─────────────────────────────────────────────────────────
class _ErrorBar extends StatelessWidget {
  final String message;
  final bool isMic;

  const _ErrorBar({required this.message, this.isMic = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 6, 20, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _error.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _error.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Icon(
            isMic ? Icons.mic_off_rounded : Icons.error_outline_rounded,
            color: _error,
            size: 15,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 12, color: _error, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// CLEAR BUTTON
// ─────────────────────────────────────────────────────────
class _ClearButton extends StatelessWidget {
  final VoidCallback onTap;
  const _ClearButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _border),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.refresh_rounded, size: 14, color: _textSecondary),
            SizedBox(width: 6),
            Text(
              'Clear',
              style: TextStyle(
                fontSize: 13,
                color: _textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
