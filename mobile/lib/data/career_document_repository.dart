import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'api_client.dart';
import 'career_profile_repository.dart';
import 'current_cv_repository.dart';
import 'github_profile_repository.dart';
import 'models.dart';
import 'tone_profile_repository.dart';

class CareerDocumentHistory {
  final JobOpportunity job;
  final String kind;
  final List<CareerDocument> versions;

  const CareerDocumentHistory({
    required this.job,
    required this.kind,
    required this.versions,
  });
}

class CareerDocumentRepository extends ChangeNotifier {
  final ApiClient api;
  final CareerProfileRepository careerProfileRepository;
  final GithubProfileRepository githubProfileRepository;
  final CurrentCvRepository currentCvRepository;
  final ToneProfileRepository toneProfileRepository;

  final Map<String, CareerDocument> _documents = {};
  final Map<String, JobOpportunity> _jobs = {};
  final Map<String, List<CareerDocument>> _history = {};
  final Map<String, DownloadedFile> _downloaded = {};
  final Set<String> _busy = {};
  bool _historyLoaded = false;
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

  List<CareerDocumentHistory> get histories {
    final values = <CareerDocumentHistory>[];
    for (final entry in _history.entries) {
      final job = _jobs[entry.key];
      if (job == null || entry.value.isEmpty) continue;
      final versions = [...entry.value]
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      values.add(
        CareerDocumentHistory(
          job: job,
          kind: versions.first.kind,
          versions: List.unmodifiable(versions),
        ),
      );
    }
    values.sort(
      (a, b) => b.versions.first.updatedAt.compareTo(
        a.versions.first.updatedAt,
      ),
    );
    return List.unmodifiable(values);
  }

  Future<void> loadHistory({bool force = false}) async {
    if (_historyLoaded && !force) return;
    try {
      final json = await api.get('/v1/career/documents');
      for (final raw in json['documents'] as List? ?? const []) {
        if (raw is! Map) continue;
        final item = Map<String, dynamic>.from(raw);
        final jobJson = item['job'];
        if (jobJson is! Map) continue;
        _register(
          JobOpportunity.fromDocumentJson(
            Map<String, dynamic>.from(jobJson),
          ),
          CareerDocument.fromJson(item),
        );
      }
      _historyLoaded = true;
      notifyListeners();
    } catch (_) {
      // The library remains usable with documents generated in this runtime.
    }
  }

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
      _register(job, document);
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
      _register(job, updated);
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

  Future<DownloadedFile> download(CareerDocument document) async {
    final cacheKey = _downloadKey(document);
    final cached = _downloaded[cacheKey];
    if (cached != null && await File(cached.path).exists()) {
      return cached;
    }
    late final DownloadedFile downloaded;
    try {
      downloaded = await api.download(
        document.pdfPath,
        filename: document.filename,
        timeout: const Duration(seconds: 75),
      );
    } on TimeoutException {
      throw const ApiException(
        'The PDF took too long to open. The backend may still be waking up; '
        'try once more.',
      );
    }
    _downloaded[cacheKey] = downloaded;
    return downloaded;
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
    _jobs.clear();
    _history.clear();
    _downloaded.clear();
    _historyLoaded = false;
    _busy.clear();
    error = null;
    notifyListeners();
  }

  void invalidateCurrent() {
    _documents.clear();
    _busy.clear();
    error = null;
    notifyListeners();
  }

  static String _key(String jobId, String kind) => '$jobId::$kind';

  static String _downloadKey(CareerDocument document) =>
      '${document.id}::${document.version}';

  void _register(JobOpportunity job, CareerDocument document) {
    final key = _key(job.id, document.kind);
    final current = _documents[key];
    if (current == null || document.updatedAt.isAfter(current.updatedAt)) {
      _documents[key] = document;
    }
    _jobs[document.id] = job;
    final versions = _history.putIfAbsent(document.id, () => []);
    versions.removeWhere(
      (value) => value.id == document.id && value.version == document.version,
    );
    versions.add(document);
  }
}
