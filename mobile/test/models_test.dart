import 'package:careerloop/data/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('loads the professional evidence extracted from a LinkedIn PDF', () {
    final profile = LinkedInPdfProfile.fromJson({
      'file_name': 'LinkedIn.pdf',
      'imported_at': '2026-07-26T12:00:00Z',
      'page_count': 2,
      'name': 'Ada Lovelace',
      'headline': 'Software Engineer',
      'summary': 'Builds reliable systems.',
      'contact': ['ada@example.com'],
      'experience': ['Example GmbH'],
      'education': ['GIU'],
      'certifications': ['Cloud Foundations'],
      'skills': ['Python'],
      'raw_text': 'Ada Lovelace\nSoftware Engineer',
    });

    expect(profile.name, 'Ada Lovelace');
    expect(profile.experience, contains('Example GmbH'));
    expect(profile.toJson()['skills'], ['Python']);
    expect(profile.pageCount, 2);
  });

  test('keeps the CMS limited-access message without failing the session', () {
    final session = SessionInfo.fromJson({
      'current_season': 'Winter 2025',
      'advisory_year': '2024-2025',
      'enrollment_year': 2021,
      'transcript_years': ['2024-2025'],
      'expires_in_seconds': 2700,
      'cms_connected': false,
      'cms_message': 'CMS access may end after graduation.',
    });

    expect(session.cmsConnected, isFalse);
    expect(session.cmsMessage, contains('graduation'));
  });

  test('extracts a GIU course code and title from its long portal label', () {
    final course = CourseSummary.fromLabel(
      'GIU-Cairo.Informatics and Computer Science - '
      'Software Engineering 5th - ICS501 Software Project I',
    );

    expect(course.code, 'ICS501');
    expect(course.title, 'Software Project I');
  });

  test('calculates an assessment ratio from an earned / maximum grade', () {
    const assessment = Assessment(
      assessment: 'Final Grade',
      element: 'Quiz',
      grade: '7 / 10',
      evaluator: 'Instructor',
    );

    expect(assessment.ratio, .7);
  });

  test('maps GIU percentages to the supplied letter and GPA bands', () {
    expect(GiuGradeScale.forPercentage(94)?.letter, 'A+');
    expect(GiuGradeScale.forPercentage(93.9)?.letter, 'A');
    expect(GiuGradeScale.forPercentage(86)?.letter, 'A-');
    expect(GiuGradeScale.forPercentage(82)?.letter, 'B+');
    expect(GiuGradeScale.forPercentage(78)?.letter, 'B');
    expect(GiuGradeScale.forPercentage(74)?.letter, 'B-');
    expect(GiuGradeScale.forPercentage(70)?.letter, 'C+');
    expect(GiuGradeScale.forPercentage(65)?.letter, 'C');
    expect(GiuGradeScale.forPercentage(60)?.letter, 'C-');
    expect(GiuGradeScale.forPercentage(55)?.letter, 'D+');
    expect(GiuGradeScale.forPercentage(50)?.letter, 'D');
    expect(GiuGradeScale.forPercentage(49.9)?.letter, 'F');
    expect(GiuGradeScale.forPercentage(94)?.gpaRange, '0.70–0.99');
  });

  test('writes the transcript GPA with its letter grade in brackets', () {
    const course = TranscriptCourse(
      semester: 'Winter 2024',
      course: 'ICS501 Software Project I',
      grade: 'A',
      numeric: '1.20',
      hours: '4',
      group: 'Core',
    );

    expect(course.numericGpa, 1.2);
    expect(course.mappedGrade?.letter, 'A');
    expect(course.mappedGrade?.gpaRange, '1.00–1.29');
    expect(course.gpaWithGrade, '1.20 (A)');
  });

  test('writes cumulative GPA with its mapped letter grade', () {
    const transcript = Transcript(
      year: '2024-2025',
      cumulativeGpa: '1.45',
      courses: [],
    );

    expect(transcript.cumulativeGpaWithGrade, '1.45 (A-)');
  });

  test('maps a hidden practice answer to the correct local option', () {
    final practice = PracticeSet.fromJson({
      'id': 'set-1',
      'title': 'Data Structures Midterm',
      'course': 'CSEN301',
      'assessment_type': 'midterm',
      'study_notes': 'Review balanced tree operations.',
      'created_at': '2026-07-26T12:00:00Z',
      'questions': [
        {
          'id': 'q-1',
          'question': 'Which operation is logarithmic in a balanced BST?',
          'options': ['Traversal', 'Linear scan', 'Search', 'Array append'],
          'correct_index': 2,
          'explanation': 'Search follows the logarithmic tree height.',
          'concept': 'Balanced search trees',
        },
      ],
    });

    expect(practice.questions.single.correctIndex, 2);
    expect(
      practice.questions.single.options[practice.questions.single.correctIndex],
      'Search',
    );
  });
}
