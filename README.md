# agentshuka

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Playstore Instructions

- If you target Android 14+, you must declare your app as a "Calling app" in the Google Play Console to be granted the USE_FULL_SCREEN_INTENT permission. If you don't, the intent will be blocked, and it will just show as a standard notification icon.
- You cannot use a standard .p12 push certificate. You must create a specific VoIP Services Certificate in the Apple Developer Portal and upload it to your backend (or notification provider).