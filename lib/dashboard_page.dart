
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  Timer? _timer;
  double _temperature = 25.0;
  double _humidity = 60.0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      setState(() {
        _temperature += 0.1;
        _humidity -= 0.2;
        if (_temperature > 30) _temperature = 25;
        if (_humidity < 50) _humidity = 60;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
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

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
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
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24.0),
            Text(
              'Real-time Sensor Data',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16.0),
            Row(
              children: [
                Expanded(
                  child: SensorCard(
                    icon: Icons.thermostat,
                    label: 'Temperature',
                    value: '${_temperature.toStringAsFixed(1)} °C',
                  ),
                ),
                const SizedBox(width: 16.0),
                Expanded(
                  child: SensorCard(
                    icon: Icons.water_drop,
                    label: 'Humidity',
                    value: '${_humidity.toStringAsFixed(1)} %',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24.0),
            Text(
              'Manual Input Parameters',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16.0),
            const ManualInputGrid(),
            const SizedBox(height: 24.0),
            Center(
              child: ElevatedButton(
                onPressed: () {},
                child: const Text('Calculate Prediction'),
              ),
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

  const SensorCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, size: 40, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8.0),
            Text(label, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 4.0),
            Text(value, style: Theme.of(context).textTheme.headlineSmall),
          ],
        ),
      ),
    );
  }
}

class ManualInputGrid extends StatelessWidget {
  const ManualInputGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16.0,
      mainAxisSpacing: 16.0,
      childAspectRatio: 2.5,
      children: const [
        InputChip(label: 'Amount of Chicken', initialValue: '100'),
        InputChip(label: 'Ammonia (ppm)', initialValue: '20'),
        InputChip(label: 'Day', initialValue: '30'),
        InputChip(label: 'Average Weight (gr)', initialValue: '1500'),
        InputChip(label: 'Feed Consumption (gr)', initialValue: '120'),
        InputChip(label: 'Water Consumption (L)', initialValue: '250'),
      ],
    );
  }
}

class InputChip extends StatelessWidget {
  final String label;
  final String initialValue;

  const InputChip({
    super.key,
    required this.label,
    required this.initialValue,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: initialValue,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      keyboardType: TextInputType.number,
    );
  }
}
