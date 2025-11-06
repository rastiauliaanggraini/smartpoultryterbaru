
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:myapp/login_page.dart';
import 'package:myapp/notifications_page.dart';
import 'package:myapp/settings_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;
  
  // Realtime Database reference
  final DatabaseReference _sensorRef = FirebaseDatabase.instance.ref('sensor_data/dht22');

  // State for sensor data will be managed by StreamBuilder, 
  // but we need local copies for the prediction logic.
  double _currentTemperature = 25.0;
  double _currentHumidity = 60.0;

  String _predictionResult = '';
  String _predictionStatus = '';
  List<String> _recommendations = [];

  final _chickenController = TextEditingController();
  final _feedController = TextEditingController();
  final _ammoniaController = TextEditingController();
  final _lightController = TextEditingController();
  final _noiseController = TextEditingController();

  @override
  void dispose() {
    _chickenController.dispose();
    _feedController.dispose();
    _ammoniaController.dispose();
    _lightController.dispose();
    _noiseController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (index == 1) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsPage()));
    } else if (index == 2) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationsPage()));
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  void _calculatePrediction() {
    final chickens = int.tryParse(_chickenController.text) ?? 0;
    final feed = double.tryParse(_feedController.text) ?? 0.0;
    final ammonia = double.tryParse(_ammoniaController.text) ?? 0.0;
    final light = double.tryParse(_lightController.text) ?? 0.0;
    final noise = double.tryParse(_noiseController.text) ?? 0.0;
    
    // Use the latest data from Firebase
    final temp = _currentTemperature;
    final humidity = _currentHumidity;

    if (chickens <= 0 || chickens > 10000) {
        setState(() {
            _predictionResult = 'Jumlah ayam tidak valid (100-10,000).';
            _predictionStatus = '';
            _recommendations = [];
        });
        return;
    }

    double baseProduction = chickens * 0.85;
    double predictedEggs = baseProduction;
    bool isDanger = false;
    List<String> recommendations = [];

    final feedProvided = feed * 1000;
    final requiredFeed = chickens * 120; 
    
    double feedEffect = 1.0;
    if (feedProvided < requiredFeed) {
        isDanger = true;
        final idealFeedMin = (chickens * 100) / 1000;
        final idealFeedMax = (chickens * 150) / 1000;
        recommendations.add('Jumlah pakan tidak sesuai! Idealnya ${idealFeedMin.toStringAsFixed(1)}-${idealFeedMax.toStringAsFixed(1)} kg.');
        feedEffect = feedProvided / requiredFeed;
    }
    predictedEggs *= feedEffect;

    if (ammonia > 25) {
        predictedEggs *= 0.9;
        isDanger = true;
        recommendations.add('Kadar amonia berbahaya, periksa ventilasi dan litter segera.');
    }

    if (noise > 60) {
        predictedEggs *= 0.95;
        isDanger = true;
        recommendations.add('Kebisingan terlalu tinggi, kurangi sumber kebisingan untuk mencegah stress.');
    }

    if (light < 10 || light > 20) {
        predictedEggs *= 0.98;
        recommendations.add('Intensitas cahaya tidak optimal (10-20 lux). Atur pencahayaan.');
    }

    if (temp > 25) {
        predictedEggs *= 0.97;
        isDanger = true;
        recommendations.add('Suhu terlalu panas, tingkatkan ventilasi dan sediakan air cukup.');
    } else if (temp < 20) {
        predictedEggs *= 0.97;
        isDanger = true;
        recommendations.add('Suhu terlalu dingin! Aktifkan sistem pemanas.');
    }

    if (humidity > 70 || humidity < 50) {
        predictedEggs *= 0.98;
        isDanger = true;
        recommendations.add('Kelembaban kritis, perbaiki ventilasi dan cek kebocoran air.');
    }

    setState(() {
        _predictionResult = '${max(0, predictedEggs.round())} Telur';
        _predictionStatus = isDanger ? 'Danger' : 'Healthy';
        if (recommendations.isEmpty && !isDanger) {
            _recommendations = ['Kondisi optimal. Pertahankan manajemen saat ini.'];
        } else {
            _recommendations = recommendations;
        }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Poultry Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome, ${user?.email ?? 'User'}',
              style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24.0),
            Text(
              'Real-time Sensor Data',
              style: textTheme.titleLarge,
            ),
            const SizedBox(height: 16.0),
            
            // --- StreamBuilder for Real-time Data ---
            StreamBuilder(
              stream: _sensorRef.onValue,
              builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.hasError || snapshot.data!.snapshot.value == null) {
                  // Update local state for prediction logic with default values
                  _currentTemperature = 25.0;
                  _currentHumidity = 60.0;
                  return const Text('No sensor data available or error.');
                }

                // Data is available, let's parse it
                final data = Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);
                final temp = data['temperature'] ?? 25.0;
                final hum = data['humidity'] ?? 60.0;

                // Update local state variables for prediction logic
                _currentTemperature = (temp is int) ? temp.toDouble() : temp;
                _currentHumidity = (hum is int) ? hum.toDouble() : hum;

                return Row(
                  children: [
                    Expanded(
                      child: SensorCard(
                        icon: Icons.thermostat,
                        label: 'Temperature',
                        value: '${_currentTemperature.toStringAsFixed(1)} °C',
                        color: Colors.redAccent,
                      ),
                    ),
                    const SizedBox(width: 16.0),
                    Expanded(
                      child: SensorCard(
                        icon: Icons.water_drop,
                        label: 'Humidity',
                        value: '${_currentHumidity.toStringAsFixed(1)} %',
                        color: Colors.blueAccent,
                      ),
                    ),
                  ],
                );
              },
            ),
            // --- End of StreamBuilder ---

            const SizedBox(height: 24.0),
            Text(
              'Manual Input Parameters',
              style: textTheme.titleLarge,
            ),
            const SizedBox(height: 16.0),
            ManualInputForm(
              chickenController: _chickenController,
              feedController: _feedController,
              ammoniaController: _ammoniaController,
              lightController: _lightController,
              noiseController: _noiseController,
            ),
            const SizedBox(height: 24.0),
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                  textStyle: textTheme.titleMedium,
                ),
                onPressed: _calculatePrediction,
                child: const Text('Calculate Prediction'),
              ),
            ),
            if (_predictionResult.isNotEmpty)
              PredictionResultCard(
                result: _predictionResult,
                status: _predictionStatus,
                recommendations: _recommendations,
              ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Notifications',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}

class SensorCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const SensorCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.color = Colors.grey,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 8.0),
            Text(label, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 4.0),
            Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class ManualInputForm extends StatelessWidget {
  final TextEditingController chickenController;
  final TextEditingController feedController;
  final TextEditingController ammoniaController;
  final TextEditingController lightController;
  final TextEditingController noiseController;

  const ManualInputForm({
    super.key,
    required this.chickenController,
    required this.feedController,
    required this.ammoniaController,
    required this.lightController,
    required this.noiseController,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildTextField(label: 'Jumlah Ayam (100-10,000)', controller: chickenController),
            const SizedBox(height: 16),
            _buildTextField(label: 'Jumlah Pakan (kg)', controller: feedController),
            const SizedBox(height: 16),
            _buildTextField(label: 'Amonia (ppm)', controller: ammoniaController),
            const SizedBox(height: 16),
            _buildTextField(label: 'Intensitas Cahaya (lux)', controller: lightController),
            const SizedBox(height: 16),
            _buildTextField(label: 'Kebisingan (dB)', controller: noiseController),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({required String label, required TextEditingController controller}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Colors.grey[200]?.withAlpha(128),
      ),
      keyboardType: TextInputType.number,
    );
  }
}

class PredictionResultCard extends StatelessWidget {
  final String result;
  final String status;
  final List<String> recommendations;

  const PredictionResultCard({
    super.key,
    required this.result,
    required this.status,
    required this.recommendations,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isDanger = status == 'Danger';
    final statusColor = isDanger ? Colors.redAccent : Colors.green;
    final statusIcon = isDanger ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded;

    return Card(
      margin: const EdgeInsets.only(top: 24.0),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hasil Analisis', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const Divider(thickness: 1, height: 24),

            ListTile(
              leading: const Icon(Icons.egg_outlined, size: 40),
              title: Text(result, style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
              subtitle: Text('Prediksi Produksi Telur', style: textTheme.bodyLarge),
            ),
            const SizedBox(height: 16),

            ListTile(
              leading: Icon(statusIcon, size: 40, color: statusColor),
              title: Text(status, style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: statusColor)),
              subtitle: Text('Status Kandang', style: textTheme.bodyLarge),
            ),
            const SizedBox(height: 16),

            Text('Rekomendasi:', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...recommendations.map((rec) => Padding(
              padding: const EdgeInsets.only(left: 16.0, bottom: 4.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Expanded(child: Text(rec, style: textTheme.bodyLarge)),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}
