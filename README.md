# Main Project

A Flutter application for managing contacts, leads, and tasks.

## Getting Started

### Prerequisites

- Flutter SDK (version 3.24.0 or later)
- Dart SDK (comes with Flutter)
- Android Studio or VS Code with Flutter extensions
- For iOS development: macOS with Xcode

### Local Setup

1. **Clone the repository:**
   ```bash
   git clone <repository-url>
   cd main_project
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Verify setup:**
   ```bash
   flutter doctor
   ```

4. **Run the app:**
   - For Android: `flutter run`
   - For iOS: `flutter run` (on macOS)
   - For Web: `flutter run -d chrome`
   - For Desktop: `flutter run -d windows` or `flutter run -d macos`

### Development Workflow

- **Linting:** `flutter analyze`
- **Formatting:** `flutter format .`
- **Testing:** `flutter test`
- **Building:** `flutter build apk` or `flutter build ios`

### Branching Strategy

- `main`: Production-ready code
- `develop`: Integration branch
- Feature branches: `feat/feature-name`
- Bug fixes: `fix/bug-description`

See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed contribution guidelines.

### Architecture

See [docs/architecture.md](docs/architecture.md) for high-level architecture overview.
