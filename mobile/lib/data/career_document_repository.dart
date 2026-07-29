import 'package:flutter/foundation.dart';

import 'api_client.dart';
import 'career_profile_repository.dart';
import 'current_cv_repository.dart';
import 'github_profile_repository.dart';
import 'models.dart';
import 'tone_profile_repository.dart';

class CareerDocumentRepository extends ChangeNotifier {
  final ApiClient api;
  final CareerProfileRepository careerProfileRepository;
  final GithubProfileRepository githubProfileRepository;
  final CurrentCvRepository currentCvRepository;
  final ToneProfileRepository toneProfileRepository;

  final Map<String, CareerDocument> _documents = {};
  final Set<String> _busy = {};
  String? error;

  CareerDocumentRepository({
    required this.api,
    required this.careerProfileRepository,
    required this.githubProfileRepository,
    required this.currentCvRepository,
    required this.toneProfileRepository,
  });

  CareerDocument? documentFor(JobOpportunity job, String kind) =>
      _documents[_key(job.id, kind)];

  bool isBusy(JobOpportunity job, String kind) => _busy.contains(
        _key(job.id, kind),
      );

  Future<CareerDocument?> generate(
    JobOpportunity job,
    String kind, {
    String instructions = '',
  }) async {
    final key = _key(job.id, kind);
    if (_busy.contains(key)) return null;
    _busy.add(key);
    error = null;
    notifyListeners();
    try {
      await _syncEvidence();
      final json = await api.post(
        '/v1/career/documents/generate',
        body: {
          'kind': kind,
          'job': job.toDocumentJson(),
          'instructions': instructions,
        },
      );
      final document = CareerDocument.fromJson(json);
      _documents[key] = document;
      return document;
    } on ApiException catch (exception) {
      error = exception.message;
      return null;
    } catch (_) {
      error = 'The tailored document could not be generated right now.';
      return null;
    } finally {
      _busy.remove(key);
      notifyListeners();
    }
  }

  Future<CareerDocument?> refine(
    JobOpportunity job,
    CareerDocument document,
    String instruction,
  ) async {
    final key = _key(job.id, document.kind);
    if (_busy.contains(key)) return null;
    _busy.add(key);
    error = null;
    notifyListeners();
    try {
      await _syncEvidence();
      final json = await api.post(
        '/v1/career/documents/${document.id}/refine',
        body: {'instruction': instruction},
      );
      final updated = CareerDocument.fromJson(json);
      _documents[key] = updated;
      return updated;
    } on ApiException catch (exception) {
      error = exception.message;
      return null;
    } catch (_) {
      error = 'The document could not be refined right now.';
      return null;
    } finally {
      _busy.remove(key);
      notifyListeners();
    }
  }

  Future<DownloadedFile> download(CareerDocument document) {
    return api.download(
      document.pdfPath,
      filename: document.filename,
    );
  }

  Future<void> _syncEvidence() async {
    final linkedInReady = await careerProfileRepository.ensureSynced();
    if (careerProfileRepository.hasProfile && !linkedInReady) {
      throw const ApiException(
        'Your LinkedIn evidence could not be loaded into this session.',
      );
    }

    final githubReady = await githubProfileRepository.ensureSynced();
    if (githubProfileRepository.hasProfile && !githubReady) {
      throw const ApiException(
        'Your GitHub projects could not be loaded into this session.',
      );
    }

    await toneProfileRepository.ensureSynced();
    final resumeReady = await currentCvRepository.ensureSynced();
    if (currentCvRepository.hasProfile && !resumeReady) {
      throw const ApiException(
        'Your current resume could not be loaded into this session.',
      );
    }
  }

  void clear() {
    _documents.clear();
    _busy.clear();
    error = null;
    notifyListeners();
  }

  static String _key(String jobId, String kind) => '$jobId::$kind';
}
