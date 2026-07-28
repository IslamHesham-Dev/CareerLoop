class SessionInfo {
  final String institution;
  final String currentSeason;
  final String advisoryYear;
  final int enrollmentYear;
  final List<String> transcriptYears;
  final int expiresInSeconds;
  final bool cmsConnected;
  final String? cmsMessage;

  const SessionInfo({
    required this.institution,
    required this.currentSeason,
    required this.advisoryYear,
    required this.enrollmentYear,
    required this.transcriptYears,
    required this.expiresInSeconds,
    required this.cmsConnected,
    required this.cmsMessage,
  });

  factory SessionInfo.fromJson(Map<String, dynamic> json) => SessionInfo(
        institution: json['institution'] as String? ?? 'giu',
        currentSeason: json['current_season'] as String? ?? 'Winter 2024',
        advisoryYear: json['advisory_year'] as String? ?? '2024-2025',
        enrollmentYear: json['enrollment_year'] as int? ?? 2021,
        transcriptYears:
            List<String>.from(json['transcript_years'] as List? ?? const []),
        expiresInSeconds: json['expires_in_seconds'] as int? ?? 0,
        cmsConnected: json['cms_connected'] as bool? ?? false,
        cmsMessage: json['cms_message'] as String?,
      );

  String get universityLabel => institution.toUpperCase();
}

class AdvisoryContext {
  final String currentSeason;
  final String transcriptYear;
  final int enrollmentYear;
  final List<String> transcriptYears;
  final List<String> dataSources;
  final List<String> excludedSources;

  const AdvisoryContext({
    required this.currentSeason,
    required this.transcriptYear,
    required this.enrollmentYear,
    required this.transcriptYears,
    required this.dataSources,
    required this.excludedSources,
  });

  factory AdvisoryContext.fromJson(Map<String, dynamic> json) =>
      AdvisoryContext(
        currentSeason:
            json['simulated_current_season'] as String? ?? 'Winter 2024',
        transcriptYear: json['transcript_year'] as String? ?? '2024-2025',
        enrollmentYear: json['enrollment_year'] as int? ?? 2021,
        transcriptYears:
            List<String>.from(json['transcript_years'] as List? ?? const []),
        dataSources:
            List<String>.from(json['data_sources'] as List? ?? const []),
        excludedSources:
            List<String>.from(json['excluded_sources'] as List? ?? const []),
      );
}

class CourseSummary {
  final String label;
  final String code;
  final String title;
  final String track;

  const CourseSummary({
    required this.label,
    required this.code,
    required this.title,
    required this.track,
  });

  factory CourseSummary.fromLabel(String label) {
    final match = RegExp(r'\b[A-Z]{2,6}\d{3}\b').firstMatch(label);
    final code = match?.group(0) ?? 'COURSE';
    final afterCode = match == null
        ? label
        : label
            .substring(match.end)
            .trim()
            .replaceFirst(RegExp(r'^[-–]\s*'), '');
    final beforeCode =
        match == null ? '' : label.substring(0, match.start).trim();
    final track = beforeCode
        .split(' - ')
        .where((part) => part.trim().isNotEmpty)
        .lastOrNull;
    return CourseSummary(
      label: label,
      code: code,
      title: afterCode.isEmpty ? label : afterCode,
      track: track ?? 'University',
    );
  }
}

class Assessment {
  final String assessment;
  final String element;
  final String grade;
  final String evaluator;

  const Assessment({
    required this.assessment,
    required this.element,
    required this.grade,
    required this.evaluator,
  });

  factory Assessment.fromJson(Map<String, dynamic> json) => Assessment(
        assessment: json['assessment'] as String? ?? '',
        element: json['element'] as String? ?? '',
        grade: json['grade'] as String? ?? '',
        evaluator: json['evaluator'] as String? ?? '',
      );

  double? get ratio {
    final match =
        RegExp(r'(-?\d+(?:\.\d+)?)\s*/\s*(-?\d+(?:\.\d+)?)').firstMatch(grade);
    if (match == null) return null;
    final earned = double.tryParse(match.group(1)!);
    final maximum = double.tryParse(match.group(2)!);
    if (earned == null || maximum == null || maximum == 0) return null;
    return (earned / maximum).clamp(0, 1);
  }
}

class CourseGrades {
  final String season;
  final String course;
  final List<Assessment> assessments;
  final Map<String, String> midtermResults;

  const CourseGrades({
    required this.season,
    required this.course,
    required this.assessments,
    required this.midtermResults,
  });

  factory CourseGrades.fromJson(Map<String, dynamic> json) => CourseGrades(
        season: json['season'] as String? ?? '',
        course: json['course'] as String? ?? '',
        assessments: (json['assessments'] as List? ?? const [])
            .map((item) =>
                Assessment.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList(),
        midtermResults: Map<String, String>.from(
          (json['midterm_results'] as Map? ?? const {})
              .map((key, value) => MapEntry('$key', '$value')),
        ),
      );

  double? get averageRatio {
    final values =
        assessments.map((item) => item.ratio).whereType<double>().toList();
    if (values.isEmpty) return null;
    return values.reduce((a, b) => a + b) / values.length;
  }
}

class TranscriptCourse {
  final String semester;
  final String course;
  final String grade;
  final String numeric;
  final String hours;
  final String group;

  const TranscriptCourse({
    required this.semester,
    required this.course,
    required this.grade,
    required this.numeric,
    required this.hours,
    required this.group,
  });

  factory TranscriptCourse.fromJson(Map<String, dynamic> json) =>
      TranscriptCourse(
        semester: json['semester'] as String? ?? '',
        course: json['course'] as String? ?? '',
        grade: json['grade'] as String? ?? '',
        numeric: json['numeric'] as String? ?? '',
        hours: json['hours'] as String? ?? '',
        group: json['group'] as String? ?? '',
      );

  double? get numericGpa {
    final match = RegExp(r'-?\d+(?:[.,]\d+)?').firstMatch(numeric);
    if (match == null) return null;
    return double.tryParse(match.group(0)!.replaceAll(',', '.'));
  }

  GradeBand? get mappedGrade => GiuGradeScale.forGpa(numericGpa);

  String get displayGrade =>
      grade.isNotEmpty ? grade : mappedGrade?.letter ?? '';

  String get gpaWithGrade {
    if (numeric.isEmpty) return displayGrade;
    return displayGrade.isEmpty ? numeric : '$numeric ($displayGrade)';
  }
}

class GradeBand {
  final double minimum;
  final double maximum;
  final String letter;
  final String gpaRange;

  const GradeBand({
    required this.minimum,
    required this.maximum,
    required this.letter,
    required this.gpaRange,
  });

  String get percentageRange =>
      '${minimum.toStringAsFixed(minimum == minimum.roundToDouble() ? 0 : 1)}'
      '–'
      '${maximum.toStringAsFixed(maximum == maximum.roundToDouble() ? 0 : 1)}';
}

abstract final class GiuGradeScale {
  static const bands = <GradeBand>[
    GradeBand(
      minimum: 94,
      maximum: 100,
      letter: 'A+',
      gpaRange: '0.70–0.99',
    ),
    GradeBand(
      minimum: 90,
      maximum: 93.9,
      letter: 'A',
      gpaRange: '1.00–1.29',
    ),
    GradeBand(
      minimum: 86,
      maximum: 89.9,
      letter: 'A-',
      gpaRange: '1.30–1.69',
    ),
    GradeBand(
      minimum: 82,
      maximum: 85.9,
      letter: 'B+',
      gpaRange: '1.70–1.99',
    ),
    GradeBand(
      minimum: 78,
      maximum: 81.9,
      letter: 'B',
      gpaRange: '2.00–2.29',
    ),
    GradeBand(
      minimum: 74,
      maximum: 77.9,
      letter: 'B-',
      gpaRange: '2.30–2.69',
    ),
    GradeBand(
      minimum: 70,
      maximum: 73.9,
      letter: 'C+',
      gpaRange: '2.70–2.99',
    ),
    GradeBand(
      minimum: 65,
      maximum: 69.9,
      letter: 'C',
      gpaRange: '3.00–3.29',
    ),
    GradeBand(
      minimum: 60,
      maximum: 64.9,
      letter: 'C-',
      gpaRange: '3.30–3.69',
    ),
    GradeBand(
      minimum: 55,
      maximum: 59.9,
      letter: 'D+',
      gpaRange: '3.70–3.99',
    ),
    GradeBand(
      minimum: 50,
      maximum: 54.9,
      letter: 'D',
      gpaRange: '4.00–4.99',
    ),
    GradeBand(
      minimum: 0,
      maximum: 49.9,
      letter: 'F',
      gpaRange: '5.00–6.00',
    ),
  ];

  static GradeBand? forPercentage(double? percentage) {
    if (percentage == null || percentage < 0 || percentage > 100) return null;
    for (final band in bands) {
      if (percentage >= band.minimum) {
        return band;
      }
    }
    return null;
  }

  static GradeBand? forGpa(double? gpa) {
    if (gpa == null || gpa < .7 || gpa > 6) return null;
    for (final band in bands) {
      final bounds = band.gpaRange.split('–');
      final minimum = double.tryParse(bounds.first);
      final maximum = double.tryParse(bounds.last);
      if (minimum != null &&
          maximum != null &&
          gpa >= minimum &&
          gpa <= maximum) {
        return band;
      }
    }
    return null;
  }
}

class Transcript {
  final String year;
  final String? cumulativeGpa;
  final List<TranscriptCourse> courses;

  const Transcript({
    required this.year,
    required this.cumulativeGpa,
    required this.courses,
  });

  factory Transcript.fromJson(Map<String, dynamic> json) => Transcript(
        year: json['year'] as String? ?? '',
        cumulativeGpa: json['cumulative_gpa'] as String?,
        courses: (json['courses'] as List? ?? const [])
            .map((item) => TranscriptCourse.fromJson(
                Map<String, dynamic>.from(item as Map)))
            .toList(),
      );

  Map<String, List<TranscriptCourse>> get bySemester {
    final grouped = <String, List<TranscriptCourse>>{};
    for (final course in courses) {
      grouped.putIfAbsent(course.semester, () => []).add(course);
    }
    return grouped;
  }

  GradeBand? get cumulativeGrade {
    final match = RegExp(r'-?\d+(?:[.,]\d+)?').firstMatch(cumulativeGpa ?? '');
    if (match == null) return null;
    final value = double.tryParse(match.group(0)!.replaceAll(',', '.'));
    return GiuGradeScale.forGpa(value);
  }

  String get cumulativeGpaWithGrade {
    final value = cumulativeGpa;
    if (value == null || value.isEmpty) return 'Not displayed';
    final letter = cumulativeGrade?.letter;
    return letter == null ? value : '$value ($letter)';
  }
}

class CmsCourse {
  final String id;
  final String code;
  final String title;
  final String cmsLabel;
  final int? resourceCount;
  final String season;
  final int? seasonId;
  final bool? active;
  final bool hasSupplementalVideos;
  final int videoCount;
  final int transcribedCount;

  const CmsCourse({
    required this.id,
    required this.code,
    required this.title,
    required this.cmsLabel,
    required this.resourceCount,
    required this.season,
    required this.seasonId,
    required this.active,
    required this.hasSupplementalVideos,
    required this.videoCount,
    required this.transcribedCount,
  });

  factory CmsCourse.fromJson(Map<String, dynamic> json) => CmsCourse(
        id: json['id'] as String? ?? '',
        code: json['code'] as String? ?? 'CMS',
        title: json['title'] as String? ?? '',
        cmsLabel: json['cms_label'] as String? ?? '',
        resourceCount: (json['resource_count'] as num?)?.toInt(),
        season: json['season'] as String? ?? '',
        seasonId: (json['season_id'] as num?)?.toInt(),
        active: json['active'] as bool?,
        hasSupplementalVideos:
            json['has_supplemental_videos'] as bool? ?? false,
        videoCount: (json['video_count'] as num?)?.toInt() ?? 0,
        transcribedCount: (json['transcribed_count'] as num?)?.toInt() ?? 0,
      );
}

class CmsResource {
  final String id;
  final String title;
  final String subtitle;
  final String contentType;
  final String fileExtension;
  final int? week;
  final String? weekLabel;
  final bool isVod;
  final String downloadPath;

  const CmsResource({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.contentType,
    required this.fileExtension,
    required this.week,
    required this.weekLabel,
    required this.isVod,
    required this.downloadPath,
  });

  factory CmsResource.fromJson(Map<String, dynamic> json) => CmsResource(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? 'CMS resource',
        subtitle: json['subtitle'] as String? ?? '',
        contentType: json['content_type'] as String? ?? 'Resource',
        fileExtension: json['file_extension'] as String? ?? '',
        week: (json['week'] as num?)?.toInt(),
        weekLabel: json['week_label'] as String?,
        isVod: json['is_vod'] as bool? ?? false,
        downloadPath: json['download_path'] as String? ?? '',
      );

  String get filename {
    final extension =
        fileExtension.isEmpty ? '' : '.${fileExtension.toLowerCase()}';
    return '$title$extension';
  }
}

class CmsVideo {
  final String id;
  final String title;
  final String contentType;
  final String driveUrl;
  final String collection;
  final String transcriptStatus;
  final int? sizeBytes;

  const CmsVideo({
    required this.id,
    required this.title,
    required this.contentType,
    required this.driveUrl,
    required this.collection,
    required this.transcriptStatus,
    required this.sizeBytes,
  });

  factory CmsVideo.fromJson(Map<String, dynamic> json) => CmsVideo(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        contentType: json['content_type'] as String? ?? 'video',
        driveUrl: json['drive_url'] as String? ?? '',
        collection: json['collection'] as String? ?? '',
        transcriptStatus: json['transcript_status'] as String? ?? 'pending',
        sizeBytes: (json['size_bytes'] as num?)?.toInt(),
      );

  String get sizeLabel {
    final bytes = sizeBytes;
    if (bytes == null || bytes <= 0) return '';
    final megabytes = bytes / (1024 * 1024);
    return '${megabytes.toStringAsFixed(megabytes >= 100 ? 0 : 1)} MB';
  }
}

class CmsCourseContent {
  final CmsCourse course;
  final List<CmsResource> cmsResources;
  final List<CmsVideo> availableVideos;

  const CmsCourseContent({
    required this.course,
    required this.cmsResources,
    required this.availableVideos,
  });

  factory CmsCourseContent.fromJson(Map<String, dynamic> json) =>
      CmsCourseContent(
        course: CmsCourse.fromJson(
          Map<String, dynamic>.from(json['course'] as Map),
        ),
        cmsResources: (json['cms_resources'] as List? ?? const [])
            .map((item) => CmsResource.fromJson(
                  Map<String, dynamic>.from(item as Map),
                ))
            .toList(),
        availableVideos: (json['available_videos'] as List? ?? const [])
            .map((item) => CmsVideo.fromJson(
                  Map<String, dynamic>.from(item as Map),
                ))
            .toList(),
      );
}

class ToolActivity {
  final String name;
  final String status;

  const ToolActivity({required this.name, required this.status});

  factory ToolActivity.fromJson(Map<String, dynamic> json) => ToolActivity(
        name: json['name'] as String? ?? 'portal_tool',
        status: json['status'] as String? ?? 'completed',
      );
}

class OpportunityEvidence {
  final bool academicTranscript;
  final bool linkedInPdf;
  final bool github;
  final bool resume;

  const OpportunityEvidence({
    required this.academicTranscript,
    required this.linkedInPdf,
    required this.github,
    required this.resume,
  });

  factory OpportunityEvidence.fromJson(Map<String, dynamic> json) =>
      OpportunityEvidence(
        academicTranscript: json['academic_transcript'] as bool? ?? false,
        linkedInPdf: json['linkedin_pdf'] as bool? ?? false,
        github: json['github'] as bool? ?? false,
        resume: json['resume'] as bool? ?? false,
      );
}

class JobOpportunity {
  final String id;
  final String company;
  final String title;
  final String location;
  final List<String> locations;
  final Uri url;
  final String source;
  final String? category;
  final DateTime? postedAt;
  final DateTime? updatedAt;
  final String? sponsorship;
  final List<String> degrees;
  final Uri? companyProfileUrl;
  final Uri? companyLogoUrl;
  final bool active;
  final String roleFamily;
  final int matchScore;
  final List<String> matchReasons;
  final List<String> keywordMatches;
  final List<String> profileSkillMatches;
  final List<String> inferredSkillGaps;
  final List<String> recommendedCourseIds;

  const JobOpportunity({
    required this.id,
    required this.company,
    required this.title,
    required this.location,
    this.locations = const [],
    required this.url,
    required this.source,
    this.category,
    this.postedAt,
    this.updatedAt,
    this.sponsorship,
    this.degrees = const [],
    this.companyProfileUrl,
    this.companyLogoUrl,
    this.active = true,
    required this.roleFamily,
    required this.matchScore,
    required this.matchReasons,
    required this.keywordMatches,
    required this.profileSkillMatches,
    required this.inferredSkillGaps,
    required this.recommendedCourseIds,
  });

  factory JobOpportunity.fromJson(Map<String, dynamic> json) => JobOpportunity(
        id: json['id'] as String? ?? '',
        company: json['company'] as String? ?? 'Company',
        title: json['title'] as String? ?? 'Open position',
        location: json['location'] as String? ?? 'Location not specified',
        locations: List<String>.from(
          json['locations'] as List? ?? const [],
        ),
        url: Uri.tryParse(json['url'] as String? ?? '') ?? Uri(),
        source: json['source'] as String? ?? 'Swelist',
        category: json['category'] as String?,
        postedAt: DateTime.tryParse(json['posted_at'] as String? ?? ''),
        updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? ''),
        sponsorship: json['sponsorship'] as String?,
        degrees: List<String>.from(json['degrees'] as List? ?? const []),
        companyProfileUrl: Uri.tryParse(
          json['company_profile_url'] as String? ?? '',
        ),
        companyLogoUrl: Uri.tryParse(
          json['company_logo_url'] as String? ?? '',
        ),
        active: json['active'] as bool? ?? true,
        roleFamily: json['role_family'] as String? ?? 'general',
        matchScore: json['match_score'] as int? ?? 0,
        matchReasons:
            List<String>.from(json['match_reasons'] as List? ?? const []),
        keywordMatches:
            List<String>.from(json['keyword_matches'] as List? ?? const []),
        profileSkillMatches: List<String>.from(
          json['profile_skill_matches'] as List? ?? const [],
        ),
        inferredSkillGaps: List<String>.from(
          json['inferred_skill_gaps'] as List? ?? const [],
        ),
        recommendedCourseIds: List<String>.from(
          json['recommended_course_ids'] as List? ?? const [],
        ),
      );

  Map<String, dynamic> toDocumentJson() => {
        'id': id,
        'company': company,
        'title': title,
        'location': location,
        'url': url.toString(),
        'category': category,
        'role_family': roleFamily,
        'match_reasons': matchReasons,
        'keyword_matches': keywordMatches,
        'profile_skill_matches': profileSkillMatches,
        'inferred_skill_gaps': inferredSkillGaps,
      };
}

class CareerDocument {
  final String id;
  final String kind;
  final int version;
  final String filename;
  final String title;
  final String company;
  final String jobTitle;
  final String preview;
  final List<String> sourcesUsed;
  final String pdfPath;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CareerDocument({
    required this.id,
    required this.kind,
    required this.version,
    required this.filename,
    required this.title,
    required this.company,
    required this.jobTitle,
    required this.preview,
    required this.sourcesUsed,
    required this.pdfPath,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CareerDocument.fromJson(Map<String, dynamic> json) => CareerDocument(
        id: json['id'] as String? ?? '',
        kind: json['kind'] as String? ?? 'resume',
        version: json['version'] as int? ?? 1,
        filename: json['filename'] as String? ?? 'CareerLoop_Document.pdf',
        title: json['title'] as String? ?? 'Tailored document',
        company: json['company'] as String? ?? '',
        jobTitle: json['job_title'] as String? ?? '',
        preview: json['preview'] as String? ?? '',
        sourcesUsed:
            List<String>.from(json['sources_used'] as List? ?? const []),
        pdfPath: json['pdf_path'] as String? ?? '',
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
            DateTime.now(),
        updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? '') ??
            DateTime.now(),
      );
}

class CareerCourseRecommendation {
  final String id;
  final String title;
  final String provider;
  final String platform;
  final Uri url;
  final String level;
  final String duration;
  final List<String> skills;
  final List<String> roles;
  final List<String> addressesSkills;

  const CareerCourseRecommendation({
    required this.id,
    required this.title,
    required this.provider,
    required this.platform,
    required this.url,
    required this.level,
    required this.duration,
    required this.skills,
    required this.roles,
    required this.addressesSkills,
  });

  factory CareerCourseRecommendation.fromJson(Map<String, dynamic> json) =>
      CareerCourseRecommendation(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? 'Recommended course',
        provider: json['provider'] as String? ?? 'Course provider',
        platform: json['platform'] as String? ?? 'Coursera',
        url: Uri.tryParse(json['url'] as String? ?? '') ?? Uri(),
        level: json['level'] as String? ?? '',
        duration: json['duration'] as String? ?? '',
        skills: List<String>.from(json['skills'] as List? ?? const []),
        roles: List<String>.from(json['roles'] as List? ?? const []),
        addressesSkills: List<String>.from(
          json['addresses_skills'] as List? ?? const [],
        ),
      );
}

class OpportunitySearchResult {
  final String source;
  final String sourceDetail;
  final DateTime searchedAt;
  final OpportunityEvidence evidence;
  final List<JobOpportunity> jobs;
  final List<CareerCourseRecommendation> courses;
  final String? message;
  final List<String> limitations;

  const OpportunitySearchResult({
    required this.source,
    required this.sourceDetail,
    required this.searchedAt,
    required this.evidence,
    required this.jobs,
    required this.courses,
    required this.message,
    required this.limitations,
  });

  factory OpportunitySearchResult.fromJson(Map<String, dynamic> json) =>
      OpportunitySearchResult(
        source: json['source'] as String? ?? 'Swelist',
        sourceDetail: json['source_detail'] as String? ?? '',
        searchedAt: DateTime.tryParse(json['searched_at'] as String? ?? '')
                ?.toLocal() ??
            DateTime.now(),
        evidence: OpportunityEvidence.fromJson(
          Map<String, dynamic>.from(json['evidence'] as Map? ?? const {}),
        ),
        jobs: (json['jobs'] as List? ?? const [])
            .map(
              (item) => JobOpportunity.fromJson(
                Map<String, dynamic>.from(item as Map),
              ),
            )
            .toList(),
        courses: (json['recommended_courses'] as List? ?? const [])
            .map(
              (item) => CareerCourseRecommendation.fromJson(
                Map<String, dynamic>.from(item as Map),
              ),
            )
            .toList(),
        message: json['message'] as String?,
        limitations:
            List<String>.from(json['limitations'] as List? ?? const []),
      );
}

class PracticeQuestion {
  final String id;
  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;
  final String concept;

  const PracticeQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
    required this.concept,
  });

  factory PracticeQuestion.fromJson(Map<String, dynamic> json) =>
      PracticeQuestion(
        id: json['id'] as String? ?? '',
        question: json['question'] as String? ?? '',
        options: List<String>.from(json['options'] as List? ?? const []),
        correctIndex: json['correct_index'] as int? ?? 0,
        explanation: json['explanation'] as String? ?? '',
        concept: json['concept'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'question': question,
        'options': options,
        'correct_index': correctIndex,
        'explanation': explanation,
        'concept': concept,
      };
}

class PracticeSet {
  final String id;
  final String title;
  final String course;
  final String assessmentType;
  final String studyNotes;
  final DateTime createdAt;
  final List<PracticeQuestion> questions;

  const PracticeSet({
    required this.id,
    required this.title,
    required this.course,
    required this.assessmentType,
    required this.studyNotes,
    required this.createdAt,
    required this.questions,
  });

  factory PracticeSet.fromJson(Map<String, dynamic> json) => PracticeSet(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? 'Practice set',
        course: json['course'] as String? ?? '',
        assessmentType: json['assessment_type'] as String? ?? 'practice',
        studyNotes: json['study_notes'] as String? ?? '',
        createdAt:
            DateTime.tryParse(json['created_at'] as String? ?? '')?.toLocal() ??
                DateTime.now(),
        questions: (json['questions'] as List? ?? const [])
            .map(
              (item) => PracticeQuestion.fromJson(
                Map<String, dynamic>.from(item as Map),
              ),
            )
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'course': course,
        'assessment_type': assessmentType,
        'study_notes': studyNotes,
        'created_at': createdAt.toUtc().toIso8601String(),
        'questions': questions.map((question) => question.toJson()).toList(),
      };
}

class ChatMessage {
  final bool isUser;
  final String text;
  final DateTime createdAt;
  final List<String> sources;
  final List<ToolActivity> tools;
  final PracticeSet? practiceSet;

  const ChatMessage({
    required this.isUser,
    required this.text,
    required this.createdAt,
    this.sources = const [],
    this.tools = const [],
    this.practiceSet,
  });
}

class GithubSkillEvidence {
  final String skill;
  final String category;
  final List<String> evidenceRepos;
  final double weight;

  const GithubSkillEvidence({
    required this.skill,
    required this.category,
    required this.evidenceRepos,
    required this.weight,
  });

  factory GithubSkillEvidence.fromJson(Map<String, dynamic> json) =>
      GithubSkillEvidence(
        skill: json['skill'] as String? ?? '',
        category: json['category'] as String? ?? 'technology',
        evidenceRepos: List<String>.from(
          json['evidence_repos'] as List? ?? const [],
        ),
        weight: (json['weight'] as num?)?.toDouble() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'skill': skill,
        'category': category,
        'evidence_repos': evidenceRepos,
        'weight': weight,
      };
}

class GithubRepositoryEvidence {
  final String name;
  final String fullName;
  final String? description;
  final Uri url;
  final String? primaryLanguage;
  final Map<String, int> languages;
  final List<String> topics;
  final int stars;
  final int forks;
  final DateTime? pushedAt;
  final String? readmeExcerpt;
  final List<String> detectedSkills;

  const GithubRepositoryEvidence({
    required this.name,
    required this.fullName,
    required this.description,
    required this.url,
    required this.primaryLanguage,
    required this.languages,
    required this.topics,
    required this.stars,
    required this.forks,
    required this.pushedAt,
    required this.readmeExcerpt,
    required this.detectedSkills,
  });

  factory GithubRepositoryEvidence.fromJson(Map<String, dynamic> json) =>
      GithubRepositoryEvidence(
        name: json['name'] as String? ?? 'Repository',
        fullName: json['full_name'] as String? ?? '',
        description: json['description'] as String?,
        url: Uri.tryParse(json['html_url'] as String? ?? '') ?? Uri(),
        primaryLanguage: json['primary_language'] as String?,
        languages: (json['languages'] as Map? ?? const {}).map(
          (key, value) => MapEntry(
            key.toString(),
            (value as num?)?.toInt() ?? 0,
          ),
        ),
        topics: List<String>.from(json['topics'] as List? ?? const []),
        stars: json['stars'] as int? ?? 0,
        forks: json['forks'] as int? ?? 0,
        pushedAt: DateTime.tryParse(json['pushed_at'] as String? ?? ''),
        readmeExcerpt: json['readme_excerpt'] as String?,
        detectedSkills: List<String>.from(
          json['detected_skills'] as List? ?? const [],
        ),
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'full_name': fullName,
        'description': description,
        'html_url': url.toString(),
        'primary_language': primaryLanguage,
        'languages': languages,
        'topics': topics,
        'stars': stars,
        'forks': forks,
        'pushed_at': pushedAt?.toUtc().toIso8601String(),
        'readme_excerpt': readmeExcerpt,
        'detected_skills': detectedSkills,
      };
}

class GithubProfileEvidence {
  final String login;
  final String? name;
  final String? bio;
  final String? company;
  final String? location;
  final Uri? avatarUrl;
  final Uri profileUrl;
  final int publicRepos;
  final int followers;
  final int repositoryCount;
  final int analyzedRepositoryCount;
  final DateTime refreshedAt;
  final Map<String, int> languages;
  final List<GithubSkillEvidence> skills;
  final List<GithubRepositoryEvidence> repositories;

  const GithubProfileEvidence({
    required this.login,
    required this.name,
    required this.bio,
    required this.company,
    required this.location,
    required this.avatarUrl,
    required this.profileUrl,
    required this.publicRepos,
    required this.followers,
    required this.repositoryCount,
    required this.analyzedRepositoryCount,
    required this.refreshedAt,
    required this.languages,
    required this.skills,
    required this.repositories,
  });

  factory GithubProfileEvidence.fromJson(Map<String, dynamic> json) =>
      GithubProfileEvidence(
        login: json['login'] as String? ?? '',
        name: json['name'] as String?,
        bio: json['bio'] as String?,
        company: json['company'] as String?,
        location: json['location'] as String?,
        avatarUrl: Uri.tryParse(json['avatar_url'] as String? ?? ''),
        profileUrl: Uri.tryParse(json['html_url'] as String? ?? '') ?? Uri(),
        publicRepos: json['public_repos'] as int? ?? 0,
        followers: json['followers'] as int? ?? 0,
        repositoryCount: json['repository_count'] as int? ?? 0,
        analyzedRepositoryCount: json['analyzed_repository_count'] as int? ?? 0,
        refreshedAt: DateTime.tryParse(json['refreshed_at'] as String? ?? '') ??
            DateTime.now(),
        languages: (json['languages'] as Map? ?? const {}).map(
          (key, value) => MapEntry(
            key.toString(),
            (value as num?)?.toInt() ?? 0,
          ),
        ),
        skills: (json['skills'] as List? ?? const [])
            .map(
              (value) => GithubSkillEvidence.fromJson(
                Map<String, dynamic>.from(value as Map),
              ),
            )
            .toList(),
        repositories: (json['repositories'] as List? ?? const [])
            .map(
              (value) => GithubRepositoryEvidence.fromJson(
                Map<String, dynamic>.from(value as Map),
              ),
            )
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'login': login,
        'name': name,
        'bio': bio,
        'company': company,
        'location': location,
        'avatar_url': avatarUrl?.toString(),
        'html_url': profileUrl.toString(),
        'public_repos': publicRepos,
        'followers': followers,
        'repository_count': repositoryCount,
        'analyzed_repository_count': analyzedRepositoryCount,
        'refreshed_at': refreshedAt.toUtc().toIso8601String(),
        'languages': languages,
        'skills': skills.map((value) => value.toJson()).toList(),
        'repositories': repositories.map((value) => value.toJson()).toList(),
      };
}

class GithubDeviceAuthorization {
  final String userCode;
  final Uri verificationUri;
  final int expiresIn;
  final int interval;

  const GithubDeviceAuthorization({
    required this.userCode,
    required this.verificationUri,
    required this.expiresIn,
    required this.interval,
  });

  factory GithubDeviceAuthorization.fromJson(Map<String, dynamic> json) =>
      GithubDeviceAuthorization(
        userCode: json['user_code'] as String? ?? '',
        verificationUri:
            Uri.tryParse(json['verification_uri'] as String? ?? '') ?? Uri(),
        expiresIn: json['expires_in'] as int? ?? 900,
        interval: json['interval'] as int? ?? 5,
      );
}

class LinkedInPdfProfile {
  final String fileName;
  final DateTime importedAt;
  final int pageCount;
  final String? name;
  final String? headline;
  final String? summary;
  final List<String> contact;
  final List<String> experience;
  final List<String> education;
  final List<String> certifications;
  final List<String> skills;
  final String rawText;

  const LinkedInPdfProfile({
    required this.fileName,
    required this.importedAt,
    required this.pageCount,
    required this.name,
    required this.headline,
    required this.summary,
    required this.contact,
    required this.experience,
    required this.education,
    required this.certifications,
    required this.skills,
    required this.rawText,
  });

  factory LinkedInPdfProfile.fromJson(Map<String, dynamic> json) {
    final parsedName = json['name'] as String?;
    final safeName = _credibleLinkedInName(parsedName) ? parsedName : null;
    return LinkedInPdfProfile(
      fileName: json['file_name'] as String? ?? 'LinkedIn_Profile.pdf',
      importedAt: DateTime.tryParse(json['imported_at'] as String? ?? '') ??
          DateTime.now(),
      pageCount: (json['page_count'] as num?)?.toInt() ?? 1,
      name: safeName,
      headline: safeName == null ? null : json['headline'] as String?,
      summary: json['summary'] as String?,
      contact: List<String>.from(json['contact'] as List? ?? const []),
      experience: List<String>.from(json['experience'] as List? ?? const []),
      education: List<String>.from(json['education'] as List? ?? const []),
      certifications:
          List<String>.from(json['certifications'] as List? ?? const []),
      skills: List<String>.from(json['skills'] as List? ?? const []),
      rawText: json['raw_text'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'file_name': fileName,
        'imported_at': importedAt.toUtc().toIso8601String(),
        'page_count': pageCount,
        'name': name,
        'headline': headline,
        'summary': summary,
        'contact': contact,
        'experience': experience,
        'education': education,
        'certifications': certifications,
        'skills': skills,
        'raw_text': rawText,
      };
}

bool _credibleLinkedInName(String? value) {
  if (value == null) return false;
  final words = value.trim().split(RegExp(r'\s+'));
  if (words.length < 2 || words.length > 6) return false;
  const nonNameTerms = {
    'academy',
    'badge',
    'certification',
    'certified',
    'certificate',
    'course',
    'credential',
    'diploma',
    'foundations',
    'license',
    'professional',
    'specialist',
  };
  return words
      .map((word) => word.toLowerCase().replaceAll(RegExp(r'[^a-z-]'), ''))
      .where((word) => word.isNotEmpty)
      .every((word) => !nonNameTerms.contains(word));
}

extension _LastOrNull<T> on Iterable<T> {
  T? get lastOrNull => isEmpty ? null : last;
}
