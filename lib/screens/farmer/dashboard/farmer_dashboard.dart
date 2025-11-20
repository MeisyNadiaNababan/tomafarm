import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late DatabaseReference _databaseRef;
  bool _isLoading = true;

  Map<String, dynamic> sensorData = {
    'temperature': 0.0,
    'humidity': 0.0,
    'soilMoisture': 0.0,
    'lightIntensity': 0.0,
  };

  Map<String, dynamic> actuatorData = {
    'pump': false,
    'light': false,
    'autoMode': true,
  };

  @override
  void initState() {
    super.initState();
    _databaseRef = FirebaseDatabase.instance.ref();
    _setupRealtimeListener();
  }

  /// Listener untuk sensor dan kontrol
  void _setupRealtimeListener() {
    // SENSOR
    _databaseRef.child('sensorData').onValue.listen((event) {
      try {
        final data = event.snapshot.value;

        if (data != null && data is Map) {
          setState(() {
            sensorData = {
              'temperature': _toDouble(data['temperature']),
              'humidity': _toDouble(data['humidity']),
              'soilMoisture': _toDouble(data['soilMoisture']),
              'lightIntensity': _toDouble(data['lightIntensity']),
            };
            _isLoading = false;
          });
        }
      } catch (e) {
        print('Error reading sensor data: $e');
      }
    });

    // ACTUATOR
    _databaseRef.child('control').onValue.listen((event) {
      try {
        final data = event.snapshot.value;

        if (data != null && data is Map) {
          setState(() {
            actuatorData = {
              'pump': data['pump'] == true,
              'light': data['light'] == true,
              'autoMode': data['autoMode'] == true,
            };
          });
        }
      } catch (e) {
        print('Error reading control data: $e');
      }
    });

    // Set loading false after 2 seconds if no data
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && _isLoading) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  /// Helper untuk konversi ke double dengan aman
  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  /// Status sensor
  String _getStatusMessage(String type, double value) {
    switch (type) {
      case 'temperature':
        return value > 30 ? 'Panas' : value < 20 ? 'Dingin' : 'Optimal';
      case 'humidity':
        return value > 80 ? 'Lembab' : value < 40 ? 'Kering' : 'Normal';
      case 'soilMoisture':
        return value < 30 ? 'Kering' : value > 70 ? 'Basah' : 'Optimal';
      case 'lightIntensity':
        return value > 800 ? 'Terang' : value < 300 ? 'Redup' : 'Cukup';
      default:
        return 'Normal';
    }
  }

  /// Warna status
  Color _getStatusColor(String type, double value) {
    switch (type) {
      case 'temperature':
        return value > 30 ? Colors.orange : value < 20 ? Colors.blue : Colors.green;
      case 'humidity':
        return value > 80 ? Colors.orange : value < 40 ? Colors.red : Colors.green;
      case 'soilMoisture':
        return value < 30 ? Colors.red : value > 70 ? Colors.blue : Colors.green;
      case 'lightIntensity':
        return value < 300 ? Colors.orange : Colors.green;
      default:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.background,
        body: const Center(
          child: CircularProgressIndicator(color: Colors.green),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            setState(() {
              _isLoading = true;
            });
            await Future.delayed(const Duration(seconds: 1));
            setState(() {
              _isLoading = false;
            });
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                _buildSensorGrid(),
                const SizedBox(height: 24),
                _buildActuatorStatus(),
                const SizedBox(height: 24),
                _buildChartPlaceholder(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// HEADER
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Monitoring Real-time',
          style: TextStyle(
            fontSize: 16,
            color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Smart Farming Tomat',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Data terkini dari sensor kebun tomat',
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).colorScheme.onBackground.withOpacity(0.5),
          ),
        ),
      ],
    );
  }

  /// GRID SENSOR
  Widget _buildSensorGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Data Sensor',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.1,
          children: [
            _buildSensorCard(
              icon: Icons.thermostat,
              title: 'Suhu',
              value: '${sensorData['temperature']?.toStringAsFixed(1)}°C',
              unit: 'Celcius',
              status: _getStatusMessage('temperature', sensorData['temperature']),
              color: Colors.red,
              statusColor: _getStatusColor('temperature', sensorData['temperature']),
            ),
            _buildSensorCard(
              icon: Icons.water_drop,
              title: 'Kelembapan Udara',
              value: '${sensorData['humidity']?.toStringAsFixed(1)}%',
              unit: 'Persen',
              status: _getStatusMessage('humidity', sensorData['humidity']),
              color: Colors.blue,
              statusColor: _getStatusColor('humidity', sensorData['humidity']),
            ),
            _buildSensorCard(
              icon: Icons.grass,
              title: 'Kelembapan Tanah',
              value: '${sensorData['soilMoisture']?.toStringAsFixed(1)}%',
              unit: 'Persen',
              status: _getStatusMessage('soilMoisture', sensorData['soilMoisture']),
              color: Colors.brown,
              statusColor: _getStatusColor('soilMoisture', sensorData['soilMoisture']),
            ),
            _buildSensorCard(
              icon: Icons.light_mode,
              title: 'Intensitas Cahaya',
              value: '${sensorData['lightIntensity']?.toStringAsFixed(0)}',
              unit: 'Lux',
              status: _getStatusMessage('lightIntensity', sensorData['lightIntensity']),
              color: Colors.amber,
              statusColor: _getStatusColor('lightIntensity', sensorData['lightIntensity']),
            ),
          ],
        ),
      ],
    );
  }

  /// CARD SENSOR
  Widget _buildSensorCard({
    required IconData icon,
    required String title,
    required String value,
    required String unit,
    required String status,
    required Color color,
    required Color statusColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              Text(
                unit,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onBackground.withOpacity(0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 12,
                color: statusColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// STATUS AKTUATOR
  Widget _buildActuatorStatus() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Status Aktuator',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildActuatorItem(
                icon: Icons.water_drop,
                title: 'Pompa Air',
                status: actuatorData['pump'] ? 'ON' : 'OFF',
                statusColor: actuatorData['pump'] ? Colors.green : Colors.grey,
              ),
              const SizedBox(width: 12),
              _buildActuatorItem(
                icon: Icons.lightbulb,
                title: 'Lampu Tumbuh',
                status: actuatorData['light'] ? 'ON' : 'OFF',
                statusColor: actuatorData['light'] ? Colors.green : Colors.grey,
              ),
              const SizedBox(width: 12),
              _buildActuatorItem(
                icon: actuatorData['autoMode'] ? Icons.auto_mode : Icons.engineering,
                title: 'Mode',
                status: actuatorData['autoMode'] ? 'Auto' : 'Manual',
                statusColor: actuatorData['autoMode'] ? Colors.blue : Colors.orange,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActuatorItem({
    required IconData icon,
    required String title,
    required String status,
    required Color statusColor,
  }) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: statusColor, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            status,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }

  /// CHART (placeholder)
  Widget _buildChartPlaceholder() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Trend Data Sensor',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 150,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bar_chart, size: 40, color: Colors.grey),
                  SizedBox(height: 8),
                  Text(
                    'Fitur Chart Akan Segera Hadir',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // Cleanup listeners if needed
    super.dispose();
  }
}