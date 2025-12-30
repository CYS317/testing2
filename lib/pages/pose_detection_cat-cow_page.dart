import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import '../models/detection_result.dart';
import 'select_focus_exercise_category.dart';

class PoseDetectionCatCowPage extends StatefulWidget {
  final String videoPath;
  final int videoDurationInSeconds;
  final String currentUser;
  const PoseDetectionCatCowPage({
    super.key,
    required this.videoPath,
    required this.videoDurationInSeconds,
    required this.currentUser,
  });

  @override
  State<PoseDetectionCatCowPage> createState() => _PoseDetectionCatCowPageState();
}

class _PoseDetectionCatCowPageState extends State<PoseDetectionCatCowPage> {
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

  double angle(Offset a, Offset b, Offset c) {
    final ab = Offset(a.dx - b.dx, a.dy - b.dy);
    final cb = Offset(c.dx - b.dx, c.dy - b.dy);
    final dot = ab.dx * cb.dx + ab.dy * cb.dy;
    final magA = ab.distance;
    final magC = cb.distance;
    if (magA == 0 || magC == 0) return 0;
    double cosTheta = dot / (magA * magC);
    cosTheta = cosTheta.clamp(-1.0, 1.0);
    return acos(cosTheta) * 180 / pi;
  }

  Future<void> _analyzeVideo() async {
    const int fps = 4;

    for (int sec = 0; sec < widget.videoDurationInSeconds; sec++) {
      int catFrames = 0;
      int cowFrames = 0;
      bool handUnfocus = false;
      bool legUnfocus = false;
      bool hasAtLeastOneFullBody = false;

      for (int f = 0; f < fps; f++) {
        final thumb = await VideoThumbnail.thumbnailData(
          video: widget.videoPath,
          imageFormat: ImageFormat.JPEG,
          timeMs: sec * 1000 + (f * 1000 / fps).round(),
          quality: 75,
        );
        if (thumb == null) continue;

        final tempFile = File('${Directory.systemTemp.path}/frame_${sec}_$f.jpg');
        await tempFile.writeAsBytes(thumb);
        final inputImage = InputImage.fromFile(tempFile);
        final poses = await _poseDetector.processImage(inputImage);

        if (poses.isNotEmpty) {
          final pose = poses.first;
          final ls = pose.landmarks[PoseLandmarkType.leftShoulder];
          final rs = pose.landmarks[PoseLandmarkType.rightShoulder];
          final lh = pose.landmarks[PoseLandmarkType.leftHip];
          final rh = pose.landmarks[PoseLandmarkType.rightHip];
          final lk = pose.landmarks[PoseLandmarkType.leftKnee];
          final rk = pose.landmarks[PoseLandmarkType.rightKnee];
          final la = pose.landmarks[PoseLandmarkType.leftAnkle];
          final ra = pose.landmarks[PoseLandmarkType.rightAnkle];
          final lw = pose.landmarks[PoseLandmarkType.leftWrist];
          final rw = pose.landmarks[PoseLandmarkType.rightWrist];

          final hasFullBody = ls != null &&
              rs != null &&
              lh != null &&
              rh != null &&
              lk != null &&
              rk != null &&
              la != null &&
              ra != null;

          if (!hasFullBody) {
            if (await tempFile.exists()) await tempFile.delete();
            continue;
          }

          hasAtLeastOneFullBody = true;

          final shoulder = Offset((ls.x + rs.x) / 2, (ls.y + rs.y) / 2);
          final hip = Offset((lh.x + rh.x) / 2, (lh.y + rh.y) / 2);
          final knee = Offset((lk.x + rk.x) / 2, (lk.y + rk.y) / 2);
          final spineAngle = angle(shoulder, hip, knee);
          final isFourLeg = (knee.dy > hip.dy && hip.dy > shoulder.dy) &&
              (shoulder.dy - hip.dy).abs() < 120;

          if (isFourLeg) {
            if (spineAngle > 30) catFrames++;
            if (spineAngle < 10) cowFrames++;
          }

          if (lw != null && lw.y < shoulder.dy - 5) handUnfocus = true;
          if (rw != null && rw.y < shoulder.dy - 5) handUnfocus = true;
          if (la.y < hip.dy - 10) legUnfocus = true;
          if (ra.y < hip.dy - 10) legUnfocus = true;
        }

        if (await tempFile.exists()) await tempFile.delete();
      }

      if (hasAtLeastOneFullBody) {
        bool isFocus =
            ((catFrames >= fps / 2) || (cowFrames >= fps / 2)) &&
                !handUnfocus &&
                !legUnfocus;
        bool isUnfocus = !isFocus;

        String currentPoseType = 'Unknown';
        if (catFrames >= fps / 2) {
          currentPoseType = 'Cat Pose';
        } else if (cowFrames >= fps / 2) {
          currentPoseType = 'Cow Pose';
        } else if (handUnfocus || legUnfocus) {
          currentPoseType = 'Unfocus Pose';
        }

        _detectionResults.add(
          DetectionResult(
            frameIndex: sec,
            timestampSeconds: sec,
            isFocusPose: isFocus,
            isUnfocusPose: isUnfocus,
            poseType: currentPoseType,
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
