import 'package:flutter/foundation.dart';

import 'api_client.dart';
import 'career_profile_repository.dart';
import 'current_cv_repository.dart';
import 'github_profile_repository.dart';
import 'models.dart';

class OpportunityRepository extends ChangeNotifier {
  final ApiClient api;
  final CareerProfileRepository careerProfileRepository;
  final GithubProfileRepository githubProfileRepository;
  final CurrentCvRepository currentCvRepository;

  OpportunitySearchResult? result;
  String roleType = 'newgrad';
  String timeframe = 'all';
  String targetMarket = 'europe';
  List<String> locations = const ['Berlin', 'Germany'];
  List<String> keywords = const ['software engineer', 'backend'];
  List<String> workModes = const ['remote', 'hybrid'];
  bool loading = false;
  String? error;

  OpportunityRepository({
    required this.api,
    required this.careerProfileRepository,
    required this.githubProfileRepository,
    required this.currentCvRepository,
  });

  Future<bool> search({
    required String roleType,
    required String timeframe,
    required String targetMarket,
    required List<String> locations,
    required List<String> keywords,
    required List<String> workModes,
  }) async {
    if (loading) return false;
    this.roleType = roleType;
    this.timeframe = timeframe;
    this.targetMarket = targetMarket;
    this.locations = List.unmodifiable(locations);
    this.keywords = List.unmodifiable(keywords);
    this.workModes = List.unmodifiable(workModes);
    loading = true;
    error = null;
    notifyListeners();
    try {
      await careerProfileRepository.ensureSynced();
      await githubProfileRepository.ensureSynced();
      final resumeReady = await currentCvRepository.ensureSynced();
      if (currentCvRepository.hasProfile && !resumeReady) {
        throw const ApiException(
          'Your resume could not be loaded for matching. Try replacing the '
          'PDF or signing in again.',
        );
      }
      final json = await api.post(
        '/v1/career/opportunities/search',
        body: {
          'role_type': roleType,
          'timeframe': timeframe,
          'target_market': targetMarket,
          'locations': locations,
          'keywords': keywords,
          'work_modes': workModes,
          'limit': 24,
        },
      );
      result = OpportunitySearchResult.fromJson(json);
      return true;
    } on ApiException catch (exception) {
      error = exception.message;
      return false;
    } catch (_) {
      error = 'Live opportunities could not be loaded right now.';
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void clear() {
    result = null;
    error = null;
    notifyListeners();
  }
}
