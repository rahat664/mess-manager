import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/meal_repository.dart';
import '../models/meal.dart';

typedef MealQuery = ({String messId, String month, String? memberId});

final mealsProvider = StreamProvider.family<List<Meal>, MealQuery>((ref, args) {
  return ref
      .watch(mealRepositoryProvider)
      .streamMeals(messId: args.messId, month: args.month, memberId: args.memberId);
});
