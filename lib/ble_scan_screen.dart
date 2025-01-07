import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';
import 'device_details_screen.dart';

/// BLE Scan Screen for discovering BLE devices
class BLEScanScreen extends StatefulWidget {
  const BLEScanScreen({Key? key}) : super(key: key);

  @override
  BLEScanScreenState createState() => BLEScanScreenState();
}

class BLEScanScreenState extends State<BLEScanScreen> {
  final FlutterReactiveBle _ble = FlutterReactiveBle(); // BLE handler
  final List<DiscoveredDevice> _devices = []; // List of discovered devices
  late Stream<DiscoveredDevice> _scanStream; // BLE scan stream
  bool _isScanning = false; // Scan state

  @override
  void initState() {
    super.initState();
    // Check permissions and start scanning if granted
    _checkPermissions().then((isGranted) {
      if (isGranted) {
        _startScan();
      }
    });
  }

  /// Check required permissions for BLE functionality
  Future<bool> _checkPermissions() async {
    final statuses = await [
      Permission.location,
      Permission.bluetooth,
    ].request();

    final isLocationDenied = statuses[Permission.location]?.isDenied ?? true;
    final isBluetoothDenied = statuses[Permission.bluetooth]?.isDenied ?? true;

    if (isLocationDenied || isBluetoothDenied) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permissions are required to scan for devices.')),
      );
      return false;
    }
    return true;
  }

  /// Start scanning for BLE devices
  void _startScan() {
    setState(() {
      _isScanning = true;
      _devices.clear();
    });

    _scanStream = _ble.scanForDevices(
      withServices: [], // Replace with service UUIDs if required
      scanMode: ScanMode.lowLatency,
    );

    // Listen to the scan stream
    _scanStream.listen((device) {
      if (!_devices.any((d) => d.id == device.id)) {
        setState(() {
          _devices.add(device); // Add unique devices to the list
        });
      }
    }, onError: (error) {
      setState(() {
        _isScanning = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error scanning for devices: $error')),
      );
    }, onDone: () {
      setState(() {
        _isScanning = false;
      });
    });
  }

  /// Stop scanning
  void _stopScan() {
    setState(() {
      _isScanning = false;
    });
  }

  @override
  void dispose() {
    _stopScan();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checking For Devices'),
        actions: [
          if (_isScanning)
            IconButton(
              icon: const Icon(Icons.stop),
              onPressed: _stopScan,
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _startScan,
            ),
        ],
      ),
      body: Stack(
        children: [
          // Dynamically change the background image
          Positioned.fill(
            child: Image.asset(
              _devices.isNotEmpty
                  ? 'assets/backgroundlist.png' // Background for devices found
                  : 'assets/background.png', // Background when no devices
              fit: BoxFit.cover,
            ),
          ),
          // Foreground UI
          Column(
            children: [
              if (_isScanning)
                const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(), // Show loading indicator
                  ),
                )
              else if (_devices.isEmpty)
                const Expanded(
                  child: Center(
                    child: Text(
                      'No devices found.',
                      style: TextStyle(color: Colors.white),
                    ), // Show if no devices
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: _devices.length,
                    itemBuilder: (context, index) {
                      final device = _devices[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(255, 51, 51, 51), // Button background color
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                          ),
                          onPressed: () {
                            // Navigate to device details screen on tap
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    DeviceDetailsScreen(device: device),
                              ),
                            );
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                device.name.isEmpty ? 'Unknown Device' : device.name,
                                style: const TextStyle(
                                  color: Colors.white, // Text color
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                device.id,
                                style: const TextStyle(
                                  color: Colors.white70, // Subtext color
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
