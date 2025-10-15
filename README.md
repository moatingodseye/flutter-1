# Flutter Timesheet — Full application (Dart + Flutter)

This archive contains a Flutter web frontend and a Dart server backend for a timesheet application.

**Included enhancements**
- Full CRUD endpoints for users, projects, and time entries (create/read/update/delete).
- Frontend API client methods for CRUD operations.
- Frontend project UI with edit/delete.
- Reports view with PDF export (client-side download via AnchorElement).
- GitHub Actions workflow for analysis, tests and web build.

See `server/` and `frontend/` folders for details.

To run locally, follow instructions in the original canvas doc or run the server:
```
cd server
dart pub get
dart run bin/server.dart
```
and build the frontend:
```
cd frontend
flutter pub get
flutter build web
```
