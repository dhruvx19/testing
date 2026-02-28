import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// A shared helper that handles microphone permission and speech recognition.
///
/// Explicitly requests [Permission.microphone] via `permission_handler` before
/// initialising `speech_to_text`. This fixes issues on Samsung, OnePlus and
/// Xiaomi devices where the implicit permission request inside
/// `SpeechToText.initialize()` fails silently.
///
/// On iOS an additional [Permission.speech] grant is required.
class SpeechHelper {
  SpeechHelper();

  final SpeechToText speechToText = SpeechToText();
  bool speechEnabled = false;
  bool isListening = false;

  // ─── Status strings that mean "no longer listening" ───────────────────────
  static const _doneStatuses = {
    'notListening',
    'done',
    'doneNoResult',
    'inactive',
  };

  /// Initialise speech recognition, optionally requesting permissions first.
  Future<bool> initSpeech({
    required VoidCallback onListeningChanged,
    bool Function()? mounted,
    bool requestPermissionsIfNeeded = true,
  }) async {
    try {
      // 1. Microphone — required on every platform.
      final micStatus = requestPermissionsIfNeeded
          ? await Permission.microphone.request()
          : await Permission.microphone.status;
          
      if (!micStatus.isGranted) {
        developer.log('Microphone permission not granted: $micStatus');
        speechEnabled = false;
        return false;
      }

      // 2. Speech recognition — iOS ONLY.
      if (Platform.isIOS) {
        final speechStatus = requestPermissionsIfNeeded
            ? await Permission.speech.request()
            : await Permission.speech.status;
            
        if (!speechStatus.isGranted) {
          developer.log('Speech recognition permission not granted: $speechStatus');
          speechEnabled = false;
          return false;
        }
      }

      // 3. Small yield to let OS sync permission state before engine init.
      await Future.delayed(const Duration(milliseconds: 100));

      // 4. Initialise the engine.
      speechEnabled = await speechToText.initialize(
        onError: (error) {
          final errorMsg = error.errorMsg.toLowerCase();
          // 'no_match' and 'listen_failed' are benign end-of-session signals.
          if (!errorMsg.contains('no_match') &&
              !errorMsg.contains('listen_failed') &&
              !errorMsg.contains('error_busy')) {
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
            if (_doneStatuses.contains(status)) {
              isListening = false;
            } else if (status == 'listening') {
              isListening = true;
            }
            onListeningChanged();
          }
        },
        options: [SpeechToText.androidNoBluetooth],
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
  Future<bool> startListening({
    required void Function(SpeechRecognitionResult result) onResult,
    void Function(String message)? onError,
    bool Function()? mounted,
    VoidCallback? onListeningChanged,
  }) async {
    if (isListening) return true;

    // Ensure engine is initialized and permissions are granted
    if (!speechEnabled) {
      final success = await initSpeech(
        onListeningChanged: onListeningChanged ?? () {},
        mounted: mounted,
      );
      
      if (!success) {
        // Double check specific status to give accurate error message
        final micS = await Permission.microphone.status;
        final speechS = Platform.isIOS ? await Permission.speech.status : PermissionStatus.granted;

        developer.log('Initialization failed. Status: mic=$micS, speech=$speechS');

        if (micS.isPermanentlyDenied || speechS.isPermanentlyDenied) {
          // One of them is permanently denied
          onError?.call(
            'Microphone and Speech Recognition permissions are required for voice search. Please Enable both in Settings.',
          );
          // Wait briefly so user can read message before settings opens
          await Future.delayed(const Duration(milliseconds: 800));
          await openAppSettings();
        } else if (micS.isGranted && speechS.isGranted) {
           // If they are granted but initialization still failed, try one more time
           // sometimes it needs a moment to catch up.
           await Future.delayed(const Duration(milliseconds: 300));
           final retrySuccess = await speechToText.initialize(options: [SpeechToText.androidNoBluetooth]);
           if (retrySuccess) {
             speechEnabled = true;
             // Continue to the listen() call below
           } else {
             onError?.call('Speech recognition is not available on this device right now. Please try again later.');
             return false;
           }
        } else if (micS.isDenied || speechS.isDenied) {
          onError?.call(
            'Microphone and Speech Recognition permissions are required for voice search.',
          );
        } else {
          onError?.call(
            'Voice search is not ready. Please try again in a moment.',
          );
        }

        if (!speechEnabled) return false;
      }
    }

    try {
      await speechToText.listen(
        onResult: onResult,
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        listenOptions: SpeechListenOptions(
          partialResults: true,
          cancelOnError: false,
          listenMode: ListenMode.search,
        ),
      );

      isListening = true;
      onListeningChanged?.call();
      return true;
    } catch (e) {
      developer.log('Error starting speech recognition: $e');
      isListening = false;
      onListeningChanged?.call();
      
      // If we failed to start, it might be because the engine became unavailable
      if (e.toString().contains('not initialized')) {
        speechEnabled = false;
      }
      
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
    try {
      await speechToText.cancel();
    } catch (e) {
      developer.log('Error cancelling speech recognition: $e');
    }
    isListening = false;
  }
}

