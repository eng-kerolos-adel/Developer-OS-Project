import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/onboarding_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../features/projects/presentation/screens/project_detail_screen.dart';
import '../../features/projects/presentation/screens/create_project_screen.dart';
import '../../features/projects/presentation/screens/project_timeline_screen.dart';
import '../../features/projects/presentation/screens/project_tasks_screen.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../constants/route_constants.dart';
import 'package:developer_os/features/profile/presentation/screens/profile_screen.dart';
import 'package:developer_os/features/projects/presentation/screens/projects_screen.dart';
import 'package:developer_os/features/skills/presentation/screens/skills_screen.dart';
import 'package:developer_os/features/links/presentation/screens/links_screen.dart';
import 'package:developer_os/features/journal/presentation/screens/journal_screen.dart';
import 'package:developer_os/features/snippets/presentation/screens/snippets_screen.dart';
import 'package:developer_os/features/interview/presentation/screens/interview_screen.dart';
import 'package:developer_os/features/flashcards/presentation/screens/flashcards_screen.dart';
import 'package:developer_os/features/learning/presentation/screens/learning_screen.dart';
import 'package:developer_os/features/freelance/presentation/screens/freelance_screen.dart';
import 'package:developer_os/features/tools/presentation/screens/dev_tools_screen.dart';
import 'package:developer_os/features/achievements/presentation/screens/achievements_screen.dart';
import 'package:developer_os/features/settings/presentation/screens/settings_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/ai/presentation/screens/readme_generator_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: RouteConstants.splash,
    debugLogDiagnostics: false,
    redirect: (context, state) {
      final isLoggedIn = authState.asData?.value != null;
      final isAuthRoute = state.matchedLocation == RouteConstants.login ||
          state.matchedLocation == RouteConstants.register ||
          state.matchedLocation == RouteConstants.splash ||
          state.matchedLocation == RouteConstants.onboarding;

      if (!isLoggedIn && !isAuthRoute) {
        return RouteConstants.login;
      }
      if (isLoggedIn &&
          (state.matchedLocation == RouteConstants.login ||
              state.matchedLocation == RouteConstants.register)) {
        return RouteConstants.home;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: RouteConstants.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: RouteConstants.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: RouteConstants.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RouteConstants.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => HomeScreen(child: child),
        routes: [
          GoRoute(
            path: RouteConstants.home,
            builder: (context, state) => const HomeDashboard(),
          ),
          GoRoute(
            path: RouteConstants.profile,
            builder: (context, state) => const ProfileScreen(),
            routes: [
              GoRoute(
                path: 'edit',
                builder: (context, state) => const EditProfileScreen(),
              ),
            ],
          ),
          GoRoute(
            path: RouteConstants.skills,
            builder: (context, state) => const SkillsScreen(),
          ),
          GoRoute(
            path: RouteConstants.journal,
            builder: (context, state) => const JournalScreen(),
          ),
          GoRoute(
            path: RouteConstants.snippets,
            builder: (context, state) => const SnippetsScreen(),
          ),
          GoRoute(
            path: RouteConstants.interview,
            builder: (context, state) => const InterviewScreen(),
          ),
          GoRoute(
            path: RouteConstants.settings,
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: RouteConstants.links,
            builder: (context, state) => const LinksScreen(),
          ),
          GoRoute(
            path: RouteConstants.cards,
            builder: (context, state) => const FlashCardsScreen(),
          ),
          GoRoute(
            path: RouteConstants.learning,
            builder: (context, state) => const LearningScreen(),
          ),
          GoRoute(
            path: RouteConstants.freelance,
            builder: (context, state) => const FreelanceScreen(),
          ),
          // GoRoute(
          //   path: RouteConstants.tools,
          //   builder: (context, state) => const DevToolsScreen(),
          // ),
          GoRoute(
            path: RouteConstants.awards,
            builder: (context, state) => const AchievementsScreen(),
          ),
          GoRoute(
            path: RouteConstants.notifs,
            builder: (context, state) => const NotificationsScreen(),
          ),
          GoRoute(
            path: RouteConstants.readmeGenerator,
            builder: (context, state) => const ReadmeGeneratorScreen(),
          ),
          GoRoute(
            path: RouteConstants.projects,
            builder: (context, state) => const ProjectsScreen(),
            routes: [
              GoRoute(
                path: 'create',
                builder: (context, state) => const CreateProjectScreen(),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return ProjectDetailScreen(projectId: id);
                },
                routes: [
                  GoRoute(
                    path: 'timeline',
                    builder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return ProjectTimelineScreen(projectId: id);
                    },
                  ),
                  GoRoute(
                    path: 'tasks',
                    builder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return ProjectTasksScreen(projectId: id);
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('404 - ${state.error}'),
      ),
    ),
  );
});
