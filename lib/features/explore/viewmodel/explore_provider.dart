import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speakwise_mobile/features/explore/data/events_repository.dart';
import 'package:speakwise_mobile/features/explore/data/models/event_model.dart';
import 'package:speakwise_mobile/features/explore/viewmodel/explore_state.dart';
import 'package:speakwise_mobile/features/explore/viewmodel/explore_viewmodel.dart';

final exploreViewModelProvider =
    StateNotifierProvider<ExploreViewModel, ExploreState>((ref) {
  final repository = ref.watch(eventsRepositoryProvider);
  return ExploreViewModel(repository);
});

final eventDetailProvider =
    FutureProvider.family<EventItem?, String>((ref, id) async {
  final repository = ref.watch(eventsRepositoryProvider);
  return await repository.getEventDetail(id);
});
