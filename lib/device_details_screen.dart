import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

/// Screen to display and interact with a connected BLE device
class DeviceDetailsScreen extends StatefulWidget {
  final DiscoveredDevice device; // Device passed from the previous screen

  const DeviceDetailsScreen({Key? key, required this.device}) : super(key: key);

  @override
  State<DeviceDetailsScreen> createState() => DeviceDetailsScreenState();
}

class DeviceDetailsScreenState extends State<DeviceDetailsScreen> {
  final FlutterReactiveBle ble = FlutterReactiveBle(); // BLE handler
  StreamSubscription<ConnectionStateUpdate>? _connectionSubscription;
  final List<DiscoveredCharacteristic> _characteristics = [];
  bool _isConnecting = true;
  bool _isListening = false;
  StreamSubscription<List<int>>? _notificationSubscription;

  // Variables to store accelerometer and gyroscope data
  String accelerometerData = 'X: 0, Y: 0, Z: 0';
  String gyroscopeData = 'X: 0, Y: 0, Z: 0';

  @override
  void initState() {
    super.initState();
    _connectToDevice(); // Attempt to connect on initialization
  }

  /// Connect to the BLE device
  Future<void> _connectToDevice() async {
    _connectionSubscription = ble
        .connectToDevice(
          id: widget.device.id,
          connectionTimeout: const Duration(seconds: 5),
        )
        .listen((state) {
      if (state.connectionState == DeviceConnectionState.connected) {
        _discoverServices(); // Discover services once connected
      } else if (state.connectionState == DeviceConnectionState.disconnected) {
        setState(() {
          _isConnecting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Device disconnected')),
        );
      }
    }, onError: (error) {
      setState(() {
        _isConnecting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connection failed: $error')),
      );
    });
  }

  /// Discover services and characteristics
  Future<void> _discoverServices() async {
    try {
      final services = await ble.discoverServices(widget.device.id);
      setState(() {
        for (var service in services) {
          _characteristics.addAll(service.characteristics);
        }
        _isConnecting = false; // Update UI state
      });

      // Automatically start notifications if available
      for (final characteristic in _characteristics) {
        if (characteristic.isNotifiable) {
          _startNotifications(characteristic);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to discover services: $e')),
      );
    }
  }

  /// Start listening to notifications
  Future<void> _startNotifications(DiscoveredCharacteristic characteristic) async {
    if (_isListening) return; // Avoid multiple listeners

    final qualifiedCharacteristic = QualifiedCharacteristic(
      characteristicId: characteristic.characteristicId,
      serviceId: characteristic.serviceId,
      deviceId: widget.device.id,
    );

    _notificationSubscription = ble
        .subscribeToCharacteristic(qualifiedCharacteristic)
        .listen((data) {
      _processNotificationData(data); // Process incoming data
    }, onError: (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to receive notifications: $error')),
      );
    });

    setState(() {
      _isListening = true;
    });
  }

  /// Process incoming notification data
  void _processNotificationData(List<int> data) {
    try {
      // Assuming data is in JSON format for accelerometer and gyroscope
      final decodedData = utf8.decode(data);
      final parsedData = jsonDecode(decodedData);

      if (parsedData.containsKey('accelerometer')) {
        final accel = parsedData['accelerometer'];
        setState(() {
          accelerometerData = 'X: ${accel['x']}, Y: ${accel['y']}, Z: ${accel['z']}';
        });
      }

      if (parsedData.containsKey('gyroscope')) {
        final gyro = parsedData['gyroscope'];
        setState(() {
          gyroscopeData = 'X: ${gyro['x']}, Y: ${gyro['y']}, Z: ${gyro['z']}';
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error processing data: $e')),
      );
    }
  }

  @override
  void dispose() {
    _connectionSubscription?.cancel();
    _notificationSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.device.name.isNotEmpty ? widget.device.name : 'Unknown Device'),
      ),
      body: _isConnecting
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const SizedBox(height: 20),
                Text(
                  'Accelerometer Data',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(
                  accelerometerData,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),
                Text(
                  'Gyroscope Data',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(
                  gyroscopeData,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView.builder(
                    itemCount: _characteristics.length,
                    itemBuilder: (context, index) {
                      final characteristic = _characteristics[index];
                      return ListTile(
                        title: Text('Characteristic: ${characteristic.characteristicId}'),
                        subtitle: Text('Service: ${characteristic.serviceId}'),
                        onTap: () => _readCharacteristicData(characteristic),
                      );
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushReplacementNamed(context, '/ble_scan');
        },
        child: const Icon(Icons.home),
        tooltip: 'Go to BLE Scan',
      ),
    );
  }

  /// Read data directly from a characteristic
  Future<void> _readCharacteristicData(DiscoveredCharacteristic characteristic) async {
    final qualifiedCharacteristic = QualifiedCharacteristic(
      characteristicId: characteristic.characteristicId,
      serviceId: characteristic.serviceId,
      deviceId: widget.device.id,
    );

    try {
      final data = await ble.readCharacteristic(qualifiedCharacteristic);
      _processNotificationData(data); // Reuse processing logic
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to read characteristic: $e')),
      );
    }
  }
}
