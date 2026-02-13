import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// A shared helper that handles microphone permission and speech recognition.
///
/// Explicitly requests [Permission.microphone] via `permission_handler` before
/// initializing `speech_to_text`. This fixes issues on OnePlus, Xiaomi, and
/// Samsung devices where the implicit permission request inside
/// `SpeechToText.initialize()` fails silently.
class SpeechHelper {
  SpeechHelper();

  final SpeechToText speechToText = SpeechToText();
  bool speechEnabled = false;
  bool isListening = false;

  /// Initialise speech recognition after explicitly requesting mic permission.
  Future<bool> initSpeech({
    required VoidCallback onListeningChanged,
    bool Function()? mounted,
  }) async {
    try {
      // Explicitly request microphone permission first
      final micStatus = await Permission.microphone.request();
      if (!micStatus.isGranted) {
        developer.log('Microphone permission denied: $micStatus');
        speechEnabled = false;
        return false;
      }

      speechEnabled = await speechToText.initialize(
        onError: (error) {
          final errorMsg = error.errorMsg.toLowerCase();
          if (!errorMsg.contains('no_match') &&
              !errorMsg.contains('listen_failed')) {
            developer.log('Speech recognition error: ${error.errorMsg}');
          }
          if (mounted?.call() ?? true) {
            isListening = false;
            onListeningChanged();
          }
        },
        onStatus: (status) {
          developer.log('Speech recognition status: $status');
          if (mounted?.call() ?? true) {
            if (status == 'notListening' ||
                status == 'done' ||
                status == 'doneNoResult') {
              isListening = false;
            } else if (status == 'listening') {
              isListening = true;
            }
            onListeningChanged();
          }
        },
      );

      developer.log('Speech recognition initialized: $speechEnabled');
      return speechEnabled;
    } catch (e) {
      developer.log('Error initializing speech recognition: $e');
      speechEnabled = false;
      return false;
    }
  }

  /// Start listening for speech input.
  ///
  /// Returns `true` if listening started successfully, `false` otherwise.
  /// [onResult] is called with each speech recognition result.
  /// [onError] is called when an error occurs (permission denied, etc.).
  Future<bool> startListening({
    required void Function(SpeechRecognitionResult result) onResult,
    void Function(String message)? onError,
    bool Function()? mounted,
    VoidCallback? onListeningChanged,
  }) async {
    if (isListening) return true;

    if (!speechEnabled) {
      final success = await initSpeech(
        onListeningChanged: onListeningChanged ?? () {},
        mounted: mounted,
      );
      if (!success) {
        final micStatus = await Permission.microphone.status;
        if (micStatus.isPermanentlyDenied) {
          onError?.call(
            'Microphone permission is permanently denied. Please enable it in Settings.',
          );
        } else {
          onError?.call(
            'Speech recognition is not available. Please check your permissions.',
          );
        }
        return false;
      }
    }

    try {
      await speechToText.listen(
        onResult: onResult,
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        localeId: 'en_US',
        listenOptions: SpeechListenOptions(
          partialResults: true,
          cancelOnError: false,
          listenMode: ListenMode.confirmation,
        ),
      );

      isListening = true;
      onListeningChanged?.call();
      return true;
    } catch (e) {
      developer.log('Error starting speech recognition: $e');
      isListening = false;
      onListeningChanged?.call();
      onError?.call('Error starting voice search: ${e.toString()}');
      return false;
    }
  }

  /// Stop listening for speech input.
  Future<void> stopListening({VoidCallback? onListeningChanged}) async {
    try {
      await speechToText.stop();
    } catch (e) {
      developer.log('Error stopping speech recognition: $e');
    }
    isListening = false;
    onListeningChanged?.call();
  }

  /// Cancel speech recognition and release resources.
  Future<void> cancel() async {
    await speechToText.cancel();
    isListening = false;
  }
}
