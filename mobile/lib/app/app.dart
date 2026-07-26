import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/models.dart';
import '../data/repositories.dart';
import '../ui/advisor/advisor_screen.dart';
import '../ui/auth/login_screen.dart';
import '../ui/core/app_shell.dart';
import '../ui/courses/course_details_screen.dart';
import '../ui/courses/cms_course_screen.dart';
import '../ui/courses/courses_screen.dart';
import '../ui/overview/overview_screen.dart';
import '../ui/practice/practice_screens.dart';
import '../ui/settings/settings_screen.dart';
import '../ui/transcript/transcript_screen.dart';
import '../ui/viewer/drive_video_screen.dart';
import '../ui/viewer/pdf_viewer_screen.dart';
import 'theme.dart';

class CareerLoopApp extends StatefulWidget {
  const CareerLoopApp({super.key});

  @override
  State<CareerLoopApp> createState() => _CareerLoopAppState();
}

class _CareerLoopAppState extends State<CareerLoopApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthRepository>();
    _router = GoRouter(
      initialLocation: auth.isAuthenticated ? '/overview' : '/login',
      refreshListenable: auth,
      redirect: (context, state) {
        final atLogin = state.matchedLocation == '/login';
        if (!auth.isAuthenticated && !atLogin) return '/login';
        if (auth.isAuthenticated && atLogin) return '/overview';
        return null;
      },
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) =>
              AppShell(navigationShell: navigationShell),
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/overview',
                  builder: (context, state) => const OverviewScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/courses',
                  builder: (context, state) => const CoursesScreen(),
                  routes: [
                    GoRoute(
                      path: 'cms/:slug',
                      builder: (context, state) {
                        final extra = state.extra;
                        final course = extra is CmsCourse
                            ? extra
                            : CmsCourse(
                                id: state.pathParameters['slug'] ?? '',
                                code: 'CMS',
                                title: 'CMS course',
                                cmsLabel: 'CMS course',
                                resourceCount: null,
                                season: '',
                                seasonId: null,
                                active: null,
                                hasSupplementalVideos: false,
                                videoCount: 0,
                                transcribedCount: 0,
                              );
                        return CmsCourseScreen(course: course);
                      },
                    ),
                    GoRoute(
                      path: ':code',
                      builder: (context, state) {
                        final extra = state.extra;
                        final course = extra is CourseSummary
                            ? extra
                            : CourseSummary.fromLabel(
                                state.pathParameters['code'] ?? 'Course',
                              );
                        return CourseDetailsScreen(course: course);
                      },
                    ),
                  ],
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/advisor',
                  builder: (context, state) => const AdvisorScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/transcript',
                  builder: (context, state) => const TranscriptScreen(),
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
        GoRoute(
          path: '/viewer/pdf',
          builder: (context, state) {
            final args = state.extra as PdfViewerArgs;
            return PdfViewerScreen(args: args);
          },
        ),
        GoRoute(
          path: '/viewer/video',
          builder: (context, state) {
            final args = state.extra as DriveVideoArgs;
            return DriveVideoScreen(args: args);
          },
        ),
        GoRoute(
          path: '/practice',
          builder: (context, state) => const PracticeLibraryScreen(),
          routes: [
            GoRoute(
              path: 'session',
              builder: (context, state) {
                final practiceSet = state.extra as PracticeSet;
                return PracticeSessionScreen(practiceSet: practiceSet);
              },
            ),
          ],
        ),
      ],
    );
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'CareerLoop',
      debugShowCheckedModeBanner: false,
      theme: CareerLoopTheme.light(),
      routerConfig: _router,
    );
  }
}
