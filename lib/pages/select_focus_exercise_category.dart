import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'show_video_page.dart';
import 'view_exercise_summary_page.dart';
import '../models/detection_result.dart';
import '../state/app_state.dart';
import '../models/exercise_type.dart';

class SelectFocusExerciseCategoryPage extends StatefulWidget {
  final String videoPath;
  final List<DetectionResult> detectionResults;
  final String currentUser;

  const SelectFocusExerciseCategoryPage({
    super.key,
    required this.videoPath,
    required this.detectionResults,
    required this.currentUser,
  });

  @override
  State<SelectFocusExerciseCategoryPage> createState() => _SelectFocusExerciseCategoryPageState();
}

class _SelectFocusExerciseCategoryPageState extends State<SelectFocusExerciseCategoryPage> {
  int selectedThresholdTime = 45;
  final Color _primaryColor = const Color(0xFF00BCD4);

  void _onDetectionTypeSelected(String type) {
    _showTimeSelectionDialog(type);
  }

  void _showTimeSelectionDialog(String type) {
    int tempSelected = selectedThresholdTime;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => StatefulBuilder(
        builder: (sbContext, setDialog) => AlertDialog(
          backgroundColor: const Color(0xFF0F172A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            "Select Focus Duration",
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Select duration (seconds) to classify Focused/Unfocused:",
                style: TextStyle(fontSize: 14, color: Colors.white70),
              ),
              const SizedBox(height: 8),
              DropdownButton<int>(
                value: tempSelected,
                dropdownColor: const Color(0xFF0F172A),
                style: const TextStyle(color: Colors.white),
                isExpanded: true,
                items: List.generate(91, (index) => index)
                    .where((i) => i % 5 == 0)
                    .map(
                      (e) => DropdownMenuItem(
                        value: e,
                        child: Text("$e seconds"),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) setDialog(() => tempSelected = v);
                },
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                setState(() {
                  selectedThresholdTime = tempSelected;
                });
                Navigator.pop(dialogContext);
                _goToShowVideoPage(type);
              },
              child: const Text("Confirm"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                "Cancel",
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _goToShowVideoPage(String type) {
    if (!mounted) return;

    final exerciseType = Provider.of<AppState>(context, listen: false)
            .selectedExercise ??
        ExerciseType.CatCow;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ShowVideoPage(
          videoPath: widget.videoPath,
          selectedType: type,
          detectionResults: widget.detectionResults,
          selectedInattentiveTime: selectedThresholdTime,
          exerciseType: exerciseType,
          currentUser: widget.currentUser,
        ),
      ),
    );
  }

  void _goToExerciseSummary() {
    if (!mounted) return;

    final exerciseType = Provider.of<AppState>(context, listen: false)
            .selectedExercise ??
        ExerciseType.CatCow;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ViewExerciseSummaryPage(
          results: widget.detectionResults,
          exerciseType: exerciseType,
          currentUser: widget.currentUser,
        ),
      ),
    );
  }

  Widget _buildDetectionButton(String title, Color color) {
    return InkWell(
      onTap: () => _onDetectionTypeSelected(title),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text(
          "Select Focus Category Page",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: _primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Image.asset(
                'assets/images/image.jpg',
                width: double.infinity,
                height: 180,
                fit: BoxFit.cover,
              ),
              const SizedBox(height: 24),
              const Text(
                "Please choose a focus category for exercise",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              _buildDetectionButton("Focus Pose", const Color(0xFF00BCD4)),
              _buildDetectionButton("Unfocus Pose", const Color(0xFFFF5252)),
              const SizedBox(height: 16),
              const Text(
                "OR",
                style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF835EC8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  minimumSize: const Size.fromHeight(50),
                ),
                onPressed: _goToExerciseSummary,
                child: const Text(
                  "View Exercise Summary",
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
