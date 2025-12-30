import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import '../models/detection_result.dart';
import 'select_focus_exercise_category.dart';

class PoseDetectionPunchPage extends StatefulWidget {
  final String videoPath;
  final int videoDurationInSeconds;
  final String currentUser;

  const PoseDetectionPunchPage({
    super.key,
    required this.videoPath,
    required this.videoDurationInSeconds,
    required this.currentUser,
  });

  @override
  State<PoseDetectionPunchPage> createState() =>
      _PoseDetectionPunchPageState();
}

class _PoseDetectionPunchPageState extends State<PoseDetectionPunchPage> {
  double _progress = 0.0;
  final Color _primaryColor = const Color(0xFF00BCD4);
  final List<DetectionResult> _detectionResults = [];
  late PoseDetector _poseDetector;

  @override
  void initState() {
    super.initState();
    _poseDetector = PoseDetector(options: PoseDetectorOptions());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _analyzeVideo();
    });
  }

  @override
  void dispose() {
    _poseDetector.close();
    super.dispose();
  }

  Future<void> _analyzeVideo() async {
    const int fps = 4;

    for (int sec = 0; sec < widget.videoDurationInSeconds; sec++) {
      int punchCount = 0;

      for (int f = 0; f < fps; f++) {
        final thumb = await VideoThumbnail.thumbnailData(
          video: widget.videoPath,
          imageFormat: ImageFormat.JPEG,
          timeMs: sec * 1000 + (f * 1000 / fps).round(),
          quality: 75,
        );
        if (thumb == null) continue;

        final tempFile =
            File('${Directory.systemTemp.path}/frame_${sec}_$f.jpg');
        await tempFile.writeAsBytes(thumb);

        final inputImage = InputImage.fromFile(tempFile);
        final poses = await _poseDetector.processImage(inputImage);

        if (poses.isNotEmpty) {
          final pose = poses.first;

          final ls = pose.landmarks[PoseLandmarkType.leftShoulder];
          final rs = pose.landmarks[PoseLandmarkType.rightShoulder];
          final lw = pose.landmarks[PoseLandmarkType.leftWrist];
          final rw = pose.landmarks[PoseLandmarkType.rightWrist];

          if (ls != null && rs != null && lw != null && rw != null) {
            final shoulderX = (ls.x + rs.x) / 2;
            final shoulderY = (ls.y + rs.y) / 2;

            final leftPunchHorizontal = (lw.x - shoulderX).abs() > 20;
            final leftPunchVertical = (lw.y - shoulderY).abs() < 80;
            final isLeftPunch = leftPunchHorizontal && leftPunchVertical;

            final rightPunchHorizontal = (rw.x - shoulderX).abs() > 20;
            final rightPunchVertical = (rw.y - shoulderY).abs() < 80;
            final isRightPunch = rightPunchHorizontal && rightPunchVertical;

            if (isLeftPunch || isRightPunch) {
              punchCount++;
            }
          }
        }

        if (await tempFile.exists()) await tempFile.delete();
      }

      final isFocus = punchCount >= (fps ~/ 3);

      _detectionResults.add(
        DetectionResult(
          frameIndex: sec,
          timestampSeconds: sec,
          isFocusPose: isFocus,
          isUnfocusPose: !isFocus,
          poseType: "Punch",
        ),
      );

      if (mounted) {
        setState(() {
          _progress = (sec + 1) / widget.videoDurationInSeconds;
        });
      }
    }

    _goToChoosePage();
  }

  void _goToChoosePage() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => SelectFocusExerciseCategoryPage(
          videoPath: widget.videoPath,
          detectionResults: _detectionResults,
          currentUser: widget.currentUser,
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
          "Pose Detection Page",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF00BCD4),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: _primaryColor.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: CircularProgressIndicator(
                      value: _progress,
                      strokeWidth: 7,
                      valueColor: AlwaysStoppedAnimation(_primaryColor),
                      backgroundColor: _primaryColor.withOpacity(0.25),
                    ),
                  ),
                  Icon(Icons.auto_graph, size: 40, color: _primaryColor),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                "Video Processing...",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: _primaryColor,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "${(_progress * 100).toStringAsFixed(0)}%",
                style: TextStyle(fontSize: 18, color: Colors.grey[700]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

