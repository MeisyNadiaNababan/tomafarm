import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref();
  
  int _totalNodes = 0;
  int _totalFarmers = 0;
  int _activeNodes = 0;
  int _criticalAlarms = 0;
  List<Map<String, dynamic>> _recentAlarms = [];
  List<Map<String, dynamic>> _systemStats = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeDashboard();
  }

  void _initializeDashboard() {
    _loadNodesData();
    _loadFarmersData();
    _loadAlarmsData();
    _loadSystemStats();
  }

  void _loadNodesData() {
    _databaseRef.child('nodes').onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data != null) {
        setState(() {
          _totalNodes = data.length;
          _activeNodes = data.values.where((node) => 
            node['status'] == 'online').length;
        });
      }
    });
  }

  void _loadFarmersData() {
    _databaseRef.child('users').orderByChild('role').equalTo('farmer').onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data != null) {
        setState(() {
          _totalFarmers = data.length;
        });
      }
    });
  }

  void _loadAlarmsData() {
    _databaseRef.child('alarms')
      .orderByChild('timestamp')
      .limitToLast(10)
      .onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      final List<Map<String, dynamic>> alarms = [];
      
      if (data != null) {
        data.forEach((key, value) {
          alarms.add({
            'id': key,
            'title': value['title'] ?? 'Alarm',
            'message': value['message'],
            'type': value['type'],
            'nodeId': value['nodeId'],
            'severity': value['severity'] ?? 'medium',
            'timestamp': value['timestamp'],
            'read': value['read'] ?? false,
          });
        });
        
        setState(() {
          _recentAlarms = alarms.reversed.toList();
          _criticalAlarms = alarms.where((alarm) => 
            alarm['severity'] == 'high').length;
          _isLoading = false;
        });
      }
    });
  }

  void _loadSystemStats() {
    // Default system stats
    setState(() {
      _systemStats = [
        {'label': 'CPU Usage', 'value': '45%', 'icon': Icons.memory},
        {'label': 'Memory', 'value': '62%', 'icon': Icons.storage},
        {'label': 'Database', 'value': 'Online', 'icon': Icons.cloud_queue},
        {'label': 'API Status', 'value': 'Active', 'icon': Icons.api},
      ];
    });

    // Load actual stats from Firebase if available
    _databaseRef.child('systemStats').onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data != null) {
        setState(() {
          _systemStats = [
            {'label': 'CPU Usage', 'value': '${data['cpuUsage'] ?? 0}%', 'icon': Icons.memory},
            {'label': 'Memory', 'value': '${data['memoryUsage'] ?? 0}%', 'icon': Icons.storage},
            {'label': 'Database', 'value': 'Online', 'icon': Icons.cloud_queue},
            {'label': 'API Status', 'value': 'Active', 'icon': Icons.api},
          ];
        });
      }
    });
  }

  void _markAlarmAsRead(String alarmId) {
    _databaseRef.child('alarms/$alarmId/read').set(true);
  }

  Color _getSeverityColor(String severity) {
    switch (severity) {
      case 'high': return Colors.red;
      case 'medium': return Colors.orange;
      case 'low': return Colors.blue;
      default: return Colors.grey;
    }
  }

  IconData _getAlarmIcon(String type) {
    switch (type) {
      case 'soil_dry': return Icons.grass;
      case 'temperature_high': return Icons.thermostat;
      case 'temperature_low': return Icons.ac_unit;
      case 'humidity_low': return Icons.water_drop;
      case 'node_offline': return Icons.wifi_off;
      case 'pump_failure': return Icons.water_damage;
      case 'sensor_error': return Icons.error;
      default: return Icons.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    _buildHeader(),
                    const SizedBox(height: 24),

                    // Stats Grid
                    _buildStatsGrid(),
                    const SizedBox(height: 24),

                    // System Status
                    _buildSystemStatus(),
                    const SizedBox(height: 24),

                    // Recent Alarms
                    _buildRecentAlarms(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dashboard Admin',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Overview Sistem TomaFarm',
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.2,
      children: [
        _buildStatCard(
          'Total Node',
          '$_totalNodes',
          Icons.sensors,
          Colors.blue,
        ),
        _buildStatCard(
          'Total Petani',
          '$_totalFarmers',
          Icons.people,
          Colors.green,
        ),
        _buildStatCard(
          'Node Aktif',
          '$_activeNodes',
          Icons.wifi,
          Colors.green,
        ),
        _buildStatCard(
          'Alarm Kritis',
          '$_criticalAlarms',
          Icons.warning,
          Colors.red,
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
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
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemStatus() {
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
            'Status Sistem',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 3,
            children: _systemStats.map((stat) => _buildSystemStatusItem(stat)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemStatusItem(Map<String, dynamic> stat) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(stat['icon'], size: 16, color: Colors.green),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stat['label'],
                  style: const TextStyle(fontSize: 12),
                ),
                Text(
                  stat['value'],
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentAlarms() {
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
          const Row(
            children: [
              Icon(Icons.warning, color: Colors.orange),
              SizedBox(width: 8),
              Text(
                'Alarm Terbaru',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _recentAlarms.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Tidak ada alarm',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : Column(
                  children: _recentAlarms.take(5).map((alarm) => 
                    _buildAlarmItem(alarm)).toList(),
                ),
        ],
      ),
    );
  }

  Widget _buildAlarmItem(Map<String, dynamic> alarm) {
    final isUnread = alarm['read'] == false;
    final date = DateTime.fromMillisecondsSinceEpoch(alarm['timestamp']);
    final timeFormat = DateFormat('HH:mm');

    return GestureDetector(
      onTap: () => _markAlarmAsRead(alarm['id']),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUnread 
              ? _getSeverityColor(alarm['severity']).withOpacity(0.1)
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _getSeverityColor(alarm['severity']).withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _getSeverityColor(alarm['severity']).withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getAlarmIcon(alarm['type']),
                color: _getSeverityColor(alarm['severity']),
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alarm['title'],
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    alarm['message'],
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Node: ${alarm['nodeId']}',
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                Text(
                  timeFormat.format(date),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                if (isUnread)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}