import 'package:flutter/material.dart';
import '../models/exercise_type.dart';

class AppState extends ChangeNotifier {
  ExerciseType? selectedExercise;

  void setExercise(ExerciseType exercise) {
    selectedExercise = exercise;
    notifyListeners();
  }

  void clearExercise() {
    selectedExercise = null;
    notifyListeners();
  }
}