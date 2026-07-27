import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app/app.dart';
import 'core/environment.dart';
import 'data/api_client.dart';
import 'data/application_repository.dart';
import 'data/career_profile_repository.dart';
import 'data/current_cv_repository.dart';
import 'data/github_profile_repository.dart';
import 'data/opportunity_repository.dart';
import 'data/repositories.dart';
import 'data/practice_repository.dart';
import 'data/session_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storage = SessionStorage();
  final api = ApiClient(
    baseUrl: Environment.apiBaseUrl,
    storage: storage,
  );
  final auth = AuthRepository(api: api, storage: storage);
  final academic = AcademicRepository(api: api);
  final cms = CmsRepository(api: api);
  final practice = PracticeRepository();
  await practice.load();
  final careerProfile = CareerProfileRepository(api: api);
  await careerProfile.loadLocal();
  final githubProfile = GithubProfileRepository(api: api);
  await githubProfile.loadLocal();
  final currentCv = CurrentCvRepository(api: api);
  await currentCv.loadLocal();
  final advisor = AdvisorRepository(
    api: api,
    practiceRepository: practice,
    careerProfileRepository: careerProfile,
    githubProfileRepository: githubProfile,
    currentCvRepository: currentCv,
  );
  final notion = NotionRepository(api: api);
  final opportunities = OpportunityRepository(
    api: api,
    careerProfileRepository: careerProfile,
    githubProfileRepository: githubProfile,
    currentCvRepository: currentCv,
  );
  final applications = ApplicationRepository(
    api: api,
    careerProfileRepository: careerProfile,
    githubProfileRepository: githubProfile,
    currentCvRepository: currentCv,
  );

  await auth.restoreSession();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProvider.value(value: academic),
        ChangeNotifierProvider.value(value: cms),
        ChangeNotifierProvider.value(value: advisor),
        ChangeNotifierProvider.value(value: practice),
        ChangeNotifierProvider.value(value: notion),
        ChangeNotifierProvider.value(value: careerProfile),
        ChangeNotifierProvider.value(value: githubProfile),
        ChangeNotifierProvider.value(value: opportunities),
        ChangeNotifierProvider.value(value: currentCv),
        ChangeNotifierProvider.value(value: applications),
      ],
      child: const CareerLoopApp(),
    ),
  );
}
