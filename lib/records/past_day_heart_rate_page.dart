import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PastDayHeartRatePage extends StatefulWidget {
  @override
  _PastDayHeartRatePageState createState() => _PastDayHeartRatePageState();
}

class _PastDayHeartRatePageState extends State<PastDayHeartRatePage> {
  List<FlSpot> _heartRateData = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchHeartRateData();
  }

  Future<void> _fetchHeartRateData() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = DateTime(today.year, today.month, today.day + 1);

      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('Heart Rate')
          .where('timestamp', isGreaterThanOrEqualTo: startOfDay)
          .where('timestamp', isLessThan: endOfDay)
          .orderBy('timestamp')
          .get();

      setState(() {
        for (var doc in snapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final timestamp = (data['timestamp'] as Timestamp).toDate();
          final bpm = data['average_bpm'] as double;

          // Add the FlSpot for the graph
          _heartRateData.add(FlSpot(
            timestamp.hour.toDouble() + (timestamp.minute / 60), // Hour in decimal
            bpm,
          ));
        }
        _isLoading = false;
      });
    }
  }

  double get averageHeartRate {
    if (_heartRateData.isEmpty) return 0.0;
    double totalBPM = _heartRateData.fold(0, (sum, spot) => sum + spot.y);
    return totalBPM / _heartRateData.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Past Day Heart Rate'),
        backgroundColor: Colors.redAccent,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
              child: Column(
                children: [
                  Expanded(
                    child: LineChart(
                      LineChartData(
                        gridData: FlGridData(show: true, horizontalInterval: 15),
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              getTitlesWidget: (value, meta) {
                                final hour = value.toInt();
                                final minute = ((value - hour) * 60).toInt(); // Calculate minutes
                                return SideTitleWidget(
                                  axisSide: meta.axisSide,
                                  space: 8,
                                  child: Text(
                                    '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                );
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              getTitlesWidget: (value, meta) {
                                return SideTitleWidget(
                                  axisSide: meta.axisSide,
                                  space: 8,
                                  child: Text('${value.toInt()} bpm', style: TextStyle(fontSize: 12)),
                                );
                              },
                            ),
                          ),
                          topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        borderData: FlBorderData(
                          show: true,
                          border: Border.all(color: Colors.black26, width: 1),
                        ),
                        minX: 0,
                        maxX: 24, // Representing the full 24 hours
                        minY: 0,
                        maxY: 150,
                        lineBarsData: [
                          LineChartBarData(
                            spots: _heartRateData,
                            isCurved: true,
                            color: Colors.red,
                            dotData: FlDotData(show: true),
                            belowBarData: BarAreaData(show: false),
                          ),
                        ],
                        lineTouchData: LineTouchData(
                          touchTooltipData: LineTouchTooltipData(
                            tooltipBgColor: Colors.redAccent,
                            getTooltipItems: (List<LineBarSpot> touchedSpots) {
                              return touchedSpots.map((spot) {
                                final hour = spot.x.toInt();
                                final minute = ((spot.x - hour) * 60).toInt(); // Calculate minutes
                                return LineTooltipItem(
                                  'Time: ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}\nBPM: ${spot.y.toStringAsFixed(1)}',
                                  TextStyle(color: Colors.white),
                                );
                              }).toList();
                            },
                          ),
                          handleBuiltInTouches: true,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Average Heart Rate: ${averageHeartRate.toStringAsFixed(1)} bpm',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                ],
              ),
            ),
    );
  }
}
