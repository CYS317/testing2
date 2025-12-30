enum ExerciseType {
  CatCow,
  Lunge,
  Punch,
}

extension ExerciseTypeExtension on ExerciseType {
  String get displayName {
    switch (this) {
      case ExerciseType.CatCow:
        return "Cat-Cow Pose Exercise";
      case ExerciseType.Lunge:
        return "Lunge Exercise";
      case ExerciseType.Punch:
        return "Punch Exercise";
    }
  }
}
