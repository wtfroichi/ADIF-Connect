# AndénLibre

**A mobile companion for checking train services and keeping rail tickets together.**

[Le esta páxina en galego](README.md)

AndénLibre is a Flutter application for iOS, Android, and Web. It can import tickets, show live departures and arrivals when the service is available, and surface trip information through supported widgets and live activities.

> **Project status:** in development. Data availability and accuracy depend on external services. Always verify travel information against official station boards and the original ticket.

## Features

- **Local ticket wallet:** save and organize tickets on the device.
- **Ticket import:**
  - Apple Wallet `.pkpass` files.
  - PDF tickets, with text extraction for recognized layouts.
  - Manual ticket entry.
  - Opening or receiving shared files on supported platforms.
- **Ticket parsing:** extracts fields such as origin, destination, times, train, coach, seat, booking reference, and barcode when present in the document.
- **Live boards:** retrieve station departures and arrivals through the Supabase Edge Function included in this repository.
- **Widgets and trip tracking:** station departures widgets on iOS and Android; an iOS Live Activity and an ongoing trip notification on Android.
- **Google Wallet on Android:** experimental import of Save to Google Wallet links when the converter can recognize their data.
- **Platform-aware design:** Galician interface and Liquid Glass surfaces on iOS.

AndénLibre does not include fabricated tickets or schedules. If a station has no data or a service is unavailable, the app cannot guarantee that board information will be shown.

## Requirements

- Flutter and Dart versions compatible with [`pubspec.yaml`](pubspec.yaml).
- **iOS:** iOS 18 minimum deployment target; Xcode to build and sign the app.
- **Android:** Android SDK 36 and Java 17 for the current Gradle setup.
- Network access for live station boards.
- A Supabase project that you can access to deploy the board function.

Live Activities require a compatible iOS device and the relevant system settings to be enabled. Persistent Android notifications may require notification permission, depending on the OS version.

## Getting started

This repository uses Git LFS for some large files. Install it before cloning so those files are checked out correctly:

```sh
git lfs install
git clone https://github.com/wtfroichi/ADIF-Connect.git
cd ADIF-Connect
git lfs pull
flutter pub get
```

Run the app:

```sh
flutter run
```

### Run checks

```sh
flutter analyze
flutter test
```

### Build

```sh
# Android
flutter build apk --release
flutter build appbundle --release

# iOS; Xcode signing configuration is required for distribution
flutter build ios --release
```

To check an unsigned iOS build:

```sh
flutter build ios --no-codesign
```

## Supabase live boards

The `adif-board` Edge Function queries external train-service sources and caches board data. Persistent caching uses the database migration in this repository; the function also maintains a short-lived in-memory cache. External sources and their formats may change without notice.

1. Install and authenticate with the [Supabase CLI](https://supabase.com/docs/guides/cli).
2. Link your project and apply the migration:

   ```sh
   supabase login
   supabase link --project-ref YOUR_PROJECT_REF
   supabase db push
   ```

3. Deploy the function:

   ```sh
   supabase functions deploy adif-board
   ```

4. Provide the project URL and public client key when running or building Flutter:

   ```sh
   flutter run \
     --dart-define=SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co \
     --dart-define=SUPABASE_ANON_KEY=YOUR_PUBLIC_CLIENT_KEY
   ```

   Add the same `--dart-define` values to a `flutter build` command when building the app.

Never include `service_role` keys or other secrets in the mobile client, repository, or app-distributed build arguments. A client key does not replace server-side access policies.

## Import support and known limitations

- **PDF:** the parser recognizes common Renfe ticket fields and station abbreviations. Android uses PDF text extraction; image-only scanned documents may not be readable. On iOS, OCR is available when the document does not yield enough extractable text.
- **Barcodes:** generated only when the ticket contains a number or payload the app can identify. No barcode is fabricated when that information is missing.
- **Google Wallet:** experimental support. The app interprets selected fields in a JWT and only creates a ticket when it can resolve the stations and times; it does not verify the JWT signature or guarantee compatibility with every object type.
- **Train services:** the function relies on external sources outside this project's control. Some stations may have no data, updates may be delayed, and the service may change.
- **Displayed information:** platforms are not inferred; when a platform is not supplied, it is shown as pending or unassigned.

## Project layout

```text
lib/
  core/                 Shared constants, theme, and components
  features/             Home, ticket wallet, live boards, and settings
  models/               Ticket and train-service models
  services/             Import, storage, and external integrations
ios/
  Runner/               iOS app and native integrations
  TrainLiveActivity/    Departures widget and Live Activity
  ShareExtension/       Shared-content receiver
android/
  app/                  Android app, widget, and native integrations
supabase/
  functions/adif-board/ Train-board Edge Function
  migrations/           Board-cache schema
```

## Privacy and data

Saved tickets are persisted locally on the device using preferences storage. Live-board requests send a station code to the Supabase function; ticket data is not part of that request. Operating-system integrations may share the data needed with the local extension or widget to display a trip.

Review the policies and terms of external services before using the app with sensitive information.

## Contributing

Contributions are welcome. For code changes:

1. Keep all user-facing interface strings in normative Galician.
2. Do not add fabricated tickets or schedules.
3. Run `flutter analyze` and `flutter test` before opening a change.
4. Do not commit credentials or private files.

---

AndénLibre is an independent application with no official connection or affiliation with ADIF, RENFE, IRYO, or OUIGO. Schedules and positions come from public open sources.
