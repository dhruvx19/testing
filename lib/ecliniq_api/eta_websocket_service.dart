import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:ecliniq/ecliniq_api/models/eta_update.dart';
import 'package:ecliniq/ecliniq_api/src/endpoints.dart';


class ETAWebSocketService {
  IO.Socket? _socket;
  bool _isConnected = false;
  bool _isConnecting = false;

  // Stream controllers for different events
  final _etaUpdateController = StreamController<ETAUpdate>.broadcast();
  final _slotDisplayUpdateController = StreamController<SlotDisplayUpdate>.broadcast();
  final _connectionStatusController = StreamController<bool>.broadcast();
  final _errorController = StreamController<String>.broadcast();

  // Getters for streams
  Stream<ETAUpdate> get etaUpdateStream => _etaUpdateController.stream;
  Stream<SlotDisplayUpdate> get slotDisplayUpdateStream => _slotDisplayUpdateController.stream;
  Stream<bool> get connectionStatusStream => _connectionStatusController.stream;
  Stream<String> get errorStream => _errorController.stream;

  bool get isConnected => _isConnected;
  bool get isConnecting => _isConnecting;

  /// Connect to WebSocket server
  Future<void> connect() async {
    if (_isConnected || _isConnecting) {
      return;
    }

    try {
      _isConnecting = true;

      // Extract base URL from endpoints (remove /api path)
      final baseUrl = Endpoints.localhost.replaceAll('/api', '');

      _socket = IO.io(
        baseUrl,
        IO.OptionBuilder()
            .setTransports(['websocket', 'polling'])
            .setPath('/socket.io')
            .enableAutoConnect()
            .enableReconnection()
            .setReconnectionDelay(1000)
            .setReconnectionDelayMax(5000)
            .setReconnectionAttempts(5)
            .setTimeout(20000)
            .build(),
      );

      _setupEventHandlers();
    } catch (e) {
      _isConnecting = false;
      _errorController.add('Failed to connect: $e');
    }
  }

  /// Setup event handlers for socket events
  void _setupEventHandlers() {
    if (_socket == null) return;

    // Connection events
    _socket!.onConnect((_) {
      _isConnected = true;
      _isConnecting = false;
      _connectionStatusController.add(true);
    });

    _socket!.onDisconnect((_) {
      _isConnected = false;
      _isConnecting = false;
      _connectionStatusController.add(false);
    });

    _socket!.onConnectError((error) {
      _isConnecting = false;
      _errorController.add('Connection error: $error');
    });

    // Join response
    _socket!.on('joined', (data) {
      try {
        if (data is Map<String, dynamic>) {
          final joinResponse = JoinResponse.fromJson(data);
          if (joinResponse.currentETA != null) {
            _etaUpdateController.add(joinResponse.currentETA!);
          }
          if (joinResponse.currentState != null) {
            _slotDisplayUpdateController.add(joinResponse.currentState!);
          }
        }
      } catch (e) {
      }
    });

    // ETA update event
    _socket!.on('eta_update', (data) {
      try {
        if (data is Map<String, dynamic>) {
          final update = ETAUpdate.fromJson(data);
          _etaUpdateController.add(update);
        }
      } catch (e) {
      }
    });

    // Current token update for display screens
    _socket!.on('current_token_update', (data) {
      try {
        if (data is Map<String, dynamic>) {
          final update = SlotDisplayUpdate.fromJson(data);
          _slotDisplayUpdateController.add(update);
        }
      } catch (e) {
      }
    });

    // Error event
    _socket!.on('error', (data) {
      String errorMessage = 'Unknown error';
      if (data is Map<String, dynamic> && data['message'] != null) {
        errorMessage = data['message'].toString();
      } else if (data is String) {
        errorMessage = data;
      }
      _errorController.add(errorMessage);
    });
  }

  /// Join appointment room to receive ETA updates
  /// 
  /// [appointmentId] - The appointment ID to join
  /// [patientId] - Optional patient ID for verification
  Future<void> joinAppointment({
    required String appointmentId,
    String? patientId,
  }) async {
    if (!_isConnected) {
      await connect();
      // Wait a bit for connection to establish
      await Future.delayed(const Duration(milliseconds: 500));
    }

    if (_socket == null || !_isConnected) {
      throw Exception('WebSocket not connected');
    }

    _socket!.emit('join_appointment', {
      'appointmentId': appointmentId,
      if (patientId != null) 'patientId': patientId,
    });
  }

  /// Join doctor session room to receive slot updates
  /// 
  /// [doctorId] - The doctor ID
  /// [slotId] - The slot ID
  Future<void> joinDoctorSession({
    required String doctorId,
    required String slotId,
  }) async {
    if (!_isConnected) {
      await connect();
      await Future.delayed(const Duration(milliseconds: 500));
    }

    if (_socket == null || !_isConnected) {
      throw Exception('WebSocket not connected');
    }

    _socket!.emit('join_doctor_session', {
      'doctorId': doctorId,
      'slotId': slotId,
    });
  }

  /// Join slot display room for display screens
  /// 
  /// [slotId] - The slot ID to display
  Future<void> joinSlotDisplay({
    required String slotId,
  }) async {
    if (!_isConnected) {
      await connect();
      await Future.delayed(const Duration(milliseconds: 500));
    }

    if (_socket == null || !_isConnected) {
      throw Exception('WebSocket not connected');
    }

    _socket!.emit('join_slot_display', {
      'slotId': slotId,
    });
  }

  /// Leave all rooms and disconnect
  Future<void> disconnect() async {
    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
      _isConnected = false;
      _isConnecting = false;
      _connectionStatusController.add(false);
    }
  }

  /// Dispose all resources
  void dispose() {
    disconnect();
    _etaUpdateController.close();
    _slotDisplayUpdateController.close();
    _connectionStatusController.close();
    _errorController.close();
  }
}

