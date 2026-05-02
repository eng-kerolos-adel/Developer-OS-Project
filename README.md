# Developer OS — Flutter App

> Your personal developer command center. Monochrome glassmorphism design.

---

## 📁 Project Structure

```
developer_os/
├── lib/
│   ├── main.dart                         ← Entry point
│   ├── app.dart                          ← Barrel exports
│   ├── firebase_options.dart             ← Firebase config (auto-generate)
│   │
│   ├── core/
│   │   ├── constants/
│   │   │   ├── app_constants.dart        ← App-wide constants, tech lists
│   │   │   └── route_constants.dart      ← Route paths
│   │   ├── providers/
│   │   │   └── theme_provider.dart       ← Dark/Light mode state
│   │   ├── router/
│   │   │   └── app_router.dart           ← GoRouter config + auth guard
│   │   └── theme/
│   │       └── app_theme.dart            ← Monochrome Material theme
│   │
│   ├── shared/
│   │   └── widgets/
│   │       ├── glass_widgets.dart        ← GlassContainer, GlassCard, GlassButton, GlassTextField
│   │       └── animated_background.dart  ← Animated orbs + grid background
│   │
│   └── features/
│       ├── auth/
│       │   ├── domain/models/auth_user.dart
│       │   ├── data/repositories/auth_repository.dart
│       │   ├── providers/auth_provider.dart
│       │   └── presentation/screens/
│       │       ├── splash_screen.dart
│       │       ├── onboarding_screen.dart
│       │       ├── login_screen.dart
│       │       └── register_screen.dart
│       │
│       ├── home/
│       │   └── presentation/screens/
│       │       ├── home_screen.dart      ← Shell + glass bottom nav
│       │       └── home_dashboard.dart   ← Dashboard content
│       │
│       ├── profile/
│       │   ├── domain/models/developer_profile.dart  ← Profile, Skill, Certificate, Link models
│       │   ├── data/repositories/profile_repository.dart
│       │   ├── providers/profile_provider.dart
│       │   └── presentation/screens/
│       │       ├── profile_screen.dart
│       │       └── edit_profile_screen.dart
│       │
│       ├── skills/
│       │   └── presentation/screens/skills_screen.dart   ← Skills + Certificates tabs
│       │
│       ├── links/
│       │   └── presentation/screens/links_screen.dart
│       │
│       └── projects/
│           ├── domain/models/project.dart   ← Project, ProjectWeek, ProjectTask models
│           ├── data/repositories/project_repository.dart
│           ├── providers/project_provider.dart  ← Includes RoadmapGenerator
│           └── presentation/screens/
│               ├── projects_screen.dart
│               ├── create_project_screen.dart
│               ├── project_detail_screen.dart
│               ├── project_timeline_screen.dart
│               └── project_tasks_screen.dart    ← Drag & drop Kanban
│
├── assets/
│   ├── fonts/                ← JetBrainsMono + Syne fonts go here
│   ├── images/
│   ├── icons/
│   └── animations/
│
├── firestore.rules
└── pubspec.yaml
```

---

## 🚀 Setup Instructions

### Step 1 — Create the project

```bash
flutter create developer_os
cd developer_os
```

### Step 2 — Copy files

Replace the generated files with all files from this project. Paste each file exactly as provided.

### Step 3 — Download fonts

Download from Google Fonts and place in `assets/fonts/`:

**JetBrains Mono:**
- https://fonts.google.com/specimen/JetBrains+Mono
- Files needed: JetBrainsMono-Regular.ttf, JetBrainsMono-Bold.ttf, JetBrainsMono-Light.ttf, JetBrainsMono-Medium.ttf

**Syne:**
- https://fonts.google.com/specimen/Syne
- Files needed: Syne-Regular.ttf, Syne-Bold.ttf, Syne-ExtraBold.ttf

### Step 4 — Create asset folders

```bash
mkdir -p assets/fonts assets/images assets/icons assets/animations
```

Place a `google.png` icon (48x48) in `assets/icons/` for the Google sign-in button.

### Step 5 — Set up Firebase

1. Go to https://console.firebase.google.com
2. Create a new project named `developer-os`
3. Enable **Authentication** → Sign-in methods:
   - Email/Password ✓
   - Google ✓
4. Enable **Cloud Firestore** (start in test mode, then apply the `firestore.rules`)
5. Enable **Firebase Storage**
6. Install FlutterFire CLI and configure:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

This auto-generates `lib/firebase_options.dart` with your real values.

**For Android Google Sign-In:**
- Download `google-services.json` from Firebase Console
- Place it at `android/app/google-services.json`

**For iOS Google Sign-In:**
- Download `GoogleService-Info.plist`
- Add it to `ios/Runner/` in Xcode
- Add `GIDClientID` to `ios/Runner/Info.plist`:
```xml
<key>GIDClientID</key>
<string>YOUR_REVERSED_CLIENT_ID</string>
```

### Step 6 — Add dependencies to android/build.gradle

In `android/build.gradle`:
```groovy
buildscript {
  dependencies {
    classpath 'com.google.gms:google-services:4.4.0'
  }
}
```

In `android/app/build.gradle`:
```groovy
apply plugin: 'com.google.gms.google-services'

android {
    compileSdkVersion 34
    defaultConfig {
        minSdkVersion 21
        targetSdkVersion 34
    }
}
```

### Step 7 — Get packages

```bash
flutter pub get
```

### Step 8 — Run the app

```bash
flutter run
```

---

## 🔑 Features Guide

### Authentication
- **Email/Password**: Standard login and registration
- **Google Sign-In**: One-tap Google auth
- **Logout**: Available from the dashboard header

### Developer Profile
- Edit via the **Profile** tab → **EDIT** button
- Set: name, bio, specialization, experience level, location, website
- Select your tech stack (multiple categories)

### Skills & Certificates
- **Skills tab**: Add skills with category + 1-5 proficiency rating. Swipe left to delete.
- **Certificates tab**: Add credentials with issuer and credential URL. Swipe left to delete.

### Developer Links
- Add all your social/developer profiles
- Tap any link to open in browser
- Copy button for quick clipboard copy
- Swipe left to delete

### Projects Archive
- All your projects in one list
- Swipe left to delete (with confirmation)
- Filter by status

### Create Project (Smart Creator)
1. Fill name and description
2. Select project type
3. Select target platform
4. **Select tech stack** → roadmap auto-generates from this
5. Add optional GitHub/demo links
6. Hit **Create + Generate Roadmap**

### Project Timeline (Auto Roadmap)
- Week-by-week roadmap generated from your tech stack
- Tap any week to toggle completion ✓
- Progress bar updates automatically

### Project Task Board (Kanban)
- 3 columns: **To Do**, **In Progress**, **Done**
- **Drag & drop** tasks between columns
- Set priority: Low, Medium, High
- Swipe task's ✕ to delete

---

## 🎨 Design System

| Token | Value |
|-------|-------|
| Primary font | Syne (headings, titles) |
| Code font | JetBrainsMono (body, labels) |
| Dark background | `#0A0A0A` |
| Light background | `#E8E8E8` |
| Glass opacity | `0.07–0.15` |
| Glass blur | `10–20px` |
| Border radius | `12–16px` |
| Animations | flutter_animate |

---

## 🔧 Firestore Data Structure

```
users/{uid}
  - name, email, bio, specialization, experienceLevel
  - techSkills[], location, website, photoURL
  /skills/{id}      → name, category, proficiency
  /certificates/{id} → title, issuer, credentialUrl, issuedDate
  /links/{id}       → type, label, url

projects/{id}
  - uid, name, description, techStack[], projectType, targetPlatform
  - status, startDate, endDate, githubUrl, demoUrl
  - roadmap[] → {weekNumber, title, description, tasks[], completed}
  /tasks/{id}       → title, description, status, priority, dueDate
```

---

## 📦 Key Dependencies

| Package | Purpose |
|---------|---------|
| flutter_riverpod | State management |
| go_router | Navigation + auth guard |
| firebase_auth | Authentication |
| cloud_firestore | Database |
| google_sign_in | Google OAuth |
| flutter_animate | Animations |
| hive_flutter | Local preferences |
| timeline_tile | Roadmap timeline |
| percent_indicator | Skill bars |
| font_awesome_flutter | Link icons |
| url_launcher | Open links |
| uuid | Unique IDs |
| cached_network_image | Profile photos |

---

## ⚡ Quick Terminal Commands

```bash
# Create all asset directories
mkdir -p assets/{fonts,images,icons,animations}

dart pub global activate flutterfire_cli
flutterfire configure
dart run build_runner build --delete-conflicting-outputs

# Run on specific device
flutter run -d android
flutter run -d ios
flutter run -d chrome

# Build APK
flutter build apk --release

# Build iOS
flutter build ios --release
```
