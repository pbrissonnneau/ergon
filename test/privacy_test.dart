import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards the "100% offline" requirement at the source level.
void main() {
  test('application code uses no networking APIs', () {
    final forbidden = RegExp(
      r'HttpClient|HttpServer|WebSocket|RawSocket|SecureSocket|Socket\.connect|ServerSocket|'
      r'package:http/|package:dio/|InternetAddress\.lookup|NetworkInterface|RawDatagramSocket|'
      // `timezone` (required by the notifications plugin) only uses HTTP in its
      // web-only entry point; it must never be imported.
      r'package:timezone/browser\.dart',
    );
    final offenders = <String>[];
    for (final f in Directory('lib').listSync(recursive: true).whereType<File>()) {
      if (!f.path.endsWith('.dart')) continue;
      final lines = f.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (forbidden.hasMatch(lines[i])) offenders.add('${f.path}:${i + 1}: ${lines[i].trim()}');
      }
    }
    expect(offenders, isEmpty);
  });

  test('no analytics, crash-reporting, cloud or HTTP packages are direct dependencies', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final packages = RegExp(r'^  ([a-z0-9_]+):', multiLine: true).allMatches(pubspec).map((m) => m.group(1)!).toSet();
    final banned = RegExp(
      r'^(http|dio|chopper|retrofit|web_socket.*|firebase.*|cloud_.*|sentry.*|amplitude.*|mixpanel.*|'
      r'segment.*|posthog.*|datadog.*|bugsnag.*|appcenter.*|google_mobile_ads|.*analytics.*|.*crashlytics.*|'
      r'supabase.*|appwrite.*|grpc|graphql.*)$',
    );
    expect(packages.where(banned.hasMatch).toList(), isEmpty);
  });

  test('release Android manifest removes the INTERNET permission', () {
    final manifest = File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    expect(manifest, contains('android:name="android.permission.INTERNET" tools:node="remove"'));
  });
}
