# Expense Tracker

A clean Flutter + Firebase expense tracker built for the CyphLab Flutter Developer Internship task.

Beyond the core CRUD requirements, this app adds:
- **Calendar heatmap** of daily spending (GitHub-contribution-graph style)
- **Swipe gestures** to edit/delete expenses, with undo
- **Smart Insight card** — a rule-based comparison of this month vs last month's spending per category

## Tech Stack
- Flutter (Dart)
- Firebase (Cloud Firestore, Firebase Auth)
- `provider` for state management
- `fl_chart` for charts, `table_calendar`-based heatmap for the spending calendar

## Project Structure
```
lib/
  models/       # Data models (Expense)
  services/     # Firestore/Auth calls - isolated from UI
  providers/    # App state (ChangeNotifier) - filtering, aggregation
  screens/      # Full pages (Add/Edit, History, Dashboard)
  widgets/      # Reusable UI pieces
  utils/        # Formatters, insight logic, constants
```

## Setup Instructions
1. **Clone the repo** and run `flutter pub get`.
2. **Create a Firebase project** at https://console.firebase.google.com.
3. **Enable Cloud Firestore** (start in test mode, then lock down with rules — see below) and **enable Firebase Authentication** (Email/Password or Anonymous).
4. Install the FlutterFire CLI and connect this project to your Firebase project:
   ```
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```
   This overwrites `lib/firebase_options.dart` with your project's real config and adds the native config files (`google-services.json` / `GoogleService-Info.plist`).
5. Run the app: `flutter run`.

### Firestore Security Rules (recommended)
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /expenses/{expenseId} {
      allow read, write: if request.auth != null && request.auth.uid == resource.data.userId;
      allow create: if request.auth != null && request.auth.uid == request.resource.data.userId;
    }
  }
}
```

## Features Implemented
_(This section is filled in as each phase is completed — see the project's phase plan.)_
- [x] Firebase (Firestore) data layer with real-time streaming
- [x] Expense model (title, amount, category, date, note)
- [ ] Add / edit / delete expenses with validation
- [ ] Expense history list with filtering & search
- [ ] Monthly total, category chart, spending heatmap
- [ ] Smart insight card
- [ ] Dark mode, Firebase Auth, polish

## AI Tools Used
This project was built with the assistance of **Claude** (Anthropic), used for:
- Structuring the project (layered architecture: models/services/providers/screens)
- Brainstorming a differentiating feature set (heatmap, swipe gestures, insight card) 

All generated code was reviewed, tested, and understood before inclusion; I can explain and modify any part of it.

## Demo
- Screen recording: _link here_
- APK: _link here_
