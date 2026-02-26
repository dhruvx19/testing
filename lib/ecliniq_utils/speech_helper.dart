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
/// On Android this is NOT requested because Android has no separate
/// speech-recognition permission — only RECORD_AUDIO (microphone) applies.
class SpeechHelper {
  SpeechHelper();

  final SpeechToText speechToText = SpeechToText();
  bool speechEnabled = false;
  bool isListening = false;

  // ─── Status strings that mean "no longer listening" ───────────────────────
  // 'notListening' / 'done' / 'doneNoResult' — standard speech_to_text
  // 'inactive'  — emitted by Samsung OneUI 5+ and some Xiaomi MIUI ROMs
  static const _doneStatuses = {'notListening', 'done', 'doneNoResult', 'inactive'};

  /// Initialise speech recognition, optionally requesting permissions first.
  ///
  /// [requestPermissionsIfNeeded] controls whether system permission dialogs
  /// are shown when permissions have not yet been granted.
  ///
  /// Pass `requestPermissionsIfNeeded: false` when calling from [initState]
  /// so that no iOS dialogs appear on page load — permissions will only be
  /// requested when the user explicitly taps the mic button (via
  /// [startListening], which always passes the default value of `true`).
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
        developer.log('Microphone permission denied: $micStatus');
        speechEnabled = false;
        return false;
      }

      // 2. Speech recognition — iOS ONLY.
      //    Android has no separate speech permission; requesting it on Android
      //    can return unexpected statuses on Samsung / Xiaomi OEM ROMs and
      //    blocks initialisation unnecessarily.
      if (Platform.isIOS) {
        final speechStatus = requestPermissionsIfNeeded
            ? await Permission.speech.request()
            : await Permission.speech.status;
        if (!speechStatus.isGranted) {
          developer.log('Speech recognition permission denied: $speechStatus');
          speechEnabled = false;
          return false;
        }
      }

      // 3. Initialise the engine.
      //    androidNoBluetooth: prevents Samsung devices routing audio through
      //    Bluetooth, which causes "recognizer_busy" / silent failures.
      speechEnabled = await speechToText.initialize(
        onError: (error) {
          final errorMsg = error.errorMsg.toLowerCase();
          // 'no_match' and 'listen_failed' are benign end-of-session signals.
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
  ///
  /// Returns `true` if listening started successfully, `false` otherwise.
  /// [onResult] is called with each speech recognition result.
  /// [onError] is called when the feature is unavailable or denied.
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

        // On iOS also check the speech-recognition permission.
        final bool permPermanentlyDenied = micStatus.isPermanentlyDenied ||
            (Platform.isIOS && (await Permission.speech.status).isPermanentlyDenied);
        final bool permDenied = micStatus.isDenied ||
            (Platform.isIOS && (await Permission.speech.status).isDenied);

        if (permPermanentlyDenied) {
          // Take the user directly to Settings so they can re-enable.
          await openAppSettings();
        } else if (permDenied) {
          onError?.call(
            'Microphone permission is required for voice search. Please allow access.',
          );
        } else {
          onError?.call(
            'Speech recognition is not available on this device.',
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
        // Do NOT hardcode localeId — 'en_US' is not guaranteed to be installed
        // on Samsung / Xiaomi / OPPO devices, causing silent failures.
        // Omitting it lets the device use its own default language.
        listenOptions: SpeechListenOptions(
          partialResults: true,
          cancelOnError: false,
          // ListenMode.search is the correct mode for search inputs and
          // produces better short-phrase results on Samsung OneUI.
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
