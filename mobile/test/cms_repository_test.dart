import 'dart:async';
import 'dart:convert';

import 'package:careerloop/data/api_client.dart';
import 'package:careerloop/data/repositories.dart';
import 'package:careerloop/data/session_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('the latest CMS season request wins when responses arrive out of order',
      () async {
    final winter = Completer<http.Response>();
    final spring = Completer<http.Response>();
    final client = MockClient((request) {
      final season = request.url.queryParameters['season'];
      return switch (season) {
        'Winter 2025' => winter.future,
        'Spring 2026' => spring.future,
        _ => Future.value(http.Response('Not found', 404)),
      };
    });
    final repository = CmsRepository(
      api: ApiClient(
        baseUrl: 'https://careerloop.test',
        storage: SessionStorage(),
        client: client,
      ),
    );

    final oldRequest = repository.loadCourses(season: 'Winter 2025');
    await Future<void>.delayed(Duration.zero);
    final latestRequest = repository.loadCourses(season: 'Spring 2026');
    spring.complete(
      http.Response(
        jsonEncode({
          'season': 'Spring 2026',
          'courses': [
            {
              'id': 'spring-course',
              'code': 'ICS603',
              'title': 'Advanced Machine Learning',
              'cms_label': '(|ICS603|) Advanced Machine Learning (2719)',
              'season': 'Spring 2026',
              'season_id': 68,
            },
          ],
        }),
        200,
      ),
    );
    await latestRequest;
    winter.complete(
      http.Response(
        jsonEncode({
          'season': 'Winter 2025',
          'courses': [
            {
              'id': 'winter-course',
              'code': 'ICS501',
              'title': 'Software Project I',
              'cms_label': '(|ICS501|) Software Project I (2617)',
              'season': 'Winter 2025',
              'season_id': 67,
            },
          ],
        }),
        200,
      ),
    );
    await oldRequest;

    expect(repository.season, 'Spring 2026');
    expect(repository.courses.single.id, 'spring-course');
    expect(repository.loadingCourses, isFalse);
  });
}
