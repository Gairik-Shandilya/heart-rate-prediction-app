import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PastMonthHeartRatePage extends StatefulWidget {
  @override
  _PastMonthHeartRatePageState createState() => _PastMonthHeartRatePageState();
}

class _PastMonthHeartRatePageState extends State<PastMonthHeartRatePage> {
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
      final startOfMonth = today.subtract(Duration(days: 30));
      final endOfMonth = today;

      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('Heart Rate')
          .where('timestamp', isGreaterThanOrEqualTo: startOfMonth)
          .where('timestamp', isLessThan: endOfMonth)
          .get();

      Map<DateTime, List<double>> dailyBPM = {};

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final timestamp = (data['timestamp'] as Timestamp).toDate();
        final bpm = data['average_bpm'] as double;

        // Group by day
        final dateKey = DateTime(timestamp.year, timestamp.month, timestamp.day);
        if (!dailyBPM.containsKey(dateKey)) {
          dailyBPM[dateKey] = [];
        }
        dailyBPM[dateKey]!.add(bpm);
      }

      // Calculate averages
      for (var entry in dailyBPM.entries) {
        final averageBPM = entry.value.reduce((a, b) => a + b) / entry.value.length;
        _heartRateData.add(FlSpot(entry.key.millisecondsSinceEpoch.toDouble(), averageBPM));
      }

      // Sort by date
      _heartRateData.sort((a, b) => a.x.compareTo(b.x));
      _isLoading = false;
      setState(() {});
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
        title: Text('Past 30 Days Heart Rate'),
        backgroundColor: Colors.redAccent,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Expanded(
                    child: Container(
                      height: 300, // Adjust height for better fit
                      child: LineChart(
                        LineChartData(
                          gridData: FlGridData(show: true, horizontalInterval: 15),
                          titlesData: FlTitlesData(
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 40,
                                getTitlesWidget: (value, meta) {
                                  final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                                  return SideTitleWidget(
                                    axisSide: meta.axisSide,
                                    space: 8,
                                    child: Text(
                                      '${date.day}/${date.month}',
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
                          minX: (DateTime.now().subtract(Duration(days: 30))).millisecondsSinceEpoch.toDouble(),
                          maxX: DateTime.now().millisecondsSinceEpoch.toDouble(),
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
                                  final date = DateTime.fromMillisecondsSinceEpoch(spot.x.toInt());
                                  return LineTooltipItem(
                                    'Date: ${date.day}/${date.month}\nBPM: ${spot.y.toStringAsFixed(1)}',
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
