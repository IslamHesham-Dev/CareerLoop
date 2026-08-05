import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app/app.dart';
import 'core/environment.dart';
import 'data/api_client.dart';
import 'data/application_repository.dart';
import 'data/career_document_repository.dart';
import 'data/career_profile_repository.dart';
import 'data/current_cv_repository.dart';
import 'data/email_repository.dart';
import 'data/github_profile_repository.dart';
import 'data/opportunity_repository.dart';
import 'data/practice_repository.dart';
import 'data/repositories.dart';
import 'data/session_storage.dart';
import 'data/tone_profile_repository.dart';
import 'ui/core/startup_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const _CareerLoopBootstrap());
}

class _CareerLoopBootstrap extends StatefulWidget {
  const _CareerLoopBootstrap();

  @override
  State<_CareerLoopBootstrap> createState() => _CareerLoopBootstrapState();
}

class _CareerLoopBootstrapState extends State<_CareerLoopBootstrap> {
  late Future<_AppDependencies> _initialization;

  @override
  void initState() {
    super.initState();
    _initialization = _initialize();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_AppDependencies>(
      future: _initialization,
      builder: (context, snapshot) {
        final dependencies = snapshot.data;
        if (dependencies != null) {
          return MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: dependencies.auth),
              ChangeNotifierProvider.value(value: dependencies.academic),
              ChangeNotifierProvider.value(value: dependencies.cms),
              ChangeNotifierProvider.value(value: dependencies.advisor),
              ChangeNotifierProvider.value(value: dependencies.practice),
              ChangeNotifierProvider.value(value: dependencies.notion),
              ChangeNotifierProvider.value(value: dependencies.careerProfile),
              ChangeNotifierProvider.value(value: dependencies.githubProfile),
              ChangeNotifierProvider.value(value: dependencies.opportunities),
              ChangeNotifierProvider.value(value: dependencies.currentCv),
              ChangeNotifierProvider.value(value: dependencies.applications),
              ChangeNotifierProvider.value(
                value: dependencies.careerDocuments,
              ),
              ChangeNotifierProvider.value(value: dependencies.toneProfile),
              ChangeNotifierProvider.value(value: dependencies.emails),
            ],
            child: const CareerLoopApp(),
          );
        }

        final failed = snapshot.hasError;
        return MaterialApp(
          title: 'CareerLoop',
          debugShowCheckedModeBanner: false,
          home: CareerLoopStartupScreen(
            errorMessage: failed
                ? 'CareerLoop could not finish opening. Check your connection '
                    'and try again.'
                : null,
            onRetry: failed
                ? () => setState(() => _initialization = _initialize())
                : null,
          ),
        );
      },
    );
  }
}

Future<_AppDependencies> _initialize() async {
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
  final toneProfile = ToneProfileRepository(api: api);
  await toneProfile.loadLocal();
  final advisor = AdvisorRepository(
    api: api,
    practiceRepository: practice,
    careerProfileRepository: careerProfile,
    githubProfileRepository: githubProfile,
    currentCvRepository: currentCv,
    toneProfileRepository: toneProfile,
  );
  final notion = NotionRepository(api: api);
  final opportunities = OpportunityRepository(
    api: api,
    careerProfileRepository: careerProfile,
    githubProfileRepository: githubProfile,
    currentCvRepository: currentCv,
    storage: storage,
  );
  await opportunities.loadSavedPreferences();
  final applications = ApplicationRepository(
    api: api,
    careerProfileRepository: careerProfile,
    githubProfileRepository: githubProfile,
    currentCvRepository: currentCv,
    toneProfileRepository: toneProfile,
  );
  final careerDocuments = CareerDocumentRepository(
    api: api,
    careerProfileRepository: careerProfile,
    githubProfileRepository: githubProfile,
    currentCvRepository: currentCv,
    toneProfileRepository: toneProfile,
  );
  final emails = EmailRepository(
    api: api,
    careerProfileRepository: careerProfile,
    githubProfileRepository: githubProfile,
    currentCvRepository: currentCv,
    toneProfileRepository: toneProfile,
  );

  await auth.restoreSession();
  if (auth.isAuthenticated) {
    unawaited(academic.loadDashboard());
    unawaited(toneProfile.ensureSynced());
  }

  return _AppDependencies(
    auth: auth,
    academic: academic,
    cms: cms,
    advisor: advisor,
    practice: practice,
    notion: notion,
    careerProfile: careerProfile,
    githubProfile: githubProfile,
    opportunities: opportunities,
    currentCv: currentCv,
    applications: applications,
    careerDocuments: careerDocuments,
    toneProfile: toneProfile,
    emails: emails,
  );
}

class _AppDependencies {
  final AuthRepository auth;
  final AcademicRepository academic;
  final CmsRepository cms;
  final AdvisorRepository advisor;
  final PracticeRepository practice;
  final NotionRepository notion;
  final CareerProfileRepository careerProfile;
  final GithubProfileRepository githubProfile;
  final OpportunityRepository opportunities;
  final CurrentCvRepository currentCv;
  final ApplicationRepository applications;
  final CareerDocumentRepository careerDocuments;
  final ToneProfileRepository toneProfile;
  final EmailRepository emails;

  const _AppDependencies({
    required this.auth,
    required this.academic,
    required this.cms,
    required this.advisor,
    required this.practice,
    required this.notion,
    required this.careerProfile,
    required this.githubProfile,
    required this.opportunities,
    required this.currentCv,
    required this.applications,
    required this.careerDocuments,
    required this.toneProfile,
    required this.emails,
  });
}
