import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../models/detection_result.dart';
import 'select_focus_exercise_category.dart';
import '../models/exercise_type.dart';

class ShowVideoPage extends StatefulWidget {
  final String videoPath;
  final List<DetectionResult> detectionResults;
  final String selectedType;
  final int selectedInattentiveTime;
  final ExerciseType exerciseType;
  final String currentUser;

  const ShowVideoPage({
    super.key,
    required this.videoPath,
    required this.detectionResults,
    required this.selectedType,
    required this.selectedInattentiveTime,
    required this.exerciseType,
    required this.currentUser,
  });

  @override
  State<ShowVideoPage> createState() => _ShowVideoPageState();
}

class _ShowVideoPageState extends State<ShowVideoPage> {
  late VideoPlayerController _controller;
  late List<List<DetectionResult>> _filteredSegments;
  int _currentSegmentIndex = 0;
  bool _isControllerInitialized = false;
  final Color _primaryColor = const Color(0xFF00BCD4);
  final Color _backgroundColor = const Color(0xFF0F172A);

  String get _appBarTitle {
    String poseName = widget.exerciseType.name;
    String focusType = widget.selectedType == "Focus Pose" ? "Focus" : "Unfocus";
    return "Show $poseName Pose $focusType Page";
  }

  @override
  void initState() {
    super.initState();
    _filterResults();
    if (_filteredSegments.isNotEmpty) {
      _initializeController();
    }
  }

  List<List<DetectionResult>> _groupSegments(bool Function(DetectionResult) condition) {
    List<List<DetectionResult>> segments = [];
    List<DetectionResult> currentSegment = [];
    for (var res in widget.detectionResults) {
      if (condition(res)) {
        currentSegment.add(res);
      } else {
        if (currentSegment.isNotEmpty) {
          segments.add(List.from(currentSegment));
          currentSegment.clear();
        }
      }
    }
    if (currentSegment.isNotEmpty) segments.add(currentSegment);
    return segments;
  }

  void _filterResults() {
    List<DetectionResult> processedResults = [];
    for (int i = 0; i < widget.detectionResults.length; i++) {
      final res = widget.detectionResults[i];
      int duration = 1;
      if (i < widget.detectionResults.length - 1) {
        duration = widget.detectionResults[i + 1].timestampSeconds - res.timestampSeconds;
      }
      if (res.isFocusPose && duration > widget.selectedInattentiveTime) {
        processedResults.add(
          DetectionResult(
            frameIndex: res.frameIndex,
            timestampSeconds: res.timestampSeconds,
            isFocusPose: false,
            isUnfocusPose: true,
            poseType: res.poseType,
          ),
        );
      } else {
        processedResults.add(res);
      }
    }

    switch (widget.selectedType) {
      case "Focus Pose":
        _filteredSegments = _groupSegments((res) => res.isFocusPose);
        break;
      case "Unfocus Pose":
        _filteredSegments = _groupSegments((res) => res.isUnfocusPose);
        break;
      default:
        _filteredSegments = [];
    }
  }

  void _initializeController() {
    _controller = VideoPlayerController.file(File(widget.videoPath))
      ..initialize().then((_) {
        if (mounted) {
          setState(() {
            _isControllerInitialized = true;
          });
          _playCurrentSegment();
        }
      });

    _controller.addListener(() {
      if (!_controller.value.isPlaying || !mounted) return;
      final currentSecond = _controller.value.position.inSeconds;
      final segment = _filteredSegments[_currentSegmentIndex];
      final segmentEnd = segment.last.timestampSeconds;

      if (currentSecond >= segmentEnd + 1) {
        _controller.pause();
        setState(() {});
      }
    });
  }

  void _playCurrentSegment() async {
    if (_filteredSegments.isEmpty || !_isControllerInitialized) return;
    if (_currentSegmentIndex >= _filteredSegments.length) return;
    final segment = _filteredSegments[_currentSegmentIndex];
    await _controller.seekTo(Duration(seconds: segment.first.timestampSeconds));
    await _controller.play();
    if (mounted) setState(() {});
  }

  void _nextSegment() {
    if (_currentSegmentIndex + 1 < _filteredSegments.length) {
      setState(() {
        _currentSegmentIndex++;
      });
      _playCurrentSegment();
    }
  }

  void _prevSegment() {
    if (_currentSegmentIndex > 0) {
      setState(() {
        _currentSegmentIndex--;
      });
      _playCurrentSegment();
    }
  }

  void _togglePlayPause() async {
    if (!_isControllerInitialized) return;
    if (_controller.value.isPlaying) await _controller.pause();
    else await _controller.play();
    if (mounted) setState(() {});
  }

  void _goBackToChoose() {
    if (_isControllerInitialized) _controller.pause();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => SelectFocusExerciseCategoryPage(
          videoPath: widget.videoPath,
          detectionResults: widget.detectionResults,
          currentUser: widget.currentUser,
        ),
      ),
    );
  }

  List<DetectionResult> get currentSegment {
    if (_filteredSegments.isEmpty) return [];
    if (_currentSegmentIndex >= _filteredSegments.length) return [];
    return _filteredSegments[_currentSegmentIndex];
  }

  Widget _buildFeedbackCard() {
    final segment = currentSegment;
    int start = segment.isNotEmpty ? segment.first.timestampSeconds : 0;
    int end = segment.isNotEmpty ? segment.last.timestampSeconds : 0;

    String feedbackText = "";
    Color cardColor = Colors.white;
    IconData iconData = Icons.info_outline;
    Color iconColor = Colors.black;

    final poseType = widget.exerciseType;

    if (widget.selectedType == "Focus Pose") {
      if (poseType == ExerciseType.CatCow) {
        feedbackText =
            "✓ You are doing the Cat–Cow pose attentively.\n"
            "Keep up the good work!\n\n"
            "Recommended Cat–Cow Steps:\n"
            "1. Place your hands directly under your shoulders and knees under your hips.\n"
            "2. Move gently between arching (Cow) and rounding (Cat) your back.\n"
            "3. Maintain controlled movement and steady breathing.\n\n"
            "Time: $start s - $end s";
        cardColor = Colors.green.shade50;
        iconData = Icons.check_circle;
        iconColor = Colors.green;
      } else if (poseType == ExerciseType.Lunge) {
        feedbackText =
            "✓ You are performing Lunge attentively.\n"
            "Maintain proper form for best results.\n\n"
            "Recommended Lunge Steps:\n"
            "1. Step one leg forward and bend the knee to form a 90° angle (or slightly bent is fine).\n"
            "2. Keep the other leg straight behind and maintain balance.\n"
            "3. Slowly return to standing and repeat with the other leg.\n\n"
            "Time: $start s - $end s";
        cardColor = Colors.orange.shade50;
        iconData = Icons.directions_run;
        iconColor = Colors.orange;
      } else if (poseType == ExerciseType.Punch) {
        feedbackText =
            "✓ You are performing the Punch pose.\n"
            "Maintain controlled movements and proper stance.\n\n"
            "Recommended Punch Steps:\n"
            "1. Stand with feet shoulder-width apart.\n"
            "2. Punch forward alternately with controlled speed.\n"
            "3. Keep elbows slightly bent and wrists aligned.\n\n"
            "Time: $start s - $end s";
        cardColor = Colors.blue.shade50;
        iconData = Icons.sports_martial_arts;
        iconColor = Colors.blue;
      } else {
        feedbackText = "Detected pose: ${poseType.name}\nTime: $start s - $end s";
        cardColor = Colors.grey.shade200;
        iconData = Icons.info_outline;
        iconColor = Colors.grey;
      }
    } else {
      if (poseType == ExerciseType.CatCow) {
        feedbackText =
            "✖ You lost focus during the Cat–Cow pose.\n"
            "Try to refocus and maintain a controlled motion.\n\n"
            "Recommended Cat–Cow Steps:\n"
            "1. Place your hands directly under your shoulders and knees under your hips.\n"
            "2. Move gently between arching (Cow) and rounding (Cat) your back.\n"
            "3. Maintain controlled movement and steady breathing.\n\n"
            "Time: $start s - $end s";
        cardColor = Colors.red.shade50;
        iconData = Icons.error;
        iconColor = Colors.red;
      } else if (poseType == ExerciseType.Lunge) {
        feedbackText =
            "✖ You lost focus during the Lunge pose.\n"
            "Try to refocus and maintain proper form.\n\n"
            "Recommended Lunge Steps:\n"
            "1. Step one leg forward and bend the knee to form a 90° angle (or slightly bent is fine).\n"
            "2. Keep the other leg straight behind and maintain balance.\n"
            "3. Slowly return to standing and repeat with the other leg.\n\n"
            "Time: $start s - $end s";
        cardColor = Colors.red.shade50;
        iconData = Icons.error;
        iconColor = Colors.red;
      } else if (poseType == ExerciseType.Punch) {
        feedbackText =
            "✖ You lost focus during the Punch pose.\n"
            "Try to refocus and maintain controlled movements.\n\n"
            "Recommended Punch Steps:\n"
            "1. Stand with feet shoulder-width apart.\n"
            "2. Punch forward alternately with controlled speed.\n"
            "3. Keep elbows slightly bent and wrists aligned.\n\n"
            "Time: $start s - $end s";
        cardColor = Colors.red.shade50;
        iconData = Icons.error;
        iconColor = Colors.red;
      } else {
        feedbackText = "Detected pose: ${poseType.name}\nTime: $start s - $end s";
        cardColor = Colors.grey.shade200;
        iconData = Icons.info_outline;
        iconColor = Colors.grey;
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: iconColor,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(iconData, size: 32, color: iconColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              feedbackText,
              style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    if (_isControllerInitialized) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_filteredSegments.isEmpty) {
      return Scaffold(
        backgroundColor: _backgroundColor,
        appBar: AppBar(
          title: Text(
            _appBarTitle,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
          ),
          backgroundColor: _primaryColor,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.info_outline, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                "No video segments found for\n\"${widget.selectedType}\"",
                style: TextStyle(fontSize: 16, color: Colors.grey[300]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _goBackToChoose,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal, 
                  foregroundColor: Colors.white,
                ),
                child: const Text("Back to Choose Detection"),
              ),
            ],
          ),
        ),
      );
    }

    bool showPrev = _currentSegmentIndex > 0;
    bool showNext = _currentSegmentIndex < _filteredSegments.length - 1;

    double screenWidth = MediaQuery.of(context).size.width;
    double contentWidth = screenWidth * 0.75;

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: Text(
          _appBarTitle,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
        ),
        backgroundColor: _primaryColor,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "${widget.selectedType} Video ${_currentSegmentIndex + 1}",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Column(
                  children: [
                    SizedBox(
                      width: contentWidth,
                      child: AspectRatio(
                        aspectRatio: _isControllerInitialized ? _controller.value.aspectRatio : 16 / 9,
                        child: _isControllerInitialized
                            ? VideoPlayer(_controller)
                            : const Center(child: CircularProgressIndicator(color: Colors.black54)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_isControllerInitialized)
                      SizedBox(
                        width: contentWidth,
                        child: VideoProgressIndicator(
                          _controller,
                          allowScrubbing: true,
                          colors: VideoProgressColors(
                            playedColor: _primaryColor,
                            bufferedColor: Colors.grey[300]!,
                            backgroundColor: Colors.grey[200]!,
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: contentWidth,
                      child: _buildFeedbackCard(),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: contentWidth,
                      child: Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _togglePlayPause,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepPurple,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                              child: Text(_isControllerInitialized && _controller.value.isPlaying ? "Pause" : "Play"),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              if (showPrev)
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: _prevSegment,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.indigo,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                    ),
                                    child: const Text("Previous"),
                                  ),
                                ),
                              if (showPrev && showNext) const SizedBox(width: 12),
                              if (showNext)
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: _nextSegment,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.indigo,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                    ),
                                    child: const Text("Next"),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: _goBackToChoose,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.teal,
                                side: BorderSide(color: Colors.teal, width: 2),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                              child: const Text("Back to Choose Detection"),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
