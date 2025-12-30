import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/detection_result.dart';
import '../models/exercise_summary.dart';
import '../models/exercise_type.dart';

class ViewExerciseSummaryPage extends StatelessWidget {
  final List<DetectionResult> results;
  final ExerciseType exerciseType;
  final String currentUser;

  const ViewExerciseSummaryPage({
    super.key,
    required this.results,
    required this.exerciseType,
    required this.currentUser,
  });

  double _safeDivide(int a, int b) => b == 0 ? 0.0 : a / b;

  String _formatDate(String isoString) {
    try {
      final dt = DateTime.parse(isoString).toLocal();
      return DateFormat('yyyy-MM-dd HH:mm').format(dt);
    } catch (_) {
      return isoString;
    }
  }

  String _computeExerciseEfficiency(double focusPercent) {
    if (focusPercent >= 0.7) return "High";
    if (focusPercent >= 0.4) return "Moderate";
    return "Low";
  }

  String _computePostureSafety(double focusPercent) {
    if (focusPercent >= 0.7) return "Mostly Stable";
    if (focusPercent >= 0.4) return "Needs Attention";
    return "Unstable";
  }

  String _computeInjuryRisk(double focusPercent) {
    if (focusPercent >= 0.7) return "Low";
    if (focusPercent >= 0.4) return "Moderate";
    return "High";
  }

  String _computeOverallFeedback(double focusPercent, double unfocusPercent) {
    return "Overall Feedback: Please pay more focus!";
  }

  @override
  Widget build(BuildContext context) {
    final focusResults = results.where((r) => r.isFocusPose).toList();
    final unfocusResults = results.where((r) => r.isUnfocusPose).toList();

    int focusSeconds = focusResults.length;
    int unfocusSeconds = unfocusResults.length;
    int totalSeconds = focusSeconds + unfocusSeconds;

    if (results.isEmpty || totalSeconds == 0) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        appBar: AppBar(
          title: const Text(
            'View Exercise Summary Page',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
          ),
          backgroundColor: const Color(0xFF00BCD4),
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.info_outline, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              const Text(
                "Exercise Summary is unavailable",
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    double focusPercent = _safeDivide(focusSeconds, totalSeconds);
    double unfocusPercent = _safeDivide(unfocusSeconds, totalSeconds);

    Widget buildButton({
      required Widget child,
      required VoidCallback onPressed,
      required Color backgroundColor,
    }) {
      return SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: DefaultTextStyle(
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              child: child,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text(
          'View Exercise Summary Page',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF00BCD4),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${exerciseType.displayName} Summary',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Total Video Duration: $totalSeconds sec',
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Summary Time: ${_formatDate(DateTime.now().toIso8601String())}',
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: PieChart(
                      PieChartData(
                        sections: [
                          PieChartSectionData(
                            value: focusPercent,
                            color: Colors.green,
                            title: 'Focus\n${(focusPercent * 100).toStringAsFixed(1)}%',
                            radius: 60,
                            titleStyle: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          PieChartSectionData(
                            value: unfocusPercent,
                            color: Colors.red,
                            title: 'Unfocus\n${(unfocusPercent * 100).toStringAsFixed(1)}%',
                            radius: 60,
                            titleStyle: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                        sectionsSpace: 4,
                        centerSpaceRadius: 40,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  Text(
                    'Focus Pose: $focusSeconds sec (${(focusPercent * 100).toStringAsFixed(1)}%)',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Unfocus Pose: $unfocusSeconds sec (${(unfocusPercent * 100).toStringAsFixed(1)}%)',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Exercise Efficiency: ${_computeExerciseEfficiency(focusPercent)}',
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                  Text(
                    'Posture Safety: ${_computePostureSafety(focusPercent)}',
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                  Text(
                    'Potential Injury Risk: ${_computeInjuryRisk(focusPercent)}',
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _computeOverallFeedback(focusPercent, unfocusPercent),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            buildButton(
              child: const Text('Save Summary'),
              backgroundColor: Colors.teal,
              onPressed: () async {
                final controller = TextEditingController();

                final result = await showDialog<String>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Enter Exercise Session Summary Name'),
                    content: TextField(
                      controller: controller,
                      decoration: const InputDecoration(
                        hintText: 'e.g., Home Exercise Session',
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(null),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(controller.text.trim()),
                        child: const Text('Save'),
                      ),
                    ],
                  ),
                );

                if (result == null || result.isEmpty) return;

                final summary = ExerciseSummary(
                  name: result,
                  exerciseType: exerciseType.name,
                  focusSeconds: focusSeconds,
                  unfocusSeconds: unfocusSeconds,
                  totalSeconds: totalSeconds,
                  focusPercent: focusPercent,
                  unfocusPercent: unfocusPercent,
                  timestamp: DateTime.now().toIso8601String(),
                  username: currentUser,
                );

                await ExerciseSummaryDatabase.instance.insertSummary(summary);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Summary "$result" Saved Successfully!'),
                    backgroundColor: const Color.fromARGB(255, 114, 186, 116),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            buildButton(
              child: const Text('Back to Detection Selection'),
              backgroundColor: const Color(0xFF1565C0), 
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(height: 12),
            buildButton(
              child: const Text('Back to Home'),
              backgroundColor: const Color.fromARGB(255, 131, 98, 208),
              onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}