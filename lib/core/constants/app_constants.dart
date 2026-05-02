class AppConstants {
  // App Info
  static const String appName = 'Developer OS';
  static const String appVersion = '1.0.0';
  static const String appTagline = 'Your Developer Command Center';

  // Hive box names
  static const String prefsBox = 'developer_os_prefs';

  // Firestore collections
  static const String usersCollection = 'users';
  static const String projectsCollection = 'projects';
  static const String tasksCollection = 'tasks';
  static const String skillsCollection = 'skills';
  static const String linksCollection = 'links';
  static const String certificatesCollection = 'certificates';

  // Experience levels
  static const List<String> experienceLevels = [
    'Junior (0-2 years)',
    'Mid-level (2-5 years)',
    'Senior (5-8 years)',
    'Lead (8-12 years)',
    'Principal (12+ years)',
  ];

  // Specializations
  static const List<String> specializations = [
    'Frontend Developer',
    'Backend Developer',
    'Full Stack Developer',
    'Mobile Developer',
    'DevOps Engineer',
    'Cloud Architect',
    'Data Engineer',
    'ML/AI Engineer',
    'Blockchain Developer',
    'Embedded Systems',
    'Game Developer',
    'Security Engineer',
    'QA Engineer',
    'System Architect',
  ];

  // Tech stacks
  static const List<String> frontendTechs = [
    'React', 'Vue.js', 'Angular', 'Next.js', 'Nuxt.js',
    'Svelte', 'HTML/CSS', 'TypeScript', 'JavaScript',
    'Tailwind CSS', 'SASS/SCSS', 'Bootstrap',
  ];

  static const List<String> backendTechs = [
    'Node.js', 'Python', 'Django', 'FastAPI', 'Flask',
    'Go', 'Rust', 'Java', 'Spring Boot', 'C#', '.NET',
    'Ruby on Rails', 'PHP', 'Laravel', 'Express.js',
    'NestJS', 'GraphQL', 'REST API',
  ];

  static const List<String> mobileTechs = [
    'Flutter', 'React Native', 'Swift', 'Kotlin',
    'Android', 'iOS', 'Expo', 'Xamarin',
  ];

  static const List<String> dbTechs = [
    'PostgreSQL', 'MySQL', 'MongoDB', 'Redis',
    'Firebase', 'Supabase', 'SQLite', 'DynamoDB',
    'Cassandra', 'Elasticsearch',
  ];

  static const List<String> devOpsTechs = [
    'Docker', 'Kubernetes', 'AWS', 'GCP', 'Azure',
    'CI/CD', 'GitHub Actions', 'Jenkins', 'Terraform',
    'Ansible', 'Nginx', 'Linux',
  ];

  static const List<String> allTechs = [
    ...frontendTechs,
    ...backendTechs,
    ...mobileTechs,
    ...dbTechs,
    ...devOpsTechs,
  ];

  // Project types
  static const List<String> projectTypes = [
    'Web Application',
    'Mobile App',
    'Desktop App',
    'API / Backend',
    'Library / SDK',
    'CLI Tool',
    'Game',
    'Data Pipeline',
    'ML Model',
    'Browser Extension',
    'Microservice',
    'Full Stack',
  ];

  // Target platforms
  static const List<String> targetPlatforms = [
    'Web (Browser)',
    'iOS',
    'Android',
    'Windows',
    'macOS',
    'Linux',
    'Cross-platform',
    'Cloud (Serverless)',
    'Embedded',
  ];

  // Task statuses
  static const String taskTodo = 'todo';
  static const String taskInProgress = 'in_progress';
  static const String taskDone = 'done';

  // Link types
  static const List<Map<String, String>> linkTypes = [
    {'key': 'github', 'label': 'GitHub', 'icon': 'github'},
    {'key': 'linkedin', 'label': 'LinkedIn', 'icon': 'linkedin'},
    {'key': 'portfolio', 'label': 'Portfolio', 'icon': 'globe'},
    {'key': 'twitter', 'label': 'Twitter/X', 'icon': 'twitter'},
    {'key': 'stackoverflow', 'label': 'Stack Overflow', 'icon': 'stack-overflow'},
    {'key': 'dribbble', 'label': 'Dribbble', 'icon': 'dribbble'},
    {'key': 'behance', 'label': 'Behance', 'icon': 'behance'},
    {'key': 'youtube', 'label': 'YouTube', 'icon': 'youtube'},
    {'key': 'medium', 'label': 'Medium', 'icon': 'medium'},
    {'key': 'devto', 'label': 'Dev.to', 'icon': 'dev'},
    {'key': 'hashnode', 'label': 'Hashnode', 'icon': 'hashnode'},
    {'key': 'email', 'label': 'Email', 'icon': 'envelope'},
    {'key': 'telegram', 'label': 'Telegram', 'icon': 'telegram'},
    {'key': 'discord', 'label': 'Discord', 'icon': 'discord'},
    {'key': 'other', 'label': 'Other', 'icon': 'link'},
  ];
}
