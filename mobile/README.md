# Financial Management Mobile App

Advanced Financial Management Mobile Application built with Flutter.

## Setup

1. Install Flutter SDK (3.0.0 or higher)

2. Install dependencies:
```bash
flutter pub get
```

3. Run code generation:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## Development

```bash
flutter run
```

## Testing

```bash
flutter test
```

## Build

### Android
```bash
flutter build apk
```

### iOS
```bash
flutter build ios
```

## Project Structure

```
lib/
├── core/           # Core utilities and configuration
├── models/         # Data models
├── services/       # API and local services
├── providers/      # Riverpod state management
├── screens/        # Screen widgets
├── widgets/        # Reusable widgets
└── main.dart       # Application entry point
```

## Features

- Bank account connection via OAuth2
- Automatic transaction synchronization
- Smart transaction categorization
- Budget management with alerts
- Spending analytics and reports
- Financial forecasting
- Interactive charts and visualizations
