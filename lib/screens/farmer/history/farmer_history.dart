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
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  void _loadLogs() {
    _databaseRef.child('logs').orderByChild('timestamp').onValue.listen((event) {
      try {
        final data = event.snapshot.value;
        final List<LogEntry> logs = [];

        if (data != null && data is Map) {
          data.forEach((key, value) {
            if (value is Map) {
              logs.add(LogEntry(
                id: key.toString(),
                timestamp: value['timestamp'] is int ? value['timestamp'] : DateTime.now().millisecondsSinceEpoch,
                action: value['action']?.toString() ?? 'Aktivitas Sistem',
                type: value['type']?.toString() ?? 'system',
                temperature: _toDouble(value['temperature']),
                humidity: _toDouble(value['humidity']),
                soilMoisture: _toDouble(value['soilMoisture']),
                value: _toDouble(value['value']),
                unit: value['unit']?.toString(),
              ));
            }
          });
        }

        // Sort by timestamp descending
        logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));

        setState(() {
          _logs = logs;
          _isLoading = false;
          _hasError = false;
        });
      } catch (e) {
        print('Error loading logs: $e');
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }, onError: (error) {
      print('Error listening to logs: $error');
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    });
  }

  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
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
      case '1jam':
        return now.subtract(const Duration(hours: 1));
      case '6jam':
        return now.subtract(const Duration(hours: 6));
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
      case '1jam':
        return '1 Jam';
      case '6jam':
        return '6 Jam';
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
      if (action.toLowerCase().contains('pompa') || action.toLowerCase().contains('water')) {
        return Icons.water_drop;
      } else if (action.toLowerCase().contains('lampu') || action.toLowerCase().contains('light')) {
        return Icons.lightbulb;
      } else if (action.toLowerCase().contains('mode') || action.toLowerCase().contains('auto')) {
        return Icons.auto_mode;
      }
      return Icons.engineering;
    } else if (type == 'sensor') {
      if (action.toLowerCase().contains('suhu') || action.toLowerCase().contains('temperature')) {
        return Icons.thermostat;
      } else if (action.toLowerCase().contains('kelembapan') || action.toLowerCase().contains('humidity')) {
        return Icons.water_drop;
      } else if (action.toLowerCase().contains('cahaya') || action.toLowerCase().contains('light')) {
        return Icons.light_mode;
      }
      return Icons.sensors;
    } else if (type == 'alert') {
      return Icons.warning;
    }
    return Icons.history;
  }

  Color _getLogColor(String type) {
    switch (type) {
      case 'control':
        return Colors.blue;
      case 'sensor':
        return Colors.green;
      case 'alert':
        return Colors.orange;
      case 'warning':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getLogBackgroundColor(String type) {
    switch (type) {
      case 'control':
        return Colors.blue.shade50;
      case 'sensor':
        return Colors.green.shade50;
      case 'alert':
        return Colors.orange.shade50;
      case 'warning':
        return Colors.red.shade50;
      default:
        return Colors.grey.shade50;
    }
  }

  void _refreshData() {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    _loadLogs();
  }

  @override
  Widget build(BuildContext context) {
    final filteredLogs = _selectedFilter == 'semua' ? _logs : _getFilteredLogs();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '📊 Riwayat Aktivitas',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFE8F5E8), Color(0xFFC8E6C9)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.history, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Log Aktivitas Sistem',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Total ${filteredLogs.length} aktivitas ditemukan',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Time Filter
              _buildTimeFilter(),
              const SizedBox(height: 20),

              // Content
              Expanded(
                child: _isLoading
                    ? _buildLoadingState()
                    : _hasError
                        ? _buildErrorState()
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
    final filters = ['1jam', '6jam', '24jam', '7hari', '1bulan', 'semua'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
              Icon(Icons.filter_alt, color: Colors.green, size: 18),
              SizedBox(width: 8),
              Text(
                'Filter Waktu',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: filters.map((filter) {
              final isActive = _selectedFilter == filter;
              return FilterChip(
                label: Text(_getFilterDisplayName(filter)),
                selected: isActive,
                onSelected: (selected) {
                  setState(() {
                    _selectedFilter = filter;
                  });
                },
                backgroundColor: Colors.grey.shade100,
                selectedColor: Colors.green,
                labelStyle: TextStyle(
                  color: isActive ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
                checkmarkColor: Colors.white,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLogList(List<LogEntry> logs) {
    return Column(
      children: [
        // Summary
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade100),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem('Total', logs.length.toString(), Icons.list),
              _buildSummaryItem(
                'Sensor',
                logs.where((log) => log.type == 'sensor').length.toString(),
                Icons.sensors,
              ),
              _buildSummaryItem(
                'Kontrol',
                logs.where((log) => log.type == 'control').length.toString(),
                Icons.engineering,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // List
        Expanded(
          child: ListView.separated(
            itemCount: logs.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final log = logs[index];
              return _buildLogItem(log);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryItem(String title, String value, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, size: 16, color: Colors.blue),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        Text(
          title,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildLogItem(LogEntry log) {
    final date = DateTime.fromMillisecondsSinceEpoch(log.timestamp);
    final timeFormat = DateFormat('HH:mm');
    final dateFormat = DateFormat('dd/MM/yyyy');
    final isToday = DateFormat('yyyyMMdd').format(date) == DateFormat('yyyyMMdd').format(DateTime.now());

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getLogBackgroundColor(log.type),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: _getLogColor(log.type).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _getLogColor(log.type).withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getLogIcon(log.type, log.action),
              color: _getLogColor(log.type),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.action,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
                if (log.temperature != null || log.humidity != null || log.soilMoisture != null || log.value != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      _buildSensorDataText(log),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getLogColor(log.type).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getTypeDisplayName(log.type),
                    style: TextStyle(
                      fontSize: 10,
                      color: _getLogColor(log.type),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Time
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                timeFormat.format(date),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                isToday ? 'Hari Ini' : dateFormat.format(date),
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getTypeDisplayName(String type) {
    switch (type) {
      case 'control':
        return 'KONTROL';
      case 'sensor':
        return 'SENSOR';
      case 'alert':
        return 'ALERT';
      case 'warning':
        return 'WARNING';
      default:
        return 'SISTEM';
    }
  }

  String _buildSensorDataText(LogEntry log) {
    final parts = <String>[];
    
    if (log.temperature != null) parts.add('🌡 ${log.temperature!.toStringAsFixed(1)}°C');
    if (log.humidity != null) parts.add('💧 ${log.humidity!.toStringAsFixed(1)}%');
    if (log.soilMoisture != null) parts.add('🌱 ${log.soilMoisture!.toStringAsFixed(1)}%');
    if (log.value != null) {
      final unit = log.unit ?? '';
      parts.add('📊 ${log.value!.toStringAsFixed(1)}$unit');
    }
    
    return parts.isNotEmpty ? parts.join(' • ') : 'Data sensor';
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              shape: BoxShape.circle,
            ),
            child: const CircularProgressIndicator(
              color: Colors.green,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Memuat data riwayat...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.green,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Mengambil data dari database',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline,
              size: 50,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Gagal memuat data',
            style: TextStyle(
              fontSize: 16,
              color: Colors.red,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Periksa koneksi internet Anda',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _refreshData,
            icon: const Icon(Icons.refresh),
            label: const Text('Coba Lagi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.history_toggle_off,
              size: 50,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Belum ada data riwayat',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Data riwayat akan muncul di sini\nsetelah ada aktivitas sistem',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _refreshData,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
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
  final double? value;
  final String? unit;

  LogEntry({
    required this.id,
    required this.timestamp,
    required this.action,
    required this.type,
    this.temperature,
    this.humidity,
    this.soilMoisture,
    this.value,
    this.unit,
  });
}