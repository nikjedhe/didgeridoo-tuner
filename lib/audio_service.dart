// lib/audio_service.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:mic_stream/mic_stream.dart';
import 'package:permission_handler/permission_handler.dart';
import 'pitch_analyzer.dart';

class AudioService extends ChangeNotifier {
  StreamSubscription<List<int>>? _micSubscription;
  PitchResult _currentPitch = PitchResult.empty();
  bool _isListening = false;
  String _statusMessage = 'Tap the button to start';

  PitchResult get currentPitch => _currentPitch;
  bool get isListening => _isListening;
  String get statusMessage => _statusMessage;

  // Buffer for collecting audio samples
  final List<double> _sampleBuffer = [];
  static const int _bufferSize = 4096;
  static const int _sampleRate = 44100;

  Future<void> startListening() async {
    // Request microphone permission
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      _statusMessage = 'Microphone permission denied';
      notifyListeners();
      return;
    }

    try {
      _isListening = true;
      _statusMessage = 'Listening... play your didgeridoo!';
      notifyListeners();

      final stream = await MicStream.microphone(
        sampleRate: _sampleRate,
        channelConfig: ChannelConfig.CHANNEL_IN_MONO,
        audioFormat: AudioFormat.ENCODING_PCM_16BIT,
      );

      _micSubscription = stream.listen((samples) {
        _processSamples(samples);
      });
    } catch (e) {
      _statusMessage = 'Error accessing microphone: $e';
      _isListening = false;
      notifyListeners();
    }
  }

  void stopListening() {
    _micSubscription?.cancel();
    _micSubscription = null;
    _isListening = false;
    _currentPitch = PitchResult.empty();
    _statusMessage = 'Tap the button to start';
    _sampleBuffer.clear();
    notifyListeners();
  }

  void _processSamples(List<int> samples) {
    // Convert int16 samples to doubles (-1.0 to 1.0)
    for (int i = 0; i < samples.length - 1; i += 2) {
      int sample16 = samples[i] | (samples[i + 1] << 8);
      if (sample16 > 32767) sample16 -= 65536;
      _sampleBuffer.add(sample16 / 32768.0);
    }

    // Process when buffer is full
    if (_sampleBuffer.length >= _bufferSize) {
      final frequency = _detectPitch(_sampleBuffer.sublist(0, _bufferSize));
      _sampleBuffer.removeRange(0, _bufferSize ~/ 2); // 50% overlap

      if (frequency > 0) {
        _currentPitch = PitchAnalyzer.analyze(frequency);
        notifyListeners();
      }
    }
  }

  // YIN pitch detection algorithm — accurate for monophonic instruments
  double _detectPitch(List<double> samples) {
    final int size = samples.length;
    final int halfSize = size ~/ 2;
    final List<double> yinBuffer = List.filled(halfSize, 0.0);

    // Step 1: Difference function
    for (int tau = 1; tau < halfSize; tau++) {
      for (int i = 0; i < halfSize; i++) {
        double delta = samples[i] - samples[i + tau];
        yinBuffer[tau] += delta * delta;
      }
    }

    // Step 2: Cumulative mean normalized difference
    yinBuffer[0] = 1.0;
    double runningSum = 0.0;
    for (int tau = 1; tau < halfSize; tau++) {
      runningSum += yinBuffer[tau];
      yinBuffer[tau] *= tau / runningSum;
    }

    // Step 3: Find absolute threshold (0.15 is good for didgeridoo)
    const double threshold = 0.15;
    int tauEstimate = -1;
    for (int tau = 2; tau < halfSize; tau++) {
      if (yinBuffer[tau] < threshold) {
        while (tau + 1 < halfSize && yinBuffer[tau + 1] < yinBuffer[tau]) {
          tau++;
        }
        tauEstimate = tau;
        break;
      }
    }

    if (tauEstimate == -1) return -1;

    // Step 4: Parabolic interpolation for better accuracy
    double betterTau;
    if (tauEstimate > 0 && tauEstimate < halfSize - 1) {
      double s0 = yinBuffer[tauEstimate - 1];
      double s1 = yinBuffer[tauEstimate];
      double s2 = yinBuffer[tauEstimate + 1];
      betterTau = tauEstimate + (s2 - s0) / (2 * (2 * s1 - s2 - s0));
    } else {
      betterTau = tauEstimate.toDouble();
    }

    return _sampleRate / betterTau;
  }

  @override
  void dispose() {
    stopListening();
    super.dispose();
  }
}
