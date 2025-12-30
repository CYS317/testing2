import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import '../models/detection_result.dart';
import 'select_focus_exercise_category.dart';

class PoseDetectionLungePage extends StatefulWidget {
  final String videoPath;
  final int videoDurationInSeconds;
  final String currentUser;

  const PoseDetectionLungePage({
    super.key,
    required this.videoPath,
    required this.videoDurationInSeconds,
    required this.currentUser,
  });

  @override
  State<PoseDetectionLungePage> createState() =>
      _PoseDetectionLungePageState();
}

class _PoseDetectionLungePageState extends State<PoseDetectionLungePage> {
  double _progress = 0.0;
  final Color _primaryColor = const Color(0xFF00BCD4);
  final List<DetectionResult> _detectionResults = [];
  late PoseDetector _poseDetector;

  List<double> leftKneeHeights = [];
  List<double> rightKneeHeights = [];
  List<double> hipHeights = [];

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
      bool hasLandmarks = false;
      int validFrames = 0;

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

          final lh = pose.landmarks[PoseLandmarkType.leftHip];
          final rh = pose.landmarks[PoseLandmarkType.rightHip];
          final lk = pose.landmarks[PoseLandmarkType.leftKnee];
          final rk = pose.landmarks[PoseLandmarkType.rightKnee];

          if (lh != null && rh != null && lk != null && rk != null) {
            double hipY = (lh.y + rh.y) / 2;
            double leftKneeHeight = hipY - lk.y;
            double rightKneeHeight = hipY - rk.y;

            hipHeights.add(hipY);
            leftKneeHeights.add(leftKneeHeight);
            rightKneeHeights.add(rightKneeHeight);

            if (hipHeights.length > 8) hipHeights.removeAt(0);
            if (leftKneeHeights.length > 8) leftKneeHeights.removeAt(0);
            if (rightKneeHeights.length > 8) rightKneeHeights.removeAt(0);

            bool isFocus = false;

            if (hipHeights.length >= 4) {
              int mid = hipHeights.length ~/ 2;

              double firstAvg = hipHeights
                      .sublist(0, mid)
                      .reduce((a, b) => a + b) /
                  mid;

              double lastAvg = hipHeights
                      .sublist(mid)
                      .reduce((a, b) => a + b) /
                  (hipHeights.length - mid);

              double hipDrop = lastAvg - firstAvg;

              if (hipDrop > 0.05) {
                isFocus = true;
              }
            }

            if (leftKneeHeight > 0.1 || rightKneeHeight > 0.1) {
              isFocus = true;
            }

            if (isFocus) validFrames++;
            hasLandmarks = true;
          }
        }

        if (await tempFile.exists()) {
          await tempFile.delete();
        }
      }

      if (hasLandmarks && validFrames >= 2) {
        _detectionResults.add(
          DetectionResult(
            frameIndex: sec,
            timestampSeconds: sec,
            isFocusPose: true,
            isUnfocusPose: false,
            poseType: "Lunge",
          ),
        );
      } else {
        _detectionResults.add(
          DetectionResult(
            frameIndex: sec,
            timestampSeconds: sec,
            isFocusPose: false,
            isUnfocusPose: true,
            poseType: "Lunge",
          ),
        );
      }

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
