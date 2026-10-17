# Tawazon

Tawazon is a Flutter digital-wellbeing app with a focus garden, a general AI
assistant, and an optional Android phone-usage reminder.

## Run

```bash
flutter pub get
flutter run
```

## Android phone-usage reminder

In **Settings**, enable **Phone usage alert** and grant both requested accesses:

- **Notifications** (runtime permission on Android 13 and newer).
- **Usage Access** (Android Settings → Special app access → Usage access).

The reminder checks on-device Android usage statistics and sends at most one
notification per day after 4 hours of foreground phone use. Android schedules
the check inexactly (about every 15 minutes), so Doze mode or manufacturer
battery controls can delay it. Usage data is not sent to Gemini. This feature
currently exists only on Android.

## Prayer-time location

On the Prayer Times screen, tap **Use my current location** to grant
foreground location access and calculate prayer times for the device's
location. The app requests coarse/fine location only while the user is in the
app; it does not request background location. Coordinates are saved locally
and used on-device. If location is denied or unavailable, prayer times use
Damanhour, Egypt. The full daily prayer schedule appears below the location,
alert, and next-prayer cards.

## Gemini assistant

Add a Gemini API key in the app's Settings to enable online general-purpose
text chat. Internet access is required; without it, the local wellbeing
responses are limited.

The key entered in Settings is stored on the device and the app calls Gemini
directly. Client-side keys can be extracted from a distributed app; do not ship
a private production key in the app. A production release should proxy requests
through a secured backend and apply provider-side restrictions to any temporary
development key.