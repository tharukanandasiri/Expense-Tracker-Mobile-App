# expense_tracker_mobile_app

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- VaultSync

VaultSync is a Flutter expense tracker. It helps users record, search, compare, and manage personal expenses.

## Features

- Add, edit, and delete expenses.
- Store expenses in Firebase Firestore.
- Sign in with email/password or Google.
- Show the current month's total.
- Filter by category and date.
- Search by title, note, or category.
- Swipe or long-press an expense to edit or delete it.
- Show up to 10 recent expenses at a time with a See more option.
- Undo a recent delete action.
- Compare two months in the Insights screen.
- Compare spending by category with a bar chart.
- Use light, dark, or system theme mode.
- Select LKR, USD, or EUR display currency.
- Refresh and cache exchange rates.
- Use English, Sinhala, or Tamil.
- Reset all expense history after confirmation.
- Responsive layout for mobile and web.

## Technologies

- Flutter and Dart
- Firebase Core
- Firebase Authentication
- Cloud Firestore
- Google Sign-In
- Shared Preferences
- FL Chart
- Flutter Slidable
- Flutter Localizations
- HTTP

## Project Structure

```text
lib/
	core/
		localization/
		settings/
		theme/
		widgets/
	features/
		auth/
		expenses/
		navigation/
```

The app uses separate data, domain, and presentation layers for the main features.

## Requirements

Install these tools before setup:

- Flutter SDK
- Dart SDK
- Node.js and npm
- Firebase CLI
- FlutterFire CLI

Check Flutter:

```powershell
flutter doctor
```

## Local Setup

Clone the project and open its folder:

```powershell
cd T:\Work\expense_tracker_mobile_app
```

Install packages:

```powershell
flutter pub get
```

Run the analyzer and tests:

```powershell
flutter analyze
flutter test
```

Run the app:

```powershell
flutter run
```

To run the web version:

```powershell
flutter run -d chrome
```

## Firebase Setup

1. Create a project in the [Firebase Console](https://console.firebase.google.com).
2. Register an Android app with this package name:

```text
com.example.expense_tracker_mobile_app
```

3. Enable Cloud Firestore.
4. Enable Email/Password in **Authentication > Sign-in method**.
5. Enable Google in **Authentication > Sign-in method**.
6. Add the Android debug SHA-1 fingerprint in Firebase Project Settings.
7. Install and sign in to the Firebase CLI:

```powershell
npm install -g firebase-tools
firebase login
```

8. Install FlutterFire CLI:

```powershell
dart pub global activate flutterfire_cli
```

9. Configure the app:

```powershell
flutterfire configure
```

This creates or updates:

```text
lib/firebase_options.dart
android/app/google-services.json
```

## Firestore Data

Expenses are stored under the signed-in user's account:

```text
users/{userId}/expenses/{expenseId}
```

Deploy the security rules:

```powershell
firebase deploy --project expense-tracker-mobile-a-eab13 --only firestore:rules
```

The rules allow users to read and write only their own expenses.

## Currency Rates

Expense amounts are stored using LKR as the base currency. The app can display amounts in LKR, USD, or EUR.

The app tries to fetch current rates when it starts. If the network is unavailable, it uses cached or fallback rates.

Changing the display currency does not change the stored expense value.

## Languages

The app supports:

- English
- Sinhala
- Tamil

The selected language is saved on the device. Date and Material UI text also use the selected locale.

## Build a Release APK

```powershell
flutter clean
flutter pub get
flutter build apk --release
```

The APK is created in:

```text
build/app/outputs/flutter-apk/app-release.apk
```

Build an Android App Bundle:

```powershell
flutter build appbundle --release
```

Build the web app:

```powershell
flutter build web
```

## Testing

Run all tests:

```powershell
flutter test
```

The tests cover authentication validation, expense models, filtering, responsive layouts, theme settings, and monthly comparison charts.

## AI Tools Used

GitHub Copilot was used during development.

It helped with:

- Planning the app in small development phases.
- Writing Firebase and Firestore integration code.
- Finding and fixing layout overflow errors.
- Adding localization, theme settings, search, filters, and charts.
- Creating tests and checking analyzer errors.

All generated code was reviewed, tested, and adjusted during development.

## License

This project is for the CyphLab Flutter Developer Internship task.

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
