import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../models/exercise_type.dart';
import 'pose_detection_cat-cow_page.dart';
import 'pose_detection_lunge_pose.dart';
import 'pose_detection_punch_pose.dart';

class UploadVideoPage extends StatefulWidget {
  final String currentUser;
  const UploadVideoPage({super.key, required this.currentUser});

  @override
  _UploadVideoPageState createState() => _UploadVideoPageState();
}

class _UploadVideoPageState extends State<UploadVideoPage> {
  VideoPlayerController? _videoController;
  String? _videoPath;
  bool _isVideoValid = false;
  bool _isUploading = false;
  bool _uploadSuccess = false;
  bool _uploadFailed = false;

  final Color _primaryColor = const Color(0xFF00BCD4);
  final Color _secondaryColor = const Color(0xFF4DD0E1);

  Future<void> pickVideo() async {
    bool confirmed = await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.yellow.shade100,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: const Text(
          "⚠️ Video Upload Notice",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        content: const Text(
          "1. Please keep the phone stable and ensure full-body capture.\n"
          "2. Ensure no messy background or other people obstructing the camera.",
          style: TextStyle(color: Colors.black87, fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              "OK",
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isUploading = true;
      _uploadSuccess = false;
      _uploadFailed = false;
      _isVideoValid = false;
      _videoController?.dispose();
      _videoController = null;
      _videoPath = null;
    });

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.video,
    );

    if (result == null) {
      setState(() {
        _isUploading = false;
        _uploadFailed = true;
      });
      return;
    }

    String filePath = result.files.single.path!;
    _videoController = VideoPlayerController.file(File(filePath));

    try {
      await _videoController!.initialize();
      Duration videoDuration = _videoController!.value.duration;

      if (videoDuration.inSeconds == 0) {
        _videoController?.dispose();
        _videoController = null;
        setState(() {
          _isUploading = false;
          _uploadFailed = true;
        });
        return;
      }

      _videoPath = filePath;
      _isVideoValid = true;
      _uploadSuccess = true;

      setState(() => _isUploading = false);
    } catch (e) {
      _videoController?.dispose();
      _videoController = null;
      setState(() {
        _isUploading = false;
        _uploadFailed = true;
      });
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  Widget _buildVideoPreview() {
    return Column(
      children: [
        AspectRatio(
          aspectRatio: _videoController!.value.aspectRatio,
          child: VideoPlayer(_videoController!),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: 160,
          child: ElevatedButton.icon(
            onPressed: () {
              if (_videoController!.value.isPlaying) {
                _videoController!.pause();
              } else {
                _videoController!.play();
              }
              setState(() {});
            },
            icon: Icon(
              _videoController!.value.isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
              size: 24,
            ),
            label: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                _videoController!.value.isPlaying ? "Pause Preview" : "Play Preview",
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
          ),
        ),
        const SizedBox(height: 20),
        if (_uploadSuccess)
          const Text(
            "Video uploaded successfully!",
            style: TextStyle(fontSize: 16, color: Colors.green, fontWeight: FontWeight.bold, fontFamily: 'RobotoMono'),
          ),
        if (_uploadFailed)
          const Text(
            "Video upload failed!",
            style: TextStyle(fontSize: 16, color: Colors.red, fontWeight: FontWeight.bold, fontFamily: 'RobotoMono'),
          ),
        const SizedBox(height: 15),
        Column(
          children: [
            ElevatedButton(
              onPressed: _isVideoValid
                  ? () {
                      if (_videoPath != null && _videoController != null) {
                        final duration = _videoController!.value.duration.inSeconds;
                        ExerciseType? exerciseType = Provider.of<AppState>(context, listen: false).selectedExercise;
                        if (exerciseType != null) {
                          switch (exerciseType) {
                            case ExerciseType.CatCow:
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PoseDetectionCatCowPage(
                                    videoPath: _videoPath!,
                                    videoDurationInSeconds: duration,
                                    currentUser: widget.currentUser,
                                  ),
                                ),
                              );
                              break;
                            case ExerciseType.Lunge:
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PoseDetectionLungePage(
                                    videoPath: _videoPath!,
                                    videoDurationInSeconds: duration,
                                    currentUser: widget.currentUser,
                                  ),
                                ),
                              );
                              break;
                            case ExerciseType.Punch:
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PoseDetectionPunchPage(
                                    videoPath: _videoPath!,
                                    videoDurationInSeconds: duration,
                                    currentUser: widget.currentUser,
                                  ),
                                ),
                              );
                              break;
                          }
                        }
                      }
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              child: const Text(
                "Next: Detect Pose",
                style: TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _isUploading ? null : pickVideo,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade600,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              child: const Text(
                "Re-upload Video",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text(
          "Upload Video Page",
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 30),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [_primaryColor, _secondaryColor],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: const [
                      Icon(Icons.video_library_rounded, size: 50, color: Colors.white),
                      SizedBox(height: 16),
                      Text(
                        "Upload Your Exercise Video",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Support any video format",
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                if (_isUploading)
                  const CircularProgressIndicator()
                else if (_videoController != null && _isVideoValid)
                  _buildVideoPreview()
                else
                  ElevatedButton(
                    onPressed: _isUploading ? null : pickVideo,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    child: const Text(
                      "Choose Video",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
