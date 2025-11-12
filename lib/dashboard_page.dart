
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

// Data model for the prediction result
class AIPrediction {
  final PredictionStatus status;
  final String recommendation;
  final int predictedEggs;

  AIPrediction({
    required this.status,
    required this.recommendation,
    required this.predictedEggs,
  });
}

// Enum for the status
enum PredictionStatus {
  healthy,
  danger,
}


class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final DatabaseReference _sensorRef =
      FirebaseDatabase.instance.ref('sensors/latest');
  final _chickenCountController = TextEditingController();
  final _feedAmountController = TextEditingController();
  final _ammoniaController = TextEditingController();
  final _lightIntensityController = TextEditingController();
  final _noiseController = TextEditingController();

  // Variable to store the latest sensor data
  double _latestTemp = 22.0; // Default to optimal value
  double _latestHumidity = 60.0; // Default to optimal value

  AIPrediction? _predictionResult;

  void _calculatePrediction() {
    // 1. Validate all inputs
    final chickenCount = int.tryParse(_chickenCountController.text);
    final feedAmount = double.tryParse(_feedAmountController.text);
    final ammonia = double.tryParse(_ammoniaController.text);
    final lightIntensity = double.tryParse(_lightIntensityController.text);
    final noise = double.tryParse(_noiseController.text);

    if ([chickenCount, feedAmount, ammonia, lightIntensity, noise].contains(null) || chickenCount! <= 0) {
      setState(() {
        _predictionResult = AIPrediction(
          status: PredictionStatus.danger,
          predictedEggs: 0,
          recommendation: "Error: Please ensure all manual input fields are filled with valid numbers and chicken count is greater than 0.",
        );
      });
      return;
    }

    // 2. Prediction Model Logic
    const double dailyFeedPerChicken = 0.125;
    const double peakProductionRate = 0.85;

    final double requiredFeed = chickenCount * dailyFeedPerChicken;
    final double feedFactor = (feedAmount! / requiredFeed).clamp(0.0, 1.0);

    double tempFactor = 1.0;
    if (_latestTemp < 20) {
      tempFactor = 1.0 - ((20 - _latestTemp) / 15);
    } else if (_latestTemp > 25) {
      tempFactor = 1.0 - ((_latestTemp - 25) / 15);
    }

    double humidityFactor = 1.0;
    if (_latestHumidity < 50) {
      humidityFactor = 1.0 - ((50 - _latestHumidity) / 30);
    } else if (_latestHumidity > 70) {
      humidityFactor = 1.0 - ((_latestHumidity - 70) / 30);
    }
    
    double ammoniaFactor = 1.0;
    if (ammonia! > 25) {
       ammoniaFactor = 1.0 - ((ammonia - 25) / 25);
    }

    double lightFactor = 1.0;
    if (lightIntensity! < 10) {
      lightFactor = 1.0 - ((10 - lightIntensity) / 10);
    } else if (lightIntensity > 20) {
      lightFactor = 1.0 - ((lightIntensity - 20) / 40);
    }

    double noiseFactor = 1.0;
    if (noise! > 60) {
      noiseFactor = 1.0 - ((noise - 60) / 40);
    }

    final environmentalFactor = (tempFactor * humidityFactor * ammoniaFactor * lightFactor * noiseFactor).clamp(0.0, 1.0);

    // 3. Final Calculation
    final double maxPotentialEggs = chickenCount * peakProductionRate;
    final double predictedEggs = maxPotentialEggs * feedFactor * environmentalFactor;

    // 4. Generate Status and Recommendations
    List<String> issues = [];
    if (ammonia > 25) {
      issues.add("Ammonia level is critical! Check ventilation and litter immediately.");
    }
    if (_latestTemp > 25) {
      issues.add("Temperature is too high! Increase ventilation and provide adequate water.");
    } else if (_latestTemp < 20) {
      issues.add("Temperature is too low (${_latestTemp.toStringAsFixed(1)}°C). Check heaters.");
    }
    if (_latestHumidity > 70 || _latestHumidity < 50) {
      issues.add("Humidity level is critical! Improve ventilation and check for water leaks.");
    }
    if (lightIntensity < 10) {
      issues.add("Light intensity is insufficient. Add more lighting for optimal production.");
    }
    if (noise > 60) {
      issues.add("Noise level is too high. Reduce noise sources to prevent stress.");
    }
    if (feedFactor < 0.95) {
      issues.add("Feed is below the ideal amount. Increase feed to ~${requiredFeed.toStringAsFixed(1)} kg.");
    }

    PredictionStatus status;
    String recommendation;

    if (issues.isEmpty) {
      status = PredictionStatus.healthy;
      recommendation = "Conditions are optimal. Keep up the good work!";
    } else {
      status = PredictionStatus.danger;
      recommendation = issues.join('\n');
    }

    setState(() {
      _predictionResult = AIPrediction(
        status: status,
        recommendation: recommendation,
        predictedEggs: predictedEggs.round(),
      );
    });
  }


  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prediction Dashboard'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (user != null)
              Text('Welcome, ${user.email}', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 20),
            Text('Real-time Sensor Data', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            StreamBuilder(
              stream: _sensorRef.onValue,
              builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Row(
                    children: [
                      Expanded(
                        child: _buildSensorCard(context, icon: Icons.thermostat, label: 'Temperature', value: '${_latestTemp.toStringAsFixed(1)} °C', color: Colors.orange, isLoading: true),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildSensorCard(context, icon: Icons.water_drop, label: 'Humidity', value: '${_latestHumidity.toStringAsFixed(1)} %', color: Colors.blue, isLoading: true),
                      ),
                    ],
                  );
                }
                
                final data = snapshot.data?.snapshot.value as Map<dynamic, dynamic>? ?? {};
                _latestTemp = (data['temperature'] ?? _latestTemp).toDouble();
                _latestHumidity = (data['humidity'] ?? _latestHumidity).toDouble();

                return Row(
                  children: [
                    Expanded(
                      child: _buildSensorCard(context, icon: Icons.thermostat, label: 'Temperature', value: '${_latestTemp.toStringAsFixed(1)} °C', color: Colors.orange),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildSensorCard(context, icon: Icons.water_drop, label: 'Humidity', value: '${_latestHumidity.toStringAsFixed(1)} %', color: Colors.blue),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 30),
            Text('Manual Input Parameters', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 20),
            Wrap(
              spacing: 16.0,
              runSpacing: 16.0,
              children: [
                _buildInputWidget(controller: _chickenCountController, label: 'Amount of Chicken'),
                _buildInputWidget(controller: _feedAmountController, label: 'Amount of Feeding (kg)'),
                _buildInputWidget(controller: _ammoniaController, label: 'Ammonia (ppm)'),
                _buildInputWidget(controller: _lightIntensityController, label: 'Light Intensity (lux)'),
                _buildInputWidget(controller: _noiseController, label: 'Noise (dB)'),
              ],
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.bar_chart),
                onPressed: _calculatePrediction,
                label: const Text('Calculate Prediction'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            if (_predictionResult != null)
              Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: _buildPredictionCard(_predictionResult!),
              )
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (index) {
          if (index == 1) {
            Navigator.pushNamed(context, '/settings');
          } else if (index == 2) {
            Navigator.pushNamed(context, '/notifications');
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.insights),
            label: 'Prediction',
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
      ),
    );
  }

  Widget _buildSensorCard(BuildContext context, {required IconData icon, required String label, required String value, required Color color, bool isLoading = false}) {
    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label, style: Theme.of(context).textTheme.bodyMedium),
                if(isLoading)
                  const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2.0))
                else
                  Icon(icon, color: color, size: 20),
              ],
            ),
            const SizedBox(height: 8),
            Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildInputWidget({required TextEditingController controller, required String label}) {
    return SizedBox(
      width: 200,
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        ),
      ),
    );
  }

  Widget _buildPredictionCard(AIPrediction result) {
    final bool isHealthy = result.status == PredictionStatus.healthy;
    final Color cardColor = isHealthy ? Colors.green.shade100 : Colors.red.shade100;
    final Color textColor = isHealthy ? Colors.green.shade900 : Colors.red.shade900;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withAlpha(128))
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AI Prediction',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: textColor, fontWeight: FontWeight.bold),
          ),
          const Divider(height: 16),
          _buildInfoRow(
            icon: null,
            text: 'Status: ${isHealthy ? 'Healthy' : 'Danger'}' ,
            color: textColor,
            isBold: true,
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            icon: Icons.lightbulb_outline,
            text: 'Recommendation: ${result.recommendation}',
            color: textColor,
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            icon: Icons.egg_outlined,
            text: 'Predicted Daily Egg Production: ${result.predictedEggs}',
            color: textColor,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({IconData? icon, required String text, required Color color, bool isBold = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: 15,
            ),
          ),
        ),
      ],
    );
  }
}
