import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AmbientSound { off, brownNoise, pinkNoise }

final ambientSoundProvider =
    NotifierProvider<AmbientSoundController, AmbientSound>(
        AmbientSoundController.new);

class AmbientSoundController extends Notifier<AmbientSound> {
  late final AudioPlayer _player;

  @override
  AmbientSound build() {
    _player = AudioPlayer();
    ref.onDispose(() => unawaited(_player.dispose()));
    return AmbientSound.off;
  }

  Future<void> select(AmbientSound sound) async {
    state = sound;
    if (sound == AmbientSound.off) {
      await _player.stop();
      return;
    }

    await _player.setReleaseMode(ReleaseMode.loop);
    await _player.setVolume(0.32);
    await _player.play(BytesSource(_createNoiseWave(sound)));
  }

  Uint8List _createNoiseWave(AmbientSound sound) {
    const sampleRate = 22050;
    const seconds = 4;
    const rampSamples = sampleRate ~/ 10;
    final sampleCount = sampleRate * seconds;
    final dataLength = sampleCount * 2;
    final bytes = Uint8List(44 + dataLength);
    final header = ByteData.sublistView(bytes);

    void writeTag(int offset, String tag) {
      for (var index = 0; index < tag.length; index++) {
        header.setUint8(offset + index, tag.codeUnitAt(index));
      }
    }

    writeTag(0, 'RIFF');
    header.setUint32(4, 36 + dataLength, Endian.little);
    writeTag(8, 'WAVE');
    writeTag(12, 'fmt ');
    header.setUint32(16, 16, Endian.little);
    header.setUint16(20, 1, Endian.little);
    header.setUint16(22, 1, Endian.little);
    header.setUint32(24, sampleRate, Endian.little);
    header.setUint32(28, sampleRate * 2, Endian.little);
    header.setUint16(32, 2, Endian.little);
    header.setUint16(34, 16, Endian.little);
    writeTag(36, 'data');
    header.setUint32(40, dataLength, Endian.little);

    final random = math.Random();
    final brown = sound == AmbientSound.brownNoise;
    final smoothing = brown ? 0.96 : 0.72;
    final gain = brown ? 2.1 : 0.72;
    // Generate an extra ramp of samples and cross-fade it into the start so the
    // loop point is continuous (no periodic dip or click every 4 seconds).
    final raw = List<double>.filled(sampleCount + rampSamples, 0);
    var filtered = 0.0;
    for (var index = 0; index < raw.length; index++) {
      final white = random.nextDouble() * 2 - 1;
      filtered = filtered * smoothing + white * (1 - smoothing);
      raw[index] = filtered;
    }
    for (var index = 0; index < sampleCount; index++) {
      var value = raw[index];
      if (index < rampSamples) {
        final t = index / rampSamples;
        value = value * t + raw[sampleCount + index] * (1 - t);
      }
      final sample =
          (value * gain * 0.3 * 32767).round().clamp(-32768, 32767);
      header.setInt16(44 + index * 2, sample, Endian.little);
    }
    return bytes;
  }
}
