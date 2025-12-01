# Dark Mode Implementation Guide

## 🌙 Overview

Dark mode đã được implement hoàn chỉnh cho Advanced Financial Management System. Users có thể switch giữa light mode, dark mode, hoặc follow system theme.

## 📦 Setup

### 1. Add Dependency

Thêm vào `mobile/pubspec.yaml`:
```yaml
dependencies:
  shared_preferences: ^2.2.0
```

Chạy:
```bash
cd mobile
flutter pub get
```

### 2. Files Created/Modified

**Created:**
- `mobile/lib/providers/theme_provider.dart` - Theme state management
- `mobile/lib/core/theme/app_theme.dart` - Updated với dark theme

**Modified:**
- `mobile/lib/main.dart` - Integrated theme provider

## 🎨 Theme Colors

### Light Mode:
```dart
Background: #F5F5F5
Surface: #FFFFFF
Primary: #7C3AED (Purple)
Text Primary: #1A1A1A
Text Secondary: #666666
Border: #E0E0E0
```

### Dark Mode:
```dart
Background: #121212
Surface: #1E1E1E
Input Fields: #2C2C2C
Borders: #3C3C3C
Primary: #7C3AED (Same as light)
Text Primary: #FFFFFF
Text Secondary: #B0B0B0
```

## 💻 Usage

### In Any Widget:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/theme_provider.dart';

class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get current theme mode
    final themeMode = ref.watch(themeModeProvider);
    
    // Check if dark mode is active
    final isDark = ref.watch(isDarkModeProvider);
    
    // Toggle theme
    onPressed: () {
      ref.read(themeModeProvider.notifier).toggleTheme();
    }
    
    // Set specific theme
    onPressed: () {
      ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.dark);
    }
  }
}
```

### Theme Toggle Button Example:

```dart
IconButton(
  icon: Icon(
    isDark ? Icons.light_mode : Icons.dark_mode,
  ),
  onPressed: () {
    ref.read(themeModeProvider.notifier).toggleTheme();
  },
)
```

### Settings Screen Example:

```dart
ListTile(
  leading: Icon(Icons.palette),
  title: Text('Theme'),
  subtitle: Text(
    themeMode == ThemeMode.system
        ? 'System'
        : themeMode == ThemeMode.light
            ? 'Light'
            : 'Dark',
  ),
  trailing: DropdownButton<ThemeMode>(
    value: themeMode,
    items: [
      DropdownMenuItem(
        value: ThemeMode.system,
        child: Text('System'),
      ),
      DropdownMenuItem(
        value: ThemeMode.light,
        child: Text('Light'),
      ),
      DropdownMenuItem(
        value: ThemeMode.dark,
        child: Text('Dark'),
      ),
    ],
    onChanged: (mode) {
      if (mode != null) {
        ref.read(themeModeProvider.notifier).setThemeMode(mode);
      }
    },
  ),
)
```

## 🎯 Features

### 1. Theme Persistence
Theme preference được lưu trong SharedPreferences và persist across app restarts.

### 2. System Theme Detection
Khi chọn "System", app sẽ tự động follow system theme của device.

### 3. Smooth Transitions
Theme changes are animated smoothly by Flutter framework.

### 4. Consistent Branding
Primary color (purple) giữ nguyên trong cả light và dark mode để maintain brand identity.

## 🔧 Customization

### Change Dark Mode Colors:

Edit `mobile/lib/core/theme/app_theme.dart`:

```dart
static ThemeData get darkTheme {
  return ThemeData(
    // ... existing code
    scaffoldBackgroundColor: const Color(0xFF121212), // Change this
    colorScheme: const ColorScheme.dark(
      surface: Color(0xFF1E1E1E), // Change this
      // ... other colors
    ),
  );
}
```

### Add Custom Theme:

```dart
// In theme_provider.dart
enum CustomTheme {
  light,
  dark,
  amoled, // Pure black for AMOLED screens
  highContrast,
}

// In app_theme.dart
static ThemeData get amoledTheme {
  return ThemeData(
    scaffoldBackgroundColor: Colors.black, // Pure black
    // ... rest of theme
  );
}
```

## 📱 Testing

### Test Light Mode:
1. Open app
2. Go to Settings
3. Select "Light" theme
4. Verify all screens use light colors

### Test Dark Mode:
1. Open app
2. Go to Settings
3. Select "Dark" theme
4. Verify all screens use dark colors

### Test System Theme:
1. Open app
2. Go to Settings
3. Select "System" theme
4. Change device theme in system settings
5. Verify app follows system theme

### Test Persistence:
1. Change theme
2. Close app completely
3. Reopen app
4. Verify theme is still the same

## 🐛 Troubleshooting

### Issue: Theme not persisting
**Solution:** Make sure SharedPreferences is properly initialized:
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SharedPreferences.getInstance(); // Initialize
  runApp(MyApp());
}
```

### Issue: Colors not updating
**Solution:** Make sure you're using `Theme.of(context)` or watching the provider:
```dart
// Good
color: Theme.of(context).colorScheme.primary

// Also good
final isDark = ref.watch(isDarkModeProvider);
color: isDark ? Colors.white : Colors.black
```

### Issue: System theme not detected
**Solution:** Check platform brightness:
```dart
final brightness = MediaQuery.of(context).platformBrightness;
final isDark = brightness == Brightness.dark;
```

## 🎨 Design Guidelines

### Do's:
✅ Use theme colors from `Theme.of(context)`
✅ Test both light and dark modes
✅ Ensure sufficient contrast
✅ Use semantic colors (primary, secondary, error)
✅ Keep brand colors consistent

### Don'ts:
❌ Hardcode colors (use theme colors)
❌ Use pure white on pure black (use #1E1E1E)
❌ Forget to test dark mode
❌ Use too many different colors
❌ Ignore accessibility

## 📊 Accessibility

### Contrast Ratios:
- Light mode: 4.5:1 minimum
- Dark mode: 4.5:1 minimum
- Large text: 3:1 minimum

### Testing Tools:
- Flutter DevTools
- Accessibility Scanner
- Color Contrast Analyzer

## 🚀 Future Enhancements

### Planned:
- [ ] Custom color themes
- [ ] AMOLED black theme
- [ ] High contrast theme
- [ ] Color blind friendly themes
- [ ] Theme preview before applying
- [ ] Scheduled theme switching
- [ ] Per-screen theme override

## 📝 Code Examples

### Complete Settings Screen with Theme Toggle:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/theme_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = ref.watch(isDarkModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // Theme Section
          ListTile(
            leading: Icon(
              isDark ? Icons.dark_mode : Icons.light_mode,
            ),
            title: const Text('Appearance'),
            subtitle: Text(
              themeMode == ThemeMode.system
                  ? 'System default'
                  : themeMode == ThemeMode.light
                      ? 'Light mode'
                      : 'Dark mode',
            ),
          ),
          RadioListTile<ThemeMode>(
            title: const Text('Light'),
            value: ThemeMode.light,
            groupValue: themeMode,
            onChanged: (mode) {
              if (mode != null) {
                ref.read(themeModeProvider.notifier).setThemeMode(mode);
              }
            },
          ),
          RadioListTile<ThemeMode>(
            title: const Text('Dark'),
            value: ThemeMode.dark,
            groupValue: themeMode,
            onChanged: (mode) {
              if (mode != null) {
                ref.read(themeModeProvider.notifier).setThemeMode(mode);
              }
            },
          ),
          RadioListTile<ThemeMode>(
            title: const Text('System default'),
            value: ThemeMode.system,
            groupValue: themeMode,
            onChanged: (mode) {
              if (mode != null) {
                ref.read(themeModeProvider.notifier).setThemeMode(mode);
              }
            },
          ),
        ],
      ),
    );
  }
}
```

## ✅ Checklist

Before deploying dark mode:
- [x] Light theme implemented
- [x] Dark theme implemented
- [x] System theme detection
- [x] Theme persistence
- [x] Theme provider created
- [x] Main app integrated
- [ ] All screens tested in dark mode
- [ ] Contrast ratios verified
- [ ] Accessibility tested
- [ ] User documentation created

---

**Status:** ✅ Implemented and ready to use
**Version:** 1.0.0
**Last Updated:** December 2024
