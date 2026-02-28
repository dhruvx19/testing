import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// A shared helper that handles microphone permission and speech recognition.
class SpeechHelper {
  // Singleton pattern
  static final SpeechHelper _instance = SpeechHelper._internal();
  factory SpeechHelper() => _instance;
  SpeechHelper._internal();

  final SpeechToText speechToText = SpeechToText();
  bool speechEnabled = false;
  bool isListening = false;

  static const _doneStatuses = {
    'notListening',
    'done',
    'doneNoResult',
    'inactive',
  };

  /// Request all required permissions upfront and return whether all granted.
  Future<bool> _requestPermissions() async {
    if (Platform.isIOS) {
      // Request both together on iOS
      final statuses = await [
        Permission.microphone,
        Permission.speech,
      ].request();

      final micGranted = statuses[Permission.microphone]?.isGranted ?? false;
      final speechGranted = statuses[Permission.speech]?.isGranted ?? false;

      developer.log('iOS permissions — mic: $micGranted, speech: $speechGranted');

      if (!micGranted || !speechGranted) {
        // Check if permanently denied
        final micDenied = statuses[Permission.microphone]?.isPermanentlyDenied ?? false;
        final speechDenied = statuses[Permission.speech]?.isPermanentlyDenied ?? false;

        if (micDenied || speechDenied) {
          developer.log('Permissions permanently denied — opening settings');
          await openAppSettings();
        }
        return false;
      }
      return true;
    } else {
      // Android — only microphone needed
      final micStatus = await Permission.microphone.request();
      developer.log('Android mic permission: $micStatus');

      if (!micStatus.isGranted) {
        if (micStatus.isPermanentlyDenied) {
          await openAppSettings();
        }
        return false;
      }
      return true;
    }
  }

  /// Initialise speech recognition.
  Future<bool> initSpeech({
    required VoidCallback onListeningChanged,
    bool Function()? mounted,
    bool requestPermissionsIfNeeded = true,
  }) async {
    try {
      if (requestPermissionsIfNeeded) {
        final granted = await _requestPermissions();
        if (!granted) {
          speechEnabled = false;
          return false;
        }
      }

      // Small yield to let OS sync permission state before engine init.
      await Future.delayed(const Duration(milliseconds: 500));

      speechEnabled = await speechToText.initialize(
        onError: (error) {
          final errorMsg = error.errorMsg.toLowerCase();
          developer.log('Speech error: ${error.errorMsg} (permanent: ${error.permanent})');

          if (mounted?.call() ?? true) {
            isListening = false;
            onListeningChanged();
          }

          // If permanently failed, reset so next call re-initializes
          if (error.permanent) {
            speechEnabled = false;
          }
        },
        onStatus: (status) {
          developer.log('Speech status: $status');
          if (mounted?.call() ?? true) {
            if (_doneStatuses.contains(status)) {
              isListening = false;
            } else if (status == 'listening') {
              isListening = true;
            }
            onListeningChanged();
          }
        },
        options: Platform.isAndroid ? [SpeechToText.androidNoBluetooth] : [],
      );

      developer.log('Speech initialized: $speechEnabled');
      return speechEnabled;
    } catch (e) {
      developer.log('Error initializing speech: $e');
      speechEnabled = false;
      return false;
    }
  }

  /// Start listening for speech input.
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
        developer.log('Speech init failed after permission check');

        if (Platform.isIOS) {
          final micStatus = await Permission.microphone.status;
          final speechStatus = await Permission.speech.status;
          developer.log('iOS status — mic: $micStatus, speech: $speechStatus');

          if (micStatus.isPermanentlyDenied || speechStatus.isPermanentlyDenied) {
            onError?.call('Please enable Microphone and Speech Recognition in Settings > Privacy.');
            await openAppSettings();
          } else {
            onError?.call('Could not start voice search. Please try again.');
          }
        } else {
          final micStatus = await Permission.microphone.status;
          if (micStatus.isPermanentlyDenied) {
            onError?.call('Please enable Microphone in Settings > Privacy.');
            await openAppSettings();
          } else {
            onError?.call('Could not start voice search. Please try again.');
          }
        }
        return false;
      }
    }

    try {
      await Future.delayed(const Duration(milliseconds: 100));

      await speechToText.listen(
        onResult: onResult,
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 5),
        listenOptions: SpeechListenOptions(
          partialResults: true,
          cancelOnError: false,
          listenMode: ListenMode.search,
          onDevice: false,
        ),
      );

      isListening = true;
      onListeningChanged?.call();
      return true;
    } catch (e) {
      developer.log('Error starting listening: $e');
      isListening = false;
      onListeningChanged?.call();

      if (e.toString().contains('not initialized')) {
        speechEnabled = false;
      }

      onError?.call('Could not start voice search. Please try again.');
      return false;
    }
  }

  /// Stop listening for speech input.
  Future<void> stopListening({VoidCallback? onListeningChanged}) async {
    try {
      if (speechToText.isListening) {
        await speechToText.stop();
      }
    } catch (e) {
      developer.log('Error stopping speech: $e');
    }
    isListening = false;
    onListeningChanged?.call();
  }

  /// Cancel speech recognition and release resources.
  Future<void> cancel() async {
    try {
      await speechToText.cancel();
    } catch (e) {
      developer.log('Error cancelling speech: $e');
    }
    isListening = false;
  }
}