// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'audio_service.dart';
import 'pitch_analyzer.dart';
import 'dart:math';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AudioService(),
      child: const DidgeridooTunerApp(),
    ),
  );
}

class DidgeridooTunerApp extends StatelessWidget {
  const DidgeridooTunerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Didgeridoo Tuner',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0D1117),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFE67E22),
          secondary: Color(0xFF8B4513),
        ),
      ),
      home: const TunerScreen(),
    );
  }
}

class TunerScreen extends StatelessWidget {
  const TunerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<AudioService>(
        builder: (context, audio, _) {
          return SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                const SizedBox(height: 20),
                _buildNoteDisplay(audio.currentPitch),
                const SizedBox(height: 30),
                _buildTunerNeedle(audio.currentPitch),
                const SizedBox(height: 30),
                _buildFrequencyInfo(audio.currentPitch),
                const SizedBox(height: 20),
                _buildKeyDescription(audio.currentPitch),
                const Spacer(),
                _buildStatusMessage(audio.statusMessage),
                const SizedBox(height: 20),
                _buildListenButton(context, audio),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          const Text(
            '🎵 DIDGERIDOO TUNER',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFFE67E22),
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Find your didgeridoo\'s key',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[500],
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteDisplay(PitchResult pitch) {
    Color noteColor = pitch.isDetected
        ? _getCentsColor(pitch.cents)
        : const Color(0xFF2C2C2C);

    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: noteColor, width: 3),
        color: const Color(0xFF1A1A2E),
        boxShadow: pitch.isDetected
            ? [BoxShadow(color: noteColor.withOpacity(0.3), blurRadius: 30, spreadRadius: 5)]
            : [],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            pitch.noteName,
            style: TextStyle(
              fontSize: 80,
              fontWeight: FontWeight.bold,
              color: noteColor,
              height: 1,
            ),
          ),
          if (pitch.isDetected)
            Text(
              'Octave ${pitch.octave}',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[400],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTunerNeedle(PitchResult pitch) {
    return Column(
      children: [
        Text(
          'TUNING METER',
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 80,
          width: 300,
          child: CustomPaint(
            painter: TunerNeedlePainter(
              cents: pitch.isDetected ? pitch.cents : 0,
              isActive: pitch.isDetected,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('♭ FLAT', style: TextStyle(color: Colors.blue[300], fontSize: 12)),
            const SizedBox(width: 80),
            Text('IN TUNE', style: TextStyle(color: Colors.green[400], fontSize: 12)),
            const SizedBox(width: 80),
            Text('SHARP ♯', style: TextStyle(color: Colors.red[300], fontSize: 12)),
          ],
        ),
        if (pitch.isDetected)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '${pitch.cents >= 0 ? '+' : ''}${pitch.cents.toStringAsFixed(1)} cents',
              style: TextStyle(
                color: _getCentsColor(pitch.cents),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFrequencyInfo(PitchResult pitch) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _infoChip(
          label: 'FREQUENCY',
          value: pitch.isDetected ? '${pitch.frequency.toStringAsFixed(1)} Hz' : '--- Hz',
        ),
        const SizedBox(width: 20),
        _infoChip(
          label: 'NOTE',
          value: pitch.isDetected ? pitch.fullNote : '---',
        ),
      ],
    );
  }

  Widget _infoChip({required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF333333)),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600], letterSpacing: 1)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildKeyDescription(PitchResult pitch) {
    if (!pitch.isDetected) return const SizedBox(height: 50);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 30),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE67E22).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE67E22).withOpacity(0.3)),
      ),
      child: Text(
        '🪘  ${pitch.noteName}  —  ${PitchAnalyzer.getDidgeridooKeyDescription(pitch.noteName)}',
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xFFE67E22),
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildStatusMessage(String message) {
    return Text(
      message,
      style: TextStyle(color: Colors.grey[500], fontSize: 13),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildListenButton(BuildContext context, AudioService audio) {
    return GestureDetector(
      onTap: () {
        if (audio.isListening) {
          audio.stopListening();
        } else {
          audio.startListening();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: audio.isListening
              ? const Color(0xFFC0392B)
              : const Color(0xFFE67E22),
          boxShadow: [
            BoxShadow(
              color: (audio.isListening ? const Color(0xFFC0392B) : const Color(0xFFE67E22))
                  .withOpacity(0.4),
              blurRadius: 20,
              spreadRadius: 3,
            ),
          ],
        ),
        child: Icon(
          audio.isListening ? Icons.stop_rounded : Icons.mic_rounded,
          size: 36,
          color: Colors.white,
        ),
      ),
    );
  }

  Color _getCentsColor(double cents) {
    double abs = cents.abs();
    if (abs < 10) return const Color(0xFF4CAF50);
    if (abs < 25) return const Color(0xFFFF9800);
    return const Color(0xFFF44336);
  }
}

// Custom painter for the tuner needle
class TunerNeedlePainter extends CustomPainter {
  final double cents;
  final bool isActive;

  TunerNeedlePainter({required this.cents, required this.isActive});

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height - 10;
    final radius = size.height - 15;

    // Draw arc background
    final bgPaint = Paint()
      ..color = const Color(0xFF2C2C2C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCenter(center: Offset(centerX, centerY), width: radius * 2, height: radius * 2),
      pi, pi, false, bgPaint,
    );

    // Draw colored zones
    _drawZone(canvas, centerX, centerY, radius, pi, pi * 0.35, const Color(0xFF1565C0)); // flat
    _drawZone(canvas, centerX, centerY, radius, pi * 1.35, pi * 0.3, const Color(0xFF2E7D32)); // in tune
    _drawZone(canvas, centerX, centerY, radius, pi * 1.65, pi * 0.35, const Color(0xFFC62828)); // sharp

    if (!isActive) return;

    // Draw needle
    double normalizedCents = (cents.clamp(-50.0, 50.0)) / 50.0;
    double angle = pi + (normalizedCents * pi / 2) + pi / 2;

    final needleColor = _getNeedleColor(cents.abs());
    final needlePaint = Paint()
      ..color = needleColor
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    double needleX = centerX + (radius - 10) * cos(angle);
    double needleY = centerY + (radius - 10) * sin(angle);

    canvas.drawLine(Offset(centerX, centerY), Offset(needleX, needleY), needlePaint);

    // Center dot
    canvas.drawCircle(
      Offset(centerX, centerY), 6,
      Paint()..color = needleColor,
    );
  }

  void _drawZone(Canvas canvas, double cx, double cy, double r, double startAngle, double sweepAngle, Color color) {
    final paint = Paint()
      ..color = color.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx, cy), width: r * 2, height: r * 2),
      startAngle, sweepAngle, false, paint,
    );
  }

  Color _getNeedleColor(double absCents) {
    if (absCents < 10) return const Color(0xFF4CAF50);
    if (absCents < 25) return const Color(0xFFFF9800);
    return const Color(0xFFF44336);
  }

  @override
  bool shouldRepaint(TunerNeedlePainter old) => old.cents != cents || old.isActive != isActive;
}
