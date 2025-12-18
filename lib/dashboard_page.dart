import 'dart:math';

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

  // Variable to store the latest sensor data for calculation
  double _latestTemp = 22.0;
  double _latestHumidity = 60.0;
  
  @override
  void dispose() {
    _chickenCountController.dispose();
    _feedAmountController.dispose();
    _ammoniaController.dispose();
    _lightIntensityController.dispose();
    _noiseController.dispose();
    super.dispose();
  }

  void _showPredictionDialog(AIPrediction result) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AnimatedPredictionDialog(result: result);
      },
    );
  }

  void _calculatePrediction() {
    // 1. Validate all inputs
    final chickenCount = int.tryParse(_chickenCountController.text);
    final feedAmount = double.tryParse(_feedAmountController.text);
    final ammonia = double.tryParse(_ammoniaController.text);
    final lightIntensity = double.tryParse(_lightIntensityController.text);
    final noise = double.tryParse(_noiseController.text);

    if ([chickenCount, feedAmount, ammonia, lightIntensity, noise].contains(null) || chickenCount! <= 0) {
      _showPredictionDialog(AIPrediction(
        status: PredictionStatus.danger,
        predictedEggs: 0,
        recommendation: "Error: Please ensure all manual input fields are filled with valid numbers and chicken count is greater than 0.",
      ));
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

    _showPredictionDialog(AIPrediction(
      status: status,
      recommendation: recommendation,
      predictedEggs: predictedEggs.round(),
    ));
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
              if (!mounted) return;
              Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
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
                // 1. First, check for explicit errors from the stream
                if (snapshot.hasError) {
                  print('Firebase Stream Error: ${snapshot.error}'); // Log the error!
                  return Row(
                    children: [
                      Expanded(
                        child: _buildSensorCard(context, icon: Icons.error, label: 'Temperature', value: 'Error', color: Colors.red, errorMessage: 'Connection Failed'),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildSensorCard(context, icon: Icons.error, label: 'Humidity', value: 'Error', color: Colors.red, errorMessage: 'Connection Failed'),
                      ),
                    ],
                  );
                }

                // 2. Handle the connection state
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Row(
                    children: [
                      Expanded(
                        child: _buildSensorCard(context, icon: Icons.thermostat, label: 'Temperature', value: 'Loading...', color: Colors.orange, isLoading: true),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildSensorCard(context, icon: Icons.water_drop, label: 'Humidity', value: 'Loading...', color: Colors.blue, isLoading: true),
                      ),
                    ],
                  );
                }

                // 3. Check if we have data and if the data is not null
                if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
                  return Row(
                    children: [
                      Expanded(
                        child: _buildSensorCard(context, icon: Icons.info_outline, label: 'Temperature', value: 'No Data', color: Colors.grey),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildSensorCard(context, icon: Icons.info_outline, label: 'Humidity', value: 'No Data', color: Colors.grey),
                      ),
                    ],
                  );
                }

                // 4. Safely process the data
                final data = snapshot.data!.snapshot.value;
                if (data is Map) {
                  final Map<Object?, Object?> dataMap = data;
                  
                  final tempValue = dataMap['temperature'];
                  final humValue = dataMap['humidity'];

                  _latestTemp = tempValue is num ? tempValue.toDouble() : 0.0;
                  _latestHumidity = humValue is num ? humValue.toDouble() : 0.0;

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
                } else {
                  return Row(
                     children: [
                      Expanded(
                        child: _buildSensorCard(context, icon: Icons.warning, label: 'Temperature', value: 'Format Error', color: Colors.amber, errorMessage: 'Unexpected data format'),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildSensorCard(context, icon: Icons.warning, label: 'Humidity', value: 'Format Error', color: Colors.amber, errorMessage: 'Unexpected data format'),
                      ),
                    ],
                  );
                }
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
          ],
        ),
      ),
    );
  }

  Widget _buildSensorCard(BuildContext context, {required IconData icon, required String label, required String value, required Color color, bool isLoading = false, String? errorMessage}) {
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
            if (errorMessage != null) ...[
              const SizedBox(height: 4),
              Text(errorMessage, style: TextStyle(color: color, fontSize: 12)),
            ]
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
}

class AnimatedPredictionDialog extends StatefulWidget {
  final AIPrediction result;

  const AnimatedPredictionDialog({super.key, required this.result});

  @override
  State<AnimatedPredictionDialog> createState() => _AnimatedPredictionDialogState();
}

class _AnimatedPredictionDialogState extends State<AnimatedPredictionDialog> with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    final bool isHealthy = widget.result.status == PredictionStatus.healthy;

    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: isHealthy ? 1200 : 500),
    );

    if (isHealthy) {
      _animation = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
      _controller.forward();
    } else {
      _animation = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      );
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isHealthy = widget.result.status == PredictionStatus.healthy;
    final Color dialogColor = isHealthy ? Colors.green.shade50 : Colors.red.shade50;
    final Color titleColor = isHealthy ? Colors.green.shade800 : Colors.red.shade800;

    return AlertDialog(
      backgroundColor: dialogColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      contentPadding: const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 0),
      title: Center(
        child: Text(
          isHealthy ? 'Prediction: Healthy!' : 'Prediction: Danger!',
          style: TextStyle(
            color: titleColor,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 150,
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  if (isHealthy) {
                    return Transform.scale(
                      scale: _animation.value,
                      child: child,
                    );
                  } else {
                    return Transform.translate(
                      offset: Offset(sin(_animation.value * pi * 4) * 8, 0),
                      child: child,
                    );
                  }
                },
                child: Icon(
                  isHealthy ? Icons.check_circle_outline : Icons.warning_amber_rounded,
                  color: titleColor,
                  size: 100,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildDialogInfoRow(
              icon: Icons.lightbulb_outline,
              label: 'Recommendation',
              value: widget.result.recommendation,
              color: titleColor,
            ),
            const SizedBox(height: 12),
            _buildDialogInfoRow(
              icon: Icons.egg_outlined,
              label: 'Predicted Daily Egg Production',
              value: '${widget.result.predictedEggs}',
              color: titleColor,
            ),
          ],
        ),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: <Widget>[
        TextButton(
          child: const Text('DISMISS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }

  Widget _buildDialogInfoRow({required IconData icon, required String label, required String value, required Color color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: color.withOpacity(0.8),
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}