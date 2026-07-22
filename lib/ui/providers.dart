import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:huespill/data/repositories/progress_repository.dart';
import 'package:huespill/data/services/hive_service.dart';
import 'package:huespill/ui/features/home/view_models/home_view_model.dart';

final hiveServiceProvider = Provider<HiveService>((ref) {
  throw UnimplementedError('Must be overridden in main');
});

final progressRepositoryProvider = Provider<ProgressRepository>((ref) {
  final hiveService = ref.watch(hiveServiceProvider);
  return ProgressRepository(hiveService: hiveService);
});

final homeViewModelProvider =
    StateNotifierProvider<HomeViewModel, HomeViewModelState>((ref) {
      final progressRepository = ref.watch(progressRepositoryProvider);
      return HomeViewModel(progressRepository: progressRepository);
    });

