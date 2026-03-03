// lib/pitch_analyzer.dart
import 'dart:math';

class PitchResult {
  final String noteName;
  final String fullNote;
  final int octave;
  final double frequency;
  final double cents;
  final bool isDetected;

  PitchResult({
    required this.noteName,
    required this.fullNote,
    required this.octave,
    required this.frequency,
    required this.cents,
    required this.isDetected,
  });

  factory PitchResult.empty() => PitchResult(
        noteName: '--',
        fullNote: '--',
        octave: 0,
        frequency: 0,
        cents: 0,
        isDetected: false,
      );
}

class PitchAnalyzer {
  static const List<String> noteNames = [
    'C', 'C#', 'D', 'D#', 'E', 'F',
    'F#', 'G', 'G#', 'A', 'A#', 'B'
  ];

  static const double minFreq = 40.0;
  static const double maxFreq = 350.0;

  static PitchResult analyze(double frequency) {
    if (frequency < minFreq || frequency > maxFreq) {
      return PitchResult.empty();
    }

    double midiNote = 12 * (log(frequency / 440.0) / log(2)) + 69;
    int midiRounded = midiNote.round();
    double cents = (midiNote - midiRounded) * 100;
    int noteIndex = ((midiRounded % 12) + 12) % 12;
    int octave = (midiRounded ~/ 12) - 1;

    String noteName = noteNames[noteIndex];
    String fullNote = '$noteName$octave';

    return PitchResult(
      noteName: noteName,
      fullNote: fullNote,
      octave: octave,
      frequency: frequency,
      cents: cents,
      isDetected: true,
    );
  }

  static String getDidgeridooKeyDescription(String note) {
    const Map<String, String> keyDescriptions = {
      'D':  'Most common key for beginners',
      'D#': 'Rich & powerful tone',
      'E':  'Popular for world music',
      'F':  'Deep & meditative',
      'F#': 'Traditional Aboriginal key',
      'G':  'Bright & energetic',
      'G#': 'Warm mid-range tone',
      'A':  'Classic warm sound',
      'A#': 'Versatile key',
      'B':  'Rare & unique tone',
      'C':  'Deep & resonant',
      'C#': 'Mellow & smooth',
    };
    return keyDescriptions[note] ?? 'Play your didgeridoo!';
  }
}
