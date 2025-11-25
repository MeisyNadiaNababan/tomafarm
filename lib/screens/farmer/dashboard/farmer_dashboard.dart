import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'farmer_notifications.dart';
import 'simple_chart.dart';

class FarmerDashboardScreen extends StatefulWidget {
  const FarmerDashboardScreen({super.key});

  @override
  State<FarmerDashboardScreen> createState() => _FarmerDashboardScreenState();
}

class _FarmerDashboardScreenState extends State<FarmerDashboardScreen> {
  late DatabaseReference _databaseRef;
  bool _isLoading = true;
  int _unreadNotifications = 0;
  bool _notificationsEnabled = true;

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

  // Data untuk chart
  List<ChartData> temperatureData = [];
  List<ChartData> humidityData = [];
  List<ChartData> soilMoistureData = [];

  @override
  void initState() {
    super.initState();
    _databaseRef = FirebaseDatabase.instance.ref();
    _setupRealtimeListener();
    _loadNotificationSettings();
    _setupNotificationListener();
    _initializeChartData();
  }

  void _initializeChartData() {
    // Data dummy untuk chart
    temperatureData = [
      ChartData('08:00', 25.0),
      ChartData('10:00', 27.0),
      ChartData('12:00', 30.0),
      ChartData('14:00', 32.0),
      ChartData('16:00', 28.0),
      ChartData('18:00', 26.0),
    ];

    humidityData = [
      ChartData('08:00', 65.0),
      ChartData('10:00', 62.0),
      ChartData('12:00', 58.0),
      ChartData('14:00', 55.0),
      ChartData('16:00', 60.0),
      ChartData('18:00', 68.0),
    ];

    soilMoistureData = [
      ChartData('08:00', 45.0),
      ChartData('10:00', 42.0),
      ChartData('12:00', 38.0),
      ChartData('14:00', 35.0),
      ChartData('16:00', 50.0),
      ChartData('18:00', 55.0),
    ];
  }

  void _loadNotificationSettings() async {
    setState(() {
      _notificationsEnabled = true;
    });
  }

  void _setupNotificationListener() {
    if (_notificationsEnabled) {
      NotificationService.getNotifications().listen((notifications) {
        final unread = notifications.where((n) => !n.isRead).length;
        setState(() {
          _unreadNotifications = unread;
        });
      });
    }
  }

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

          _updateChartData();
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

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && _isLoading) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  void _updateChartData() {
    final now = DateTime.now();
    final timeLabel = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    
    setState(() {
      // Update data chart dengan data terbaru
      temperatureData.add(ChartData(timeLabel, sensorData['temperature']));
      humidityData.add(ChartData(timeLabel, sensorData['humidity']));
      soilMoistureData.add(ChartData(timeLabel, sensorData['soilMoisture']));
      
      // Batasi jumlah data yang ditampilkan
      if (temperatureData.length > 6) {
        temperatureData.removeAt(0);
        humidityData.removeAt(0);
        soilMoistureData.removeAt(0);
      }
    });
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

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

  void _showNotifications() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildNotificationsSheet(),
    );
  }

  Widget _buildNotificationsSheet() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text(
                  '🔔 Notifikasi',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (_unreadNotifications > 0)
                  TextButton(
                    onPressed: () {
                      NotificationService.markAllAsRead();
                      setState(() {
                        _unreadNotifications = 0;
                      });
                    },
                    child: const Text('Tandai Sudah Dibaca'),
                  ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<NotificationItem>>(
              stream: _notificationsEnabled 
                  ? NotificationService.getNotifications()
                  : Stream.value([]),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_none, size: 60, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Tidak ada notifikasi',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }
                
                final notifications = snapshot.data!;
                return ListView.builder(
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final notification = notifications[index];
                    return _buildNotificationItem(notification);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(NotificationItem notification) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: notification.isRead ? Colors.grey[50] : Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: notification.isRead ? Colors.grey[200]! : Colors.blue[200]!,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: notification.typeColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              notification.typeIcon,
              color: notification.typeColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.title,
                  style: TextStyle(
                    fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  notification.message,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  notification.formattedTime,
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ),
          if (!notification.isRead)
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Colors.green),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.agriculture,
                  size: 50,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'TomaFarm',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Memuat data sensor...',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
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
                _buildChartSection(),
                const SizedBox(height: 24),
                _buildQuickActions(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Monitoring Real-time',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
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
                ],
              ),
            ),
            Stack(
              children: [
                IconButton(
                  onPressed: _showNotifications,
                  icon: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.notifications, color: Colors.green),
                  ),
                ),
                if (_unreadNotifications > 0 && _notificationsEnabled)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        _unreadNotifications > 9 ? '9+' : _unreadNotifications.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Data terkini dari sensor kebun tomat',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildSensorGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '📊 Data Sensor',
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
              backgroundColor: Colors.red[50]!,
            ),
            _buildSensorCard(
              icon: Icons.water_drop,
              title: 'Kelembapan Udara',
              value: '${sensorData['humidity']?.toStringAsFixed(1)}%',
              unit: 'Persen',
              status: _getStatusMessage('humidity', sensorData['humidity']),
              color: Colors.blue,
              statusColor: _getStatusColor('humidity', sensorData['humidity']),
              backgroundColor: Colors.blue[50]!,
            ),
            _buildSensorCard(
              icon: Icons.grass,
              title: 'Kelembapan Tanah',
              value: '${sensorData['soilMoisture']?.toStringAsFixed(1)}%',
              unit: 'Persen',
              status: _getStatusMessage('soilMoisture', sensorData['soilMoisture']),
              color: Colors.brown,
              statusColor: _getStatusColor('soilMoisture', sensorData['soilMoisture']),
              backgroundColor: Colors.brown[50]!,
            ),
            _buildSensorCard(
              icon: Icons.light_mode,
              title: 'Intensitas Cahaya',
              value: '${sensorData['lightIntensity']?.toStringAsFixed(0)}',
              unit: 'Lux',
              status: _getStatusMessage('lightIntensity', sensorData['lightIntensity']),
              color: Colors.amber,
              statusColor: _getStatusColor('lightIntensity', sensorData['lightIntensity']),
              backgroundColor: Colors.amber[50]!,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSensorCard({
    required IconData icon,
    required String title,
    required String value,
    required String unit,
    required String status,
    required Color color,
    required Color statusColor,
    required Color backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
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
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  unit,
                  style: TextStyle(
                    fontSize: 10,
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
              height: 1.2,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  status,
                  style: TextStyle(
                    fontSize: 12,
                    color: statusColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActuatorStatus() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.engineering, color: Colors.green),
              SizedBox(width: 8),
              Text(
                'Status Aktuator',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildActuatorItem(
                icon: Icons.water_drop,
                title: 'Pompa Air',
                status: actuatorData['pump'] ? 'ON' : 'OFF',
                statusColor: actuatorData['pump'] ? Colors.green : Colors.red,
                mode: actuatorData['autoMode'] ? 'Auto' : 'Manual',
                backgroundColor: Colors.blue[50]!,
              ),
              const SizedBox(width: 12),
              _buildActuatorItem(
                icon: Icons.lightbulb,
                title: 'Lampu Tumbuh',
                status: actuatorData['light'] ? 'ON' : 'OFF',
                statusColor: actuatorData['light'] ? Colors.green : Colors.red,
                mode: actuatorData['autoMode'] ? 'Auto' : 'Manual',
                backgroundColor: Colors.amber[50]!,
              ),
              const SizedBox(width: 12),
              _buildActuatorItem(
                icon: actuatorData['autoMode'] ? Icons.auto_mode : Icons.engineering,
                title: 'Mode Sistem',
                status: actuatorData['autoMode'] ? 'Auto' : 'Manual',
                statusColor: actuatorData['autoMode'] ? Colors.blue : Colors.orange,
                mode: 'Aktif',
                backgroundColor: Colors.purple[50]!,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info,
                  color: Colors.green[700],
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    actuatorData['autoMode'] 
                      ? 'Sistem berjalan otomatis berdasarkan kondisi sensor'
                      : 'Kontrol manual aktif - Anda dapat mengontrol di halaman Kontrol',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green[700],
                    ),
                  ),
                ),
              ],
            ),
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
    required String mode,
    required Color backgroundColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: statusColor.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
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
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.withOpacity(0.3)),
              ),
              child: Text(
                mode,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.trending_up, color: Colors.blue),
              SizedBox(width: 8),
              Text(
                '📈 Trend Data Sensor',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SimpleChart(
            data: temperatureData,
            title: 'Suhu (°C)',
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          SimpleChart(
            data: humidityData,
            title: 'Kelembapan Udara (%)',
            color: Colors.blue,
          ),
          const SizedBox(height: 16),
          SimpleChart(
            data: soilMoistureData,
            title: 'Kelembapan Tanah (%)',
            color: Colors.brown,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.purple[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.flash_on, color: Colors.purple),
              SizedBox(width: 8),
              Text(
                'Akses Cepat',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildQuickActionItem(
                icon: Icons.control_camera,
                title: 'Kontrol',
                color: Colors.green,
              ),
              _buildQuickActionItem(
                icon: Icons.history,
                title: 'Riwayat',
                color: Colors.blue,
              ),
              _buildQuickActionItem(
                icon: Icons.settings,
                title: 'Pengaturan',
                color: Colors.orange,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionItem({
    required IconData icon,
    required String title,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}