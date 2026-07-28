import 'package:flutter/foundation.dart';

import 'api_client.dart';
import 'career_profile_repository.dart';
import 'current_cv_repository.dart';
import 'email_models.dart';
import 'github_profile_repository.dart';
import 'models.dart';
import 'practice_repository.dart';
import 'session_storage.dart';
import 'tone_profile_repository.dart';

class AuthRepository extends ChangeNotifier {
  final ApiClient api;
  final SessionStorage storage;

  bool initialized = false;
  bool isAuthenticated = false;
  bool isBusy = false;
  String? error;
  SessionInfo? session;

  AuthRepository({required this.api, required this.storage});

  Future<void> restoreSession() async {
    final token = await storage.readToken();
    if (token != null) {
      api.accessToken = token;
      try {
        session = SessionInfo.fromJson(await api.get('/v1/auth/session'));
        isAuthenticated = true;
      } on ApiException {
        await storage.clearToken();
        api.accessToken = null;
      }
    }
    initialized = true;
    notifyListeners();
  }

  Future<bool> signIn(
    String username,
    String password,
    int enrollmentYear,
    String institution,
  ) async {
    isBusy = true;
    error = null;
    notifyListeners();
    try {
      final json = await api.post(
        '/v1/auth/login',
        authenticated: false,
        body: {
          'username': username.trim(),
          'password': password,
          'enrollment_year': enrollmentYear,
          'institution': institution,
        },
      );
      final token = json['access_token'] as String;
      api.accessToken = token;
      await storage.saveToken(token);
      session = SessionInfo.fromJson(json);
      isAuthenticated = true;
      return true;
    } on ApiException catch (exception) {
      error = exception.message;
      return false;
    } catch (_) {
      error =
          'Cannot reach CareerLoop. Check the backend address and try again.';
      return false;
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    try {
      await api.post('/v1/auth/logout');
    } catch (_) {
      // A local logout must still succeed if the server session already expired.
    }
    await storage.clearToken();
    api.accessToken = null;
    isAuthenticated = false;
    session = null;
    notifyListeners();
  }
}

class AcademicRepository extends ChangeNotifier {
  final ApiClient api;

  AdvisoryContext? context;
  List<String> seasons = const [];
  List<String> transcriptYears = const [];
  String? selectedTranscriptYear;
  List<CourseSummary> courses = const [];
  Transcript? transcript;
  TranscriptWindow? fullTranscript;
  String? fullTranscriptError;
  final Map<String, CourseGrades> grades = {};
  bool loadingDashboard = false;
  bool loadingTranscript = false;
  bool updatingAdvisorySemester = false;
  final Set<String> loadingCourses = {};
  String? error;

  AcademicRepository({required this.api});

  Future<void> loadDashboard({bool force = false}) async {
    if (loadingDashboard) return;
    if (!force &&
        context != null &&
        seasons.isNotEmpty &&
        transcriptYears.isNotEmpty &&
        courses.isNotEmpty &&
        transcript != null &&
        fullTranscript != null) {
      return;
    }
    loadingDashboard = true;
    error = null;
    fullTranscriptError = null;
    notifyListeners();
    try {
      context = AdvisoryContext.fromJson(
        await api.get('/v1/academic/context'),
      );
      final seasonJson = await api.get('/v1/academic/seasons');
      seasons = List<String>.from(
        seasonJson['seasons'] as List? ?? const [],
      );
      final yearJson = await api.get('/v1/academic/transcript-years');
      transcriptYears = List<String>.from(
        yearJson['years'] as List? ?? const [],
      );
      selectedTranscriptYear ??= context!.transcriptYear;
      if (!transcriptYears.contains(selectedTranscriptYear) &&
          transcriptYears.isNotEmpty) {
        selectedTranscriptYear = transcriptYears.first;
      }
      final courseJson = await api.get(
        '/v1/academic/courses',
        query: {'season': context!.currentSeason},
      );
      courses = List<String>.from(courseJson['courses'] as List? ?? const [])
          .map(CourseSummary.fromLabel)
          .toList();
      transcript = Transcript.fromJson(
        await api.get(
          '/v1/academic/transcript',
          query: {'year': selectedTranscriptYear},
        ),
      );
      try {
        fullTranscript = TranscriptWindow.fromJson(
          await api.get('/v1/academic/transcript-window'),
        );
      } on ApiException catch (exception) {
        fullTranscriptError = exception.message;
      } catch (_) {
        fullTranscriptError =
            'The complete enrollment transcript could not be loaded.';
      }
    } on ApiException catch (exception) {
      error = exception.message;
    } catch (_) {
      error = 'Academic data could not be loaded.';
    } finally {
      loadingDashboard = false;
      notifyListeners();
    }
  }

  Future<bool> selectAdvisorySemester(String season) async {
    if (updatingAdvisorySemester) return false;
    if (context?.currentSeason == season) return true;
    var contextChanged = false;
    updatingAdvisorySemester = true;
    error = null;
    notifyListeners();
    try {
      context = AdvisoryContext.fromJson(
        await api.post(
          '/v1/academic/advisory-semester',
          body: {'current_season': season},
        ),
      );
      contextChanged = true;
      courses = const [];
      grades.clear();
      final courseJson = await api.get(
        '/v1/academic/courses',
        query: {'season': context!.currentSeason},
      );
      courses = List<String>.from(courseJson['courses'] as List? ?? const [])
          .map(CourseSummary.fromLabel)
          .toList();
      return true;
    } on ApiException catch (exception) {
      if (exception.statusCode == 404 || exception.statusCode == 405) {
        error = 'The deployed backend is an older version. Redeploy the '
            'CareerLoop API, then try changing the semester again.';
      } else {
        error = exception.message;
      }
      return contextChanged;
    } catch (_) {
      error = contextChanged
          ? 'The semester changed, but its courses could not be loaded yet.'
          : 'The advisory semester could not be changed.';
      return contextChanged;
    } finally {
      updatingAdvisorySemester = false;
      notifyListeners();
    }
  }

  Future<bool> loadTranscriptYear(String year) async {
    if (loadingTranscript) return false;
    if (transcript?.year == year) {
      selectedTranscriptYear = year;
      notifyListeners();
      return true;
    }
    final previousYear = selectedTranscriptYear;
    loadingTranscript = true;
    selectedTranscriptYear = year;
    error = null;
    notifyListeners();
    try {
      transcript = Transcript.fromJson(
        await api.get(
          '/v1/academic/transcript',
          query: {'year': year},
        ),
      );
      selectedTranscriptYear = transcript!.year;
      return true;
    } on ApiException catch (exception) {
      selectedTranscriptYear = previousYear;
      error = exception.message;
      return false;
    } catch (_) {
      selectedTranscriptYear = previousYear;
      error = 'Transcript year $year could not be loaded.';
      return false;
    } finally {
      loadingTranscript = false;
      notifyListeners();
    }
  }

  Future<CourseGrades?> loadCourseGrades(
    CourseSummary course, {
    bool force = false,
  }) async {
    if (!force && grades.containsKey(course.code)) {
      return grades[course.code];
    }
    loadingCourses.add(course.code);
    error = null;
    notifyListeners();
    try {
      final result = CourseGrades.fromJson(
        await api.get(
          '/v1/academic/course-grades',
          query: {'course': course.code},
        ),
      );
      grades[course.code] = result;
      return result;
    } on ApiException catch (exception) {
      error = exception.message;
      return null;
    } catch (_) {
      error = 'Grades for ${course.code} could not be loaded.';
      return null;
    } finally {
      loadingCourses.remove(course.code);
      notifyListeners();
    }
  }

  Future<void> clearPortalCache() async {
    await api.post('/v1/academic/cache/clear');
    context = null;
    seasons = const [];
    transcriptYears = const [];
    selectedTranscriptYear = null;
    courses = const [];
    transcript = null;
    fullTranscript = null;
    fullTranscriptError = null;
    grades.clear();
    notifyListeners();
  }

  void clearLocal() {
    context = null;
    seasons = const [];
    transcriptYears = const [];
    selectedTranscriptYear = null;
    courses = const [];
    transcript = null;
    fullTranscript = null;
    fullTranscriptError = null;
    grades.clear();
    error = null;
    notifyListeners();
  }
}

class CmsRepository extends ChangeNotifier {
  final ApiClient api;

  List<CmsCourse> courses = const [];
  final Map<String, CmsCourseContent> content = {};
  bool loadingCourses = false;
  final Set<String> loadingContent = {};
  String? season;
  String? error;
  int _courseRequest = 0;

  CmsRepository({required this.api});

  Future<void> loadCourses({
    bool force = false,
    String? season,
  }) async {
    final requestedSeason = season?.trim();
    if (!force &&
        courses.isNotEmpty &&
        (requestedSeason == null || requestedSeason == this.season)) {
      return;
    }
    final request = ++_courseRequest;
    loadingCourses = true;
    error = null;
    notifyListeners();
    try {
      final json = await api.get(
        '/v1/cms/courses',
        query: {
          if (force) 'refresh': 'true',
          if (requestedSeason != null) 'season': requestedSeason,
        },
      );
      final resolvedSeason = json['season'] as String? ?? requestedSeason;
      final newCourses = (json['courses'] as List? ?? const [])
          .map((item) => CmsCourse.fromJson(
                Map<String, dynamic>.from(item as Map),
              ))
          .toList();
      if (request != _courseRequest) return;
      if (this.season != null && this.season != resolvedSeason) {
        content.clear();
      }
      this.season = resolvedSeason;
      courses = newCourses;
    } on ApiException catch (exception) {
      if (request != _courseRequest) return;
      error = exception.message;
    } catch (_) {
      if (request != _courseRequest) return;
      error = 'The CMS learning library could not be loaded.';
    } finally {
      if (request == _courseRequest) {
        loadingCourses = false;
        notifyListeners();
      }
    }
  }

  Future<CmsCourseContent?> loadCourseContent(
    String courseId, {
    bool force = false,
  }) async {
    if (!force && content.containsKey(courseId)) return content[courseId];
    if (loadingContent.contains(courseId)) return null;
    loadingContent.add(courseId);
    error = null;
    notifyListeners();
    try {
      final result = CmsCourseContent.fromJson(
        await api.get('/v1/cms/courses/$courseId/content'),
      );
      content[courseId] = result;
      final index = courses.indexWhere((course) => course.id == courseId);
      if (index >= 0) {
        courses = [
          ...courses.take(index),
          result.course,
          ...courses.skip(index + 1),
        ];
      }
      return result;
    } on ApiException catch (exception) {
      error = exception.message;
      return null;
    } catch (_) {
      error = 'The CMS course resources could not be loaded.';
      return null;
    } finally {
      loadingContent.remove(courseId);
      notifyListeners();
    }
  }

  Future<DownloadedFile> downloadResource(CmsResource resource) {
    return api.download(
      resource.downloadPath,
      filename: resource.filename,
    );
  }

  void clearLocal() {
    courses = const [];
    content.clear();
    loadingContent.clear();
    _courseRequest++;
    season = null;
    error = null;
    notifyListeners();
  }
}

class AdvisorRepository extends ChangeNotifier {
  final ApiClient api;
  final PracticeRepository practiceRepository;
  final CareerProfileRepository careerProfileRepository;
  final GithubProfileRepository githubProfileRepository;
  final CurrentCvRepository currentCvRepository;
  final ToneProfileRepository toneProfileRepository;

  final List<ChatMessage> messages = [];
  bool isSending = false;
  String? error;

  AdvisorRepository({
    required this.api,
    required this.practiceRepository,
    required this.careerProfileRepository,
    required this.githubProfileRepository,
    required this.currentCvRepository,
    required this.toneProfileRepository,
  });

  Future<ChatMessage?> send(String text) {
    return sendContextual(visibleText: text, agentText: text);
  }

  Future<ChatMessage?> sendContextual({
    required String visibleText,
    required String agentText,
  }) async {
    final visible = visibleText.trim();
    final agent = agentText.trim();
    if (visible.isEmpty || agent.isEmpty || isSending) return null;
    messages.add(
      ChatMessage(
        isUser: true,
        text: visible,
        createdAt: DateTime.now(),
      ),
    );
    isSending = true;
    error = null;
    notifyListeners();
    try {
      await careerProfileRepository.ensureSynced();
      await githubProfileRepository.ensureSynced();
      await toneProfileRepository.ensureSynced();
      final resumeReady = await currentCvRepository.ensureSynced();
      if (currentCvRepository.hasProfile && !resumeReady) {
        throw const ApiException(
          'Your resume could not be loaded into this session. Try replacing '
          'the PDF or signing in again.',
        );
      }
      final json = await api.post('/v1/chat', body: {'message': agent});
      final practiceJson = json['practice_set'];
      final practiceSet = practiceJson is Map
          ? PracticeSet.fromJson(Map<String, dynamic>.from(practiceJson))
          : null;
      if (practiceSet != null) {
        await practiceRepository.save(practiceSet);
      }
      final emailJson = json['email_draft'];
      final emailDraft = emailJson is Map
          ? GeneralEmailDraft.fromJson(
              Map<String, dynamic>.from(emailJson),
            )
          : null;
      final response = ChatMessage(
        isUser: false,
        text: json['answer'] as String? ?? 'No response was returned.',
        createdAt: DateTime.now(),
        sources: List<String>.from(json['sources'] as List? ?? const []),
        tools: (json['tools'] as List? ?? const [])
            .map((item) =>
                ToolActivity.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList(),
        practiceSet: practiceSet,
        emailDraft: emailDraft,
      );
      messages.add(response);
      return response;
    } on ApiException catch (exception) {
      error = exception.message;
      return null;
    } catch (_) {
      error = 'The advisor could not be reached.';
      return null;
    } finally {
      isSending = false;
      notifyListeners();
    }
  }

  Future<void> reset() async {
    try {
      await api.post('/v1/chat/reset');
    } finally {
      messages.clear();
      error = null;
      notifyListeners();
    }
  }

  void clearLocal() {
    messages.clear();
    error = null;
    notifyListeners();
  }
}

class NotionExportResult {
  final String pageId;
  final String pageUrl;
  final String title;

  const NotionExportResult({
    required this.pageId,
    required this.pageUrl,
    required this.title,
  });
}

class NotionRepository extends ChangeNotifier {
  final ApiClient api;

  bool available = false;
  bool connected = false;
  bool loading = false;
  bool exporting = false;
  String mode = 'disabled';
  String? workspaceName;
  String? configurationMessage;
  String? error;

  NotionRepository({required this.api});

  Future<bool> refreshStatus() async {
    if (loading) return connected;
    loading = true;
    error = null;
    notifyListeners();
    try {
      final json = await api.get('/v1/integrations/notion/status');
      available = json['available'] as bool? ?? false;
      connected = json['connected'] as bool? ?? false;
      mode = json['mode'] as String? ?? 'disabled';
      workspaceName = json['workspace_name'] as String?;
      configurationMessage = json['configuration_message'] as String?;
      return connected;
    } on ApiException catch (exception) {
      error = exception.message;
      return false;
    } catch (_) {
      error = 'The Notion connection could not be checked.';
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<Uri?> beginConnection() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final json = await api.post('/v1/integrations/notion/connect');
      connected = json['connected'] as bool? ?? false;
      final authorizationUrl = json['authorization_url'] as String?;
      return authorizationUrl == null ? null : Uri.tryParse(authorizationUrl);
    } on ApiException catch (exception) {
      error = exception.message;
      return null;
    } catch (_) {
      error = 'Notion authorization could not be started.';
      return null;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<NotionExportResult?> exportResponse({
    required String title,
    required String markdown,
    required List<String> sources,
  }) async {
    if (exporting) return null;
    exporting = true;
    error = null;
    notifyListeners();
    try {
      final json = await api.post(
        '/v1/integrations/notion/export',
        body: {
          'title': title,
          'markdown': markdown,
          'sources': sources,
        },
      );
      return NotionExportResult(
        pageId: json['page_id'] as String? ?? '',
        pageUrl: json['page_url'] as String? ?? '',
        title: json['title'] as String? ?? title,
      );
    } on ApiException catch (exception) {
      error = exception.message;
      return null;
    } catch (_) {
      error = 'The response could not be exported to Notion.';
      return null;
    } finally {
      exporting = false;
      notifyListeners();
    }
  }

  void clearLocal() {
    available = false;
    connected = false;
    mode = 'disabled';
    workspaceName = null;
    configurationMessage = null;
    error = null;
    notifyListeners();
  }
}
