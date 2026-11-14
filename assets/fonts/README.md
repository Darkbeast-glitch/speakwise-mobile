# Visby CF Font Assets

The app is now configured to use **Visby CF** as its primary typeface (`AppTheme.fontFamily = 'Visby CF'`).

Because **Visby CF** is a commercial typeface by Connary Fagen (not an open-source Google Font), its font files (`.otf` or `.ttf`) must be placed in this folder.

### Steps to activate your Visby CF font files:

1. Copy your Visby CF font files into this folder (`assets/fonts/`), for example:
   - `VisbyCF-Regular.otf`
   - `VisbyCF-Medium.otf`
   - `VisbyCF-DemiBold.otf`
   - `VisbyCF-Bold.otf`
   - `VisbyCF-ExtraBold.otf`
   - `VisbyCF-Heavy.otf`

2. Open `pubspec.yaml` and add the `fonts` section under `flutter:`:

```yaml
flutter:
  uses-material-design: true

  assets:
    - assets/images/
    - assets/fonts/
    - .env

  fonts:
    - family: Visby CF
      fonts:
        - asset: assets/fonts/VisbyCF-Regular.otf
          weight: 400
        - asset: assets/fonts/VisbyCF-Medium.otf
          weight: 500
        - asset: assets/fonts/VisbyCF-DemiBold.otf
          weight: 600
        - asset: assets/fonts/VisbyCF-Bold.otf
          weight: 700
        - asset: assets/fonts/VisbyCF-ExtraBold.otf
          weight: 800
        - asset: assets/fonts/VisbyCF-Heavy.otf
          weight: 900
```

3. Run:
   ```bash
   fvm flutter pub get
   ```

*Note: While Visby CF font files are not present in the bundle, the app automatically and gracefully falls back to **Plus Jakarta Sans** (the closest matching geometric rounded typeface on Google Fonts) and Inter, ensuring the app continues running cleanly.*

