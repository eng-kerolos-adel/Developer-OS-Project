import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../domain/models/project.dart';
import '../data/repositories/project_repository.dart';
import '../../auth/providers/auth_provider.dart';

final projectsProvider = StreamProvider<List<Project>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);
  final repo = ref.watch(projectRepositoryProvider);
  return repo.watchProjects(user.uid);
});

final projectDetailProvider =
    StreamProvider.family<Project?, String>((ref, id) {
  return ref.watch(projectRepositoryProvider).watchProjects('').map(
        (list) => list.where((p) => p.id == id).firstOrNull,
      );
});

final tasksProvider =
    StreamProvider.family<List<ProjectTask>, String>((ref, projectId) {
  return ref.watch(projectRepositoryProvider).watchTasks(projectId);
});

class ProjectController extends StateNotifier<AsyncValue<void>> {
  final ProjectRepository _repo;
  final String uid;

  ProjectController(this._repo, this.uid) : super(const AsyncValue.data(null));

  Future<String?> createProject({
    required String name,
    required String description,
    required List<String> techStack,
    required String projectType,
    required String targetPlatform,
    DateTime? startDate,
    String? githubUrl,
    String? demoUrl,
  }) async {
    state = const AsyncValue.loading();
    try {
      final roadmap = RoadmapGenerator.generate(
        techStack: techStack,
        projectType: projectType,
        targetPlatform: targetPlatform,
      );

      final project = Project(
        id: '',
        uid: uid,
        name: name,
        description: description,
        techStack: techStack,
        projectType: projectType,
        targetPlatform: targetPlatform,
        startDate: startDate ?? DateTime.now(),
        endDate: startDate != null
            ? startDate.add(Duration(days: roadmap.length * 7))
            : DateTime.now().add(Duration(days: roadmap.length * 7)),
        githubUrl: githubUrl,
        demoUrl: demoUrl,
        roadmap: roadmap,
        createdAt: DateTime.now(),
      );

      final id = await _repo.createProject(project);
      state = const AsyncValue.data(null);
      return id;
    } catch (e, s) {
      state = AsyncValue.error(e, s);
      return null;
    }
  }

  Future<void> updateProject(Project project) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repo.updateProject(project));
  }

  Future<void> deleteProject(String id) async {
    await _repo.deleteProject(id);
  }

  Future<void> toggleWeekComplete(Project project, int weekIndex) async {
    final weeks = List<ProjectWeek>.from(project.roadmap);
    weeks[weekIndex] = weeks[weekIndex].copyWith(
      completed: !weeks[weekIndex].completed,
    );
    await _repo.updateProject(project.copyWith(roadmap: weeks));
  }

  // Tasks
  Future<void> createTask({
    required String projectId,
    required String title,
    String? description,
    String status = 'todo',
    String priority = 'medium',
    DateTime? dueDate,
  }) async {
    final task = ProjectTask(
      id: const Uuid().v4(),
      projectId: projectId,
      uid: uid,
      title: title,
      description: description,
      status: status,
      priority: priority,
      dueDate: dueDate,
      createdAt: DateTime.now(),
    );
    await _repo.createTask(task);
  }

  Future<void> updateTaskStatus(ProjectTask task, String status) async {
    await _repo.updateTask(task.copyWith(status: status));
  }

  Future<void> deleteTask(String projectId, String taskId) async {
    await _repo.deleteTask(projectId, taskId);
  }
}

final projectControllerProvider =
    StateNotifierProvider<ProjectController, AsyncValue<void>>((ref) {
  final user = ref.watch(currentUserProvider);
  final repo = ref.watch(projectRepositoryProvider);
  return ProjectController(repo, user?.uid ?? '');
});

// =========================================
// Roadmap Generator
// =========================================
class RoadmapGenerator {
  static List<ProjectWeek> generate({
    required List<String> techStack,
    required String projectType,
    required String targetPlatform,
  }) {
    final weeks = <ProjectWeek>[];
    int weekNum = 1;

    // Phase 1: Planning & Setup (always week 1)
    weeks.add(ProjectWeek(
      weekNumber: weekNum++,
      title: 'Project Setup & Planning',
      description: 'Initialize repository, set up development environment, define architecture.',
      tasks: [
        'Create repository and project structure',
        'Define architecture and folder structure',
        'Set up version control (Git) and branching strategy',
        'Create initial documentation (README)',
        'Set up linting and code formatting tools',
      ],
    ));

    // Phase 2: Design
    weeks.add(ProjectWeek(
      weekNumber: weekNum++,
      title: 'UI/UX Design & Wireframes',
      description: 'Design the user interface and user experience flows.',
      tasks: [
        'Create wireframes for main screens',
        'Define color palette, typography, and design system',
        'Design component library',
        'Review and iterate on designs',
      ],
    ));

    // Phase 3: Backend/DB setup if relevant
    final hasBackend = techStack.any((t) =>
        ['Node.js', 'Python', 'Django', 'FastAPI', 'Go', 'Java', 'Spring Boot',
          'Firebase', 'Supabase', 'PostgreSQL', 'MySQL', 'MongoDB'].contains(t));

    if (hasBackend) {
      weeks.add(ProjectWeek(
        weekNumber: weekNum++,
        title: 'Backend & Database Setup',
        description: 'Configure server, database schema, and API structure.',
        tasks: [
          'Set up ${_pickFirst(techStack, ['Node.js', 'Python', 'Django', 'Go', 'Firebase'])} project',
          'Design database schema',
          'Set up database connections',
          'Configure environment variables and secrets',
          'Create initial migration/seed files',
        ],
      ));
    }

    // Phase 4: Auth if relevant
    weeks.add(ProjectWeek(
      weekNumber: weekNum++,
      title: 'Authentication & Authorization',
      description: 'Implement user authentication and access control.',
      tasks: [
        'Implement sign up / sign in flows',
        'Set up JWT or session management',
        'Add OAuth / social login (Google, GitHub)',
        'Protect private routes',
        'Write auth unit tests',
      ],
    ));

    // Phase 5: Core features - split into 2 weeks
    weeks.add(ProjectWeek(
      weekNumber: weekNum++,
      title: 'Core Feature Development — Part 1',
      description: 'Build the primary features of the application.',
      tasks: [
        'Implement main data models',
        'Build core UI screens',
        'Connect frontend to backend/API',
        'Implement CRUD operations',
        'State management setup',
      ],
    ));

    weeks.add(ProjectWeek(
      weekNumber: weekNum++,
      title: 'Core Feature Development — Part 2',
      description: 'Continue building and integrate secondary features.',
      tasks: [
        'Implement remaining screens',
        'Add real-time updates (if applicable)',
        'Integrate third-party APIs',
        'Handle error states and loading states',
        'Add form validation',
      ],
    ));

    // Phase 6: Platform-specific
    if (targetPlatform == 'iOS' || targetPlatform == 'Android' || targetPlatform == 'Cross-platform') {
      weeks.add(ProjectWeek(
        weekNumber: weekNum++,
        title: 'Mobile-Specific Implementation',
        description: 'Implement mobile-specific features and optimizations.',
        tasks: [
          'Configure push notifications',
          'Implement deep linking',
          'Handle offline mode and caching',
          'Optimize for different screen sizes',
          'Platform-specific permissions handling',
        ],
      ));
    }

    // Phase 7: Testing
    weeks.add(ProjectWeek(
      weekNumber: weekNum++,
      title: 'Testing & Quality Assurance',
      description: 'Write tests and ensure application quality.',
      tasks: [
        'Write unit tests for business logic',
        'Write integration tests',
        'Perform manual QA testing',
        'Fix identified bugs',
        'Performance profiling',
      ],
    ));

    // Phase 8: Polish & Optimization
    weeks.add(ProjectWeek(
      weekNumber: weekNum++,
      title: 'Polish, Animations & UX',
      description: 'Refine UI, add animations, and improve user experience.',
      tasks: [
        'Add micro-animations and transitions',
        'Improve loading states and skeleton screens',
        'Optimize images and assets',
        'Accessibility audit',
        'Responsive design testing',
      ],
    ));

    // Phase 9: DevOps / Deployment
    final hasDevOps = techStack.any((t) =>
        ['Docker', 'Kubernetes', 'AWS', 'GCP', 'Azure', 'CI/CD', 'GitHub Actions'].contains(t));

    if (hasDevOps) {
      weeks.add(ProjectWeek(
        weekNumber: weekNum++,
        title: 'DevOps & CI/CD Pipeline',
        description: 'Set up continuous integration, delivery, and infrastructure.',
        tasks: [
          'Configure CI/CD pipeline (GitHub Actions / Jenkins)',
          'Dockerize the application',
          'Set up staging environment',
          'Configure environment-specific configs',
          'Automate deployment',
        ],
      ));
    }

    // Phase 10: Launch
    weeks.add(ProjectWeek(
      weekNumber: weekNum++,
      title: 'Launch & Deployment',
      description: 'Deploy the application and prepare for launch.',
      tasks: [
        'Final pre-launch checklist',
        'Deploy to production environment',
        'Configure monitoring and error tracking',
        'Set up analytics',
        'Write deployment documentation',
      ],
    ));

    // Phase 11: Post-launch
    weeks.add(ProjectWeek(
      weekNumber: weekNum,
      title: 'Post-Launch & Maintenance',
      description: 'Monitor, gather feedback, and plan next iteration.',
      tasks: [
        'Monitor for production errors',
        'Gather user feedback',
        'Prioritize bug fixes',
        'Plan v2 features',
        'Update documentation',
      ],
    ));

    return weeks;
  }

  static String _pickFirst(List<String> stack, List<String> options) {
    for (final opt in options) {
      if (stack.contains(opt)) return opt;
    }
    return options.first;
  }
}
