import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/exercise_type.dart';
import '../state/app_state.dart';
import 'upload_exercise_video.dart';

class SelectExerciseTypePage extends StatelessWidget {
  final String currentUser;

  const SelectExerciseTypePage({
    super.key,
    required this.currentUser,
  });

  @override
  Widget build(BuildContext context) {
    final double cardWidth = double.infinity;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text(
          "Select Exercise Type Page",
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 16),
            const Text(
              "Please select a favourite exercise type",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            _exerciseCard(
              context,
              exerciseType: ExerciseType.CatCow,
              title: "Cat-Cow Pose Exercise",
              images: const [
                'assets/images/cat-cow_pose.png',
              ],
              steps: const [
                "1. Cat Pose: Arch up, tuck chin",
                "2. Transition: Spine moves slowly",
                "3. Cow Pose: Arch down, lift chest",
              ],
              width: cardWidth,
              gradientColors: const [
                Color(0xFF0F766E),
                Color(0xFF10B981),
              ],
              imageAlignment: Alignment.center,
            ),
            const SizedBox(height: 16),
            _exerciseCard(
              context,
              exerciseType: ExerciseType.Lunge,
              title: "Lunge Exercise",
              images: const [
                'assets/images/Lunge.png',
              ],
              steps: const [
                "1. Step forward, bend knee",
                "2. Back leg straight",
                "3. Return & repeat",
              ],
              width: cardWidth,
              gradientColors: const [
                Color(0xFF0F766E),
                Color(0xFF22C55E),
              ],
              imageAlignment: Alignment.topCenter, 
            ),
            const SizedBox(height: 16),
            _exerciseCard(
              context,
              exerciseType: ExerciseType.Punch,
              title: "Punch Exercise",
              images: const [
                'assets/images/Punch.png',
              ],
              steps: const [
                "1. Stand, fists near shoulders",
                "2. Punch one arm forward",
                "3. Return & repeat",
              ],
              width: cardWidth,
              gradientColors: const [
                Color(0xFF10B981),
                Color(0xFF22C55E),
              ],
              imageAlignment: Alignment.bottomCenter, 
            ),
          ],
        ),
      ),
    );
  }

  Widget _exerciseCard(
    BuildContext context, {
    required ExerciseType exerciseType,
    required String title,
    required List<String> images,
    required List<String> steps,
    required double width,
    required List<Color> gradientColors,
    Alignment imageAlignment = Alignment.center,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          bool? viewSteps = await showDialog(
            context: context,
            builder: (dialogContext) => AlertDialog(
              backgroundColor: Colors.blue.shade50,
              title: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: steps
                    .map(
                      (step) => Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          step,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text("OK"),
                ),
              ],
            ),
          );

          if (viewSteps == true) {
            bool? confirmed = await showDialog(
              context: context,
              builder: (dialogContext) => AlertDialog(
                backgroundColor: Colors.blue.shade50,
                title: const Text(
                  "Confirm Selection",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                content: const Text(
                  "Are you sure you want to select this exercise?",
                  style: TextStyle(fontSize: 14),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext, true),
                    child: const Text("Yes"),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext, false),
                    child: const Text("No"),
                  ),
                ],
              ),
            );

            if (confirmed == true) {
              Provider.of<AppState>(context, listen: false)
                  .setExercise(exerciseType);

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => UploadVideoPage(
                    currentUser: currentUser,
                  ),
                ),
              );
            }
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: width,
          height: 220,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: images
                    .map(
                      (img) => Expanded(
                        child: Align(
                          alignment: imageAlignment,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.asset(
                              img,
                              height: 220,
                              width: double.infinity,
                              fit: BoxFit.fitWidth,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}