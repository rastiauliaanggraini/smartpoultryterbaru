
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  // 1. Buat referensi ke node 'sensors/latest' di Firebase Realtime Database
  final DatabaseReference _sensorRef =
      FirebaseDatabase.instance.ref('sensors/latest');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Sensor Dashboard'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        // 2. Gunakan StreamBuilder untuk mendengarkan perubahan data
        child: StreamBuilder(
          stream: _sensorRef.onValue, // Langganan ke perubahan data
          builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
            // 3. Handle berbagai status koneksi
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.hasError || snapshot.data?.snapshot.value == null) {
              return const Center(
                child: Text(
                  'Menunggu data sensor pertama masuk...\nPastikan server Django Anda berjalan.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
              );
            }

            // 4. Jika data tersedia, proses dan tampilkan
            // Data dari Firebase datang sebagai Map<dynamic, dynamic>
            final data = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;

            // Ekstrak setiap nilai sensor
            final double temperature = (data['temperature'] ?? 0.0).toDouble();
            final double humidity = (data['humidity'] ?? 0.0).toDouble();
            final double noise = (data['noise'] ?? 0.0).toDouble();
            final double light = (data['light'] ?? 0.0).toDouble();
            final String lastUpdated = data['last_updated'] ?? 'N/A';

            // 5. Tampilkan data dalam layout yang rapi
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Last Updated: $lastUpdated',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    children: [
                      _buildSensorCard(
                        context,
                        icon: Icons.thermostat,
                        label: 'Temperature',
                        value: '${temperature.toStringAsFixed(1)} °C',
                        color: Colors.redAccent,
                      ),
                      _buildSensorCard(
                        context,
                        icon: Icons.water_drop,
                        label: 'Humidity',
                        value: '${humidity.toStringAsFixed(1)} %',
                        color: Colors.blueAccent,
                      ),
                      _buildSensorCard(
                        context,
                        icon: Icons.volume_up,
                        label: 'Noise',
                        value: '${noise.toStringAsFixed(1)} dB',
                        color: Colors.orangeAccent,
                      ),
                      _buildSensorCard(
                        context,
                        icon: Icons.lightbulb,
                        label: 'Light',
                        value: '${light.toStringAsFixed(1)} lux',
                        color: Colors.yellow.shade700,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // Widget helper untuk membuat kartu sensor yang bisa digunakan kembali
  Widget _buildSensorCard(BuildContext context, {required IconData icon, required String label, required String value, required Color color}) {
    return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 10),
            Text(
              label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 5),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: color, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
