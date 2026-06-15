import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'package:google_sign_in/google_sign_in.dart';
import 'app_navigator.dart';
import 'data/services/notification_service.dart';
import 'data/services/task_reminder_notification_background.dart';
import 'ui/widgets/auth_wrapper.dart';
import 'ui/theme/app_theme.dart';
import 'ui/theme/theme_mode_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await GoogleSignIn.instance.initialize(
    serverClientId: '104211948965-1s1m1iiekihfu8pmn7su584pk57cnu.apps.googleusercontent.com',
  );

  final notificationService = NotificationService();
  await notificationService.initialize(
    onDidReceiveBackgroundNotificationResponse:
        taskReminderNotificationBackground,
  );
  await notificationService.loadAppLaunchNotification();

  runApp(
    ProviderScope(
      overrides: [
        notificationServiceProvider.overrideWithValue(notificationService),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      navigatorKey: rootNavigatorKey,
      title: 'Exm To-Do',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ref.watch(themeModeProvider),
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const AuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}
