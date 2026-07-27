import 'package:careerloop/data/application_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('round-trips extracted resume evidence for session rehydration', () {
    final profile = ResumeProfile.fromJson({
      'file_name': 'Islam_Hesham_CV.pdf',
      'imported_at': '2026-07-27T12:00:00Z',
      'page_count': 1,
      'name': 'Islam Hesham',
      'headline': 'Software Engineer',
      'email': 'islam@example.com',
      'phone': '+49 123 456789',
      'summary': 'Builds reliable mobile and backend systems.',
      'skills': ['Flutter', 'FastAPI'],
      'experience': ['Built CareerLoop.'],
      'education': ['BSc Computer Science'],
      'certifications': ['Cloud Foundations'],
      'raw_text':
          'Islam Hesham Software Engineer builds reliable mobile systems.',
    });

    final restored = ResumeProfile.fromJson(profile.toJson());

    expect(restored.name, 'Islam Hesham');
    expect(restored.skills, ['Flutter', 'FastAPI']);
    expect(restored.experience, ['Built CareerLoop.']);
    expect(restored.fileName, 'Islam_Hesham_CV.pdf');
  });
}
