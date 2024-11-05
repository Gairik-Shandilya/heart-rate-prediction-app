import 'package:flutter/material.dart';

class HeartHealth extends StatefulWidget {
  @override
  _HeartHealthState createState() => _HeartHealthState();
}

class _HeartHealthState extends State<HeartHealth> {
  String _heartRate = 'Unknown'; // Initial heart rate value
  bool _isLoading = false; // Loading state

  // Method to simulate fetching heart rate data
  Future<void> _fetchHeartRate() async {
    setState(() {
      _isLoading = true; // Start loading
    });

    // Simulate a network call with a delay
    await Future.delayed(Duration(seconds: 2));

    // TODO: Replace with actual fetching logic from the backend
    // For example, you can call an API or process data
    setState(() {
      _heartRate = '75 bpm'; // Simulated heart rate
      _isLoading = false; // Stop loading
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Monitor Your Heart Health'),
        backgroundColor: Colors.red, // App bar color
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Current Heart Rate:',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            Text(
              _isLoading ? 'Fetching...' : _heartRate,
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.redAccent,
              ),
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: _fetchHeartRate, // Fetch heart rate on press
              child: Text('Get Heart Rate'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
                backgroundColor: Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
