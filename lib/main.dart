import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:todo_list/app_settings.dart';
import 'package:todo_list/l10n/app_localizations.dart';
import 'package:todo_list/shared/services/auth_service.dart';
import 'package:todo_list/shared/services/category_services.dart';
import 'package:todo_list/shared/services/notification_service.dart';
import 'package:todo_list/shared/services/task_services.dart';
import 'package:todo_list/shared/view/mainpage.dart';
import 'package:todo_list/view/loginpage.dart';
import 'firebase_options.dart';
import 'theme_data.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await AppSettings.instance.load();
  FirebaseFirestore.instance.settings = const Settings();
  await notificationService.init();
  runApp(const MyApp());
}

/// Root widget — rebuilds on [AppSettings] changes so theme/locale updates
/// propagate instantly without restarting the app.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppSettings.instance,
      builder: (context, _) {
        final settings = AppSettings.instance;
        return MaterialApp(
          locale: settings.locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.buildLightTheme(settings.accentColor),
          darkTheme: AppTheme.buildDarkTheme(settings.accentColor),
          themeMode: settings.materialThemeMode,
          home: const AuthGate(),
        );
      },
    );
  }
}

/// Listens to Firebase auth state and routes to the correct page.
/// Also initialises / clears per-user services on login / logout,
/// and refreshes the localised Default category name whenever the
/// widget rebuilds (e.g., after a locale change).
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Keep the in-memory Default category name in sync with the current locale.
    // This is a no-op when the name hasn't changed, so it's safe to call often.
    categoryServices.updateDefaultName(context);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: authService.authState,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;

        if (user != null) {
          taskServices.init(user.uid);
          categoryServices.init(user.uid, context);
          // groupTaskService is initialised inside MainPage (mainpage.dart)
          return const MainPage();
        }

        taskServices.clear();
        categoryServices.clear(context);
        return const LoginPage();
      },
    );
  }
}