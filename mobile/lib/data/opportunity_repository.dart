import 'dart:async';

import 'package:flutter/foundation.dart';

import 'api_client.dart';
import 'career_profile_repository.dart';
import 'current_cv_repository.dart';
import 'github_profile_repository.dart';
import 'models.dart';
import 'session_storage.dart';

class OpportunityRepository extends ChangeNotifier {
  final ApiClient api;
  final CareerProfileRepository careerProfileRepository;
  final GithubProfileRepository githubProfileRepository;
  final CurrentCvRepository currentCvRepository;
  final SessionStorage storage;

  OpportunitySearchResult? result;
  String roleType = 'newgrad';
  String timeframe = 'all';
  String targetMarket = 'europe';
  List<String> locations = const ['Berlin', 'Germany'];
  List<String> keywords = const ['software engineer', 'backend'];
  List<String> workModes = const ['remote', 'hybrid'];
  bool loading = false;
  String? loadingStage;
  String? error;

  OpportunityRepository({
    required this.api,
    required this.careerProfileRepository,
    required this.githubProfileRepository,
    required this.currentCvRepository,
    required this.storage,
  });

  Future<void> loadSavedPreferences() async {
    final saved = await storage.readOpportunityPreferences();
    if (saved == null) return;
    roleType = saved['role_type'] as String? ?? roleType;
    timeframe = saved['timeframe'] as String? ?? timeframe;
    targetMarket = saved['target_market'] as String? ?? targetMarket;
    locations = List<String>.from(
      saved['locations'] as List? ?? locations,
    );
    keywords = List<String>.from(
      saved['keywords'] as List? ?? keywords,
    );
    workModes = List<String>.from(
      saved['work_modes'] as List? ?? workModes,
    );
    notifyListeners();
  }

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
    try {
      await storage.saveOpportunityPreferences({
        'role_type': roleType,
        'timeframe': timeframe,
        'target_market': targetMarket,
        'locations': locations,
        'keywords': keywords,
        'work_modes': workModes,
      });
    } catch (_) {
      // Preference persistence must not prevent a live search.
    }
    loading = true;
    loadingStage = 'Preparing your profile evidence…';
    error = null;
    notifyListeners();
    try {
      final synced = await Future.wait<bool>([
        careerProfileRepository.ensureSynced(),
        githubProfileRepository.ensureSynced(),
        currentCvRepository.ensureSynced(),
      ]).timeout(const Duration(seconds: 75));
      final linkedInReady = synced[0];
      final githubReady = synced[1];
      final resumeReady = synced[2];
      if (careerProfileRepository.hasProfile && !linkedInReady) {
        throw const ApiException(
          'Your LinkedIn evidence could not be loaded for matching.',
        );
      }
      if (githubProfileRepository.hasProfile && !githubReady) {
        throw const ApiException(
          'Your GitHub projects could not be loaded for matching.',
        );
      }
      if (currentCvRepository.hasProfile && !resumeReady) {
        throw const ApiException(
          'Your resume could not be loaded for matching. Try replacing the '
          'PDF or signing in again.',
        );
      }
      loadingStage = 'Loading and ranking live roles…';
      notifyListeners();
      final json = await api.post(
        '/v1/career/opportunities/search',
        timeout: const Duration(seconds: 75),
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
    } on TimeoutException {
      error = 'The opportunity search took too long. The live job source or '
          'backend may still be waking up; try once more.';
      return false;
    } on ApiException catch (exception) {
      error = exception.message;
      return false;
    } catch (_) {
      error = 'Live opportunities could not be loaded right now.';
      return false;
    } finally {
      loading = false;
      loadingStage = null;
      notifyListeners();
    }
  }

  void clear() {
    result = null;
    loadingStage = null;
    error = null;
    notifyListeners();
  }
}
