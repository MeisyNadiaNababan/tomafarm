import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref();
  List<LogEntry> _logs = [];
  String _selectedFilter = '24jam';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  void _loadLogs() {
    _databaseRef.child('logs').orderByChild('timestamp').onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      final List<LogEntry> logs = [];

      if (data != null) {
        data.forEach((key, value) {
          logs.add(LogEntry(
            id: key,
            timestamp: value['timestamp'],
            action: value['action'] ?? '',
            type: value['type'] ?? '',
            temperature: value['temperature']?.toDouble(),
            humidity: value['humidity']?.toDouble(),
            soilMoisture: value['soilMoisture']?.toDouble(),
          ));
        });
      }

      // Sort by timestamp descending
      logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      setState(() {
        _logs = logs;
        _isLoading = false;
      });
    });
  }

  List<LogEntry> _getFilteredLogs() {
    final now = DateTime.now();
    final cutoff = _getCutoffTime(now);

    return _logs.where((log) {
      final logTime = DateTime.fromMillisecondsSinceEpoch(log.timestamp);
      return logTime.isAfter(cutoff);
    }).toList();
  }

  DateTime _getCutoffTime(DateTime now) {
    switch (_selectedFilter) {
      case '24jam':
        return now.subtract(const Duration(hours: 24));
      case '7hari':
        return now.subtract(const Duration(days: 7));
      case '1bulan':
        return now.subtract(const Duration(days: 30));
      default:
        return now.subtract(const Duration(hours: 24));
    }
  }

  String _getFilterDisplayName(String filter) {
    switch (filter) {
      case '24jam':
        return '24 Jam';
      case '7hari':
        return '7 Hari';
      case '1bulan':
        return '1 Bulan';
      case 'semua':
        return 'Semua';
      default:
        return '24 Jam';
    }
  }

  IconData _getLogIcon(String type, String action) {
    if (type == 'control') {
      if (action.contains('Pompa')) {
        return Icons.water_drop;
      } else if (action.contains('Lampu')) {
        return Icons.lightbulb;
      } else if (action.contains('Mode')) {
        return Icons.auto_mode;
      }
    } else if (type == 'sensor') {
      return Icons.sensors;
    }
    return Icons.history;
  }

  Color _getLogColor(String type) {
    switch (type) {
      case 'control':
        return Colors.blue;
      case 'sensor':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredLogs = _selectedFilter == 'semua' ? _logs : _getFilteredLogs();

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Riwayat Data Sensor & Kontrol',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Log aktivitas sistem dan data sensor',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 24),

              _buildTimeFilter(),
              const SizedBox(height: 24),

              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : filteredLogs.isEmpty
                        ? _buildEmptyState()
                        : _buildLogList(filteredLogs),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeFilter() {
    final filters = ['24jam', '7hari', '1bulan', 'semua'];

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
            'Pilih Periode Waktu',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: filters.map((filter) {
              final isActive = _selectedFilter == filter;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedFilter = filter;
                      });
                    },
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: isActive ? Colors.green : Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: isActive ? null : Border.all(color: Colors.grey.shade300),
                      ),
                      child: Center(
                        child: Text(
                          _getFilterDisplayName(filter),
                          style: TextStyle(
                            color: isActive ? Colors.white : Theme.of(context).colorScheme.onBackground,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLogList(List<LogEntry> logs) {
    return ListView.builder(
      itemCount: logs.length,
      itemBuilder: (context, index) {
        final log = logs[index];
        final date = DateTime.fromMillisecondsSinceEpoch(log.timestamp);
        final timeFormat = DateFormat('HH:mm');
        final dateFormat = DateFormat('dd/MM/yyyy');

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getLogColor(log.type).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getLogIcon(log.type, log.action),
                  color: _getLogColor(log.type),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      log.action,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (log.temperature != null || log.humidity != null || log.soilMoisture != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          _buildSensorDataText(log),
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    timeFormat.format(date),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    dateFormat.format(date),
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onBackground.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _buildSensorDataText(LogEntry log) {
    final parts = <String>[];
    if (log.temperature != null) parts.add('Suhu: ${log.temperature!.toStringAsFixed(1)}°C');
    if (log.humidity != null) parts.add('Udara: ${log.humidity!.toStringAsFixed(1)}%');
    if (log.soilMoisture != null) parts.add('Tanah: ${log.soilMoisture!.toStringAsFixed(1)}%');
    return parts.join(' • ');
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 80,
            color: Theme.of(context).colorScheme.onBackground.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Tidak ada data riwayat',
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.onBackground.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Data riwayat akan muncul di sini',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onBackground.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }
}

class LogEntry {
  final String id;
  final int timestamp;
  final String action;
  final String type;
  final double? temperature;
  final double? humidity;
  final double? soilMoisture;

  LogEntry({
    required this.id,
    required this.timestamp,
    required this.action,
    required this.type,
    this.temperature,
    this.humidity,
    this.soilMoisture,
  });
}