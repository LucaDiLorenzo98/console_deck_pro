import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:just_audio/just_audio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

enum DeckSide { left, right }

class SpecialModuleAudioService {
  final AudioPlayer _leftDeckPlayer = AudioPlayer();
  final AudioPlayer _rightDeckPlayer = AudioPlayer();
  final AudioPlayer _pianoPlayer = AudioPlayer();

  final Map<String, String> _generatedNoteFiles = {};

  String? _leftLoadedPath;
  String? _rightLoadedPath;
  double _crossfader = 0.5;

  static const Map<String, double> noteFrequencies = {
    'C4': 261.63,
    'C#4': 277.18,
    'D4': 293.66,
    'D#4': 311.13,
    'E4': 329.63,
    'F4': 349.23,
    'F#4': 369.99,
    'G4': 392.00,
    'G#4': 415.30,
    'A4': 440.00,
    'A#4': 466.16,
    'B4': 493.88,
  };

  SpecialModuleAudioService() {
    _leftDeckPlayer.setLoopMode(LoopMode.one);
    _rightDeckPlayer.setLoopMode(LoopMode.one);
    _applyCrossfader();
  }

  Future<void> setDeckTrack(
    DeckSide side,
    String filePath, {
    bool autoplay = false,
  }) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('Audio file not found: $filePath');
    }

    final player = _playerForDeck(side);
    final loadedPath = _loadedPathForDeck(side);
    if (loadedPath != filePath) {
      await player.setFilePath(filePath);
      _setLoadedPathForDeck(side, filePath);
    }

    if (autoplay) {
      await player.play();
    }
  }

  Future<bool> toggleDeckPlayback(DeckSide side, {String? filePath}) async {
    final player = _playerForDeck(side);
    if (filePath != null && filePath.isNotEmpty) {
      await setDeckTrack(side, filePath);
    }

    if (player.audioSource == null) {
      return false;
    }

    if (player.playing) {
      await player.pause();
      return false;
    }

    await player.play();
    return true;
  }

  Future<void> stopDeck(DeckSide side) async {
    final player = _playerForDeck(side);
    await player.stop();
  }

  Future<void> jogDeck(DeckSide side, Duration delta) async {
    final player = _playerForDeck(side);
    if (player.audioSource == null) {
      return;
    }

    final current = player.position;
    final duration = player.duration;
    var target = current + delta;
    if (target < Duration.zero) {
      target = Duration.zero;
    }
    if (duration != null && target > duration) {
      target = duration;
    }
    await player.seek(target);
  }

  Future<void> setCrossfader(double value) async {
    _crossfader = value.clamp(0.0, 1.0).toDouble();
    await _applyCrossfader();
  }

  Future<void> playPiano({
    required String note,
    String? customFilePath,
  }) async {
    String filePath;

    if (customFilePath != null && customFilePath.isNotEmpty) {
      final custom = File(customFilePath);
      if (await custom.exists()) {
        filePath = customFilePath;
      } else {
        filePath = await _getGeneratedNoteFile(note);
      }
    } else {
      filePath = await _getGeneratedNoteFile(note);
    }

    await _pianoPlayer.stop();
    await _pianoPlayer.setFilePath(filePath);
    await _pianoPlayer.seek(Duration.zero);
    await _pianoPlayer.play();
  }

  Future<void> _applyCrossfader() async {
    final leftVolume = (1.0 - _crossfader).clamp(0.0, 1.0).toDouble();
    final rightVolume = _crossfader.clamp(0.0, 1.0).toDouble();
    await _leftDeckPlayer.setVolume(leftVolume);
    await _rightDeckPlayer.setVolume(rightVolume);
  }

  AudioPlayer _playerForDeck(DeckSide side) {
    return side == DeckSide.left ? _leftDeckPlayer : _rightDeckPlayer;
  }

  String? _loadedPathForDeck(DeckSide side) {
    return side == DeckSide.left ? _leftLoadedPath : _rightLoadedPath;
  }

  void _setLoadedPathForDeck(DeckSide side, String path) {
    if (side == DeckSide.left) {
      _leftLoadedPath = path;
    } else {
      _rightLoadedPath = path;
    }
  }

  Future<String> _getGeneratedNoteFile(String note) async {
    final normalized = note.toUpperCase();
    final cached = _generatedNoteFiles[normalized];
    if (cached != null && await File(cached).exists()) {
      return cached;
    }

    final frequency = noteFrequencies[normalized] ?? noteFrequencies['C4']!;
    final tempDir = await getTemporaryDirectory();
    final notesDir = Directory(p.join(tempDir.path, 'console_deck_notes'));
    if (!await notesDir.exists()) {
      await notesDir.create(recursive: true);
    }

    final fileName = 'note_${normalized.replaceAll('#', 's')}.wav';
    final output = File(p.join(notesDir.path, fileName));
    if (!await output.exists()) {
      final bytes = _buildSineWaveWavBytes(
        frequency: frequency,
        durationSeconds: 0.35,
      );
      await output.writeAsBytes(bytes, flush: true);
    }

    _generatedNoteFiles[normalized] = output.path;
    return output.path;
  }

  Uint8List _buildSineWaveWavBytes({
    required double frequency,
    required double durationSeconds,
  }) {
    const sampleRate = 44100;
    const numChannels = 1;
    const bitsPerSample = 16;

    final sampleCount = (sampleRate * durationSeconds).round();
    final dataSize = sampleCount * numChannels * (bitsPerSample ~/ 8);
    final byteData = ByteData(44 + dataSize);

    _writeAscii(byteData, 0, 'RIFF');
    byteData.setUint32(4, 36 + dataSize, Endian.little);
    _writeAscii(byteData, 8, 'WAVE');
    _writeAscii(byteData, 12, 'fmt ');
    byteData.setUint32(16, 16, Endian.little); // PCM chunk size
    byteData.setUint16(20, 1, Endian.little); // PCM format
    byteData.setUint16(22, numChannels, Endian.little);
    byteData.setUint32(24, sampleRate, Endian.little);
    byteData.setUint32(
      28,
      sampleRate * numChannels * (bitsPerSample ~/ 8),
      Endian.little,
    );
    byteData.setUint16(32, numChannels * (bitsPerSample ~/ 8), Endian.little);
    byteData.setUint16(34, bitsPerSample, Endian.little);
    _writeAscii(byteData, 36, 'data');
    byteData.setUint32(40, dataSize, Endian.little);

    const amplitude = 0.35;
    for (int i = 0; i < sampleCount; i++) {
      final t = i / sampleRate;
      final sample = (math.sin(2 * math.pi * frequency * t) * amplitude * 32767)
          .round()
          .clamp(-32768, 32767);
      byteData.setInt16(44 + i * 2, sample, Endian.little);
    }

    return byteData.buffer.asUint8List();
  }

  void _writeAscii(ByteData data, int offset, String text) {
    for (int i = 0; i < text.length; i++) {
      data.setUint8(offset + i, text.codeUnitAt(i));
    }
  }

  void dispose() {
    _leftDeckPlayer.dispose();
    _rightDeckPlayer.dispose();
    _pianoPlayer.dispose();
  }
}
