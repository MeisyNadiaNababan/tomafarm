import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class ControlScreen extends StatefulWidget {
  const ControlScreen({super.key});

  @override
  State<ControlScreen> createState() => _ControlScreenState();
}

class _ControlScreenState extends State<ControlScreen> {
  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref();
  bool _pumpStatus = false;
  bool _lightStatus = false;
  bool _autoMode = true;

  @override
  void initState() {
    super.initState();
    _loadControlStatus();
  }

  void _loadControlStatus() {
    _databaseRef.child('control').onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data != null) {
        setState(() {
          _pumpStatus = data['pump'] == true;
          _lightStatus = data['light'] == true;
          _autoMode = data['autoMode'] == true;
        });
      }
    });
  }

  void _togglePump() {
    setState(() {
      _pumpStatus = !_pumpStatus;
    });
    _databaseRef.child('control/pump').set(_pumpStatus);
    
    // Log the action
    _logAction('Pompa Air ${_pumpStatus ? 'DIHIDUPKAN' : 'DIMATIKAN'}');
  }

  void _toggleLight() {
    setState(() {
      _lightStatus = !_lightStatus;
    });
    _databaseRef.child('control/light').set(_lightStatus);
    
    // Log the action
    _logAction('Lampu Tumbuh ${_lightStatus ? 'DIHIDUPKAN' : 'DIMATIKAN'}');
  }

  void _toggleAutoMode() {
    setState(() {
      _autoMode = !_autoMode;
    });
    _databaseRef.child('control/autoMode').set(_autoMode);
    
    // Log the action
    _logAction('Mode ${_autoMode ? 'OTOMATIS' : 'MANUAL'} diaktifkan');
  }

  void _logAction(String action) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    _databaseRef.child('logs').push().set({
      'timestamp': timestamp,
      'action': action,
      'type': 'control',
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Kontrol Aktuator',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Kontrol manual pompa air dan lampu tumbuh',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 32),

              _buildControlMode(),
              const SizedBox(height: 24),
              _buildPumpControl(),
              const SizedBox(height: 24),
              _buildLightControl(),
              const SizedBox(height: 24),
              _buildSystemStatus(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlMode() {
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
      child: Row(
        children: [
          Icon(
            _autoMode ? Icons.auto_mode : Icons.engineering,
            color: _autoMode ? Colors.green : Colors.blue,
            size: 30,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _autoMode ? 'Mode Otomatis' : 'Mode Manual',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _autoMode 
                    ? 'Sistem mengontrol secara otomatis'
                    : 'Kontrol manual diaktifkan',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _autoMode,
            onChanged: (value) => _toggleAutoMode(),
            activeColor: Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildPumpControl() {
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.water_drop, color: Colors.blue, size: 24),
              ),
              const SizedBox(width: 12),
              const Text(
                'Kontrol Pompa Air',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _pumpStatus ? 'MENYALA' : 'MATI',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _pumpStatus ? Colors.green : Colors.red,
                      ),
                    ),
                    Text(
                      _pumpStatus ? 'Pompa aktif mengalirkan air' : 'Pompa non-aktif',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 120,
                height: 60,
                child: Switch(
                  value: _pumpStatus,
                  onChanged: _autoMode ? null : (value) => _togglePump(),
                  activeColor: Colors.green,
                  inactiveThumbColor: Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLightControl() {
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lightbulb, color: Colors.amber, size: 24),
              ),
              const SizedBox(width: 12),
              const Text(
                'Kontrol Lampu Tumbuh',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _lightStatus ? 'MENYALA' : 'MATI',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _lightStatus ? Colors.green : Colors.red,
                      ),
                    ),
                    Text(
                      _lightStatus ? 'Lampu aktif menyinari tanaman' : 'Lampu non-aktif',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 120,
                height: 60,
                child: Switch(
                  value: _lightStatus,
                  onChanged: _autoMode ? null : (value) => _toggleLight(),
                  activeColor: Colors.green,
                  inactiveThumbColor: Colors.red,
                ),
              ),
            ],
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
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatusIndicator(
                'Koneksi IoT',
                Icons.wifi,
                Colors.green,
              ),
              const SizedBox(width: 16),
              _buildStatusIndicator(
                'Database',
                Icons.storage,
                Colors.green,
              ),
              const SizedBox(width: 16),
              _buildStatusIndicator(
                'Sensor',
                Icons.sensors,
                Colors.green,
              ),
              const SizedBox(width: 16),
              _buildStatusIndicator(
                'Aktuator',
                Icons.engineering,
                _autoMode ? Colors.green : Colors.blue,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(String label, IconData icon, Color color) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}