class DetectionResult {
  final int frameIndex;
  final bool isFocusPose;
  final bool isUnfocusPose;
  final int timestampSeconds;
  final String poseType;

  DetectionResult({
    required this.frameIndex,
    required this.isFocusPose,
    required this.isUnfocusPose,
    required this.timestampSeconds,
    required this.poseType,
  }) : assert(
          (isFocusPose ? 1 : 0) + (isUnfocusPose ? 1 : 0) == 1,
          'Each frame must belong to exactly one category',
        );
}

class DetectionSummary {
  int totalFocusPose = 0;
  int totalUnfocusPose = 0;
  final Map<String, int> poseDurations = {};

  DetectionSummary(List<DetectionResult> results) {
    for (var i = 0; i < results.length; i++) {
      final result = results[i];
      int duration = 1;
      if (i < results.length - 1) {
        duration = results[i + 1].timestampSeconds - result.timestampSeconds;
      }
      if (result.isFocusPose) totalFocusPose += duration;
      if (result.isUnfocusPose) totalUnfocusPose += duration;
      poseDurations[result.poseType] =
          (poseDurations[result.poseType] ?? 0) + duration;
    }
  }

  int get focusPoseSeconds => totalFocusPose;
  int get unfocusPoseSeconds => totalUnfocusPose;
  int getPoseSeconds(String pose) => poseDurations[pose] ?? 0;

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('Focus Pose: $totalFocusPose s');
    buffer.writeln('Unfocus Pose: $totalUnfocusPose s');
    poseDurations.forEach((pose, seconds) {
      buffer.writeln('$pose: $seconds s');
    });
    return buffer.toString();
  }
}