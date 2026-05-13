import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'package:libretrac/features/home/view/home_screen.dart';
import 'package:libretrac/providers/theme_provider.dart';
import 'package:libretrac/services/mood_widget_service.dart';

// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:libretrac/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

// final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
//     FlutterLocalNotificationsPlugin();

// Future<void> initializeNotifications() async {
//   const AndroidInitializationSettings androidInit =
//       AndroidInitializationSettings('@mipmap/ic_launcher');

//   await flutterLocalNotificationsPlugin.initialize(
//     const InitializationSettings(android: androidInit),
//   );

//   tz.initializeTimeZones();
// }

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await NotificationService.init();
  // await NotificationService.scheduleDailyReminders();

  if (!kIsWeb) {
    await HomeWidget.registerBackgroundCallback(_widgetCallback);
  }

  runApp(ProviderScope(child: const LibreTracApp()));

  // 2 — kick the widget after the first frame so ProviderScope is ready
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!kIsWeb) {
      MoodWidgetService.update();
    }
  });
}

/// Called by the OS when the widget requests an update.
// @pragma('vm:entry-point')
void _widgetCallback(Uri? _) async {
  await MoodWidgetService.update();
}

class LibreTracApp extends ConsumerWidget {
  const LibreTracApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    final seed = ref.watch(accentColorProvider); // updates live

    final lightScheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.light,
    );
    final darkScheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.dark,
      surface: const Color(0xFF000000),
      background: const Color(0xFF000000),
    );

    final lightTheme = ThemeData(
      colorScheme: lightScheme,
      useMaterial3: true,
      dividerColor: lightScheme.primary.withOpacity(0.3),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.all(lightScheme.primary),
        trackColor: MaterialStateProperty.all(
          lightScheme.primary.withOpacity(0.5),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: lightScheme.primary,
        foregroundColor: lightScheme.onPrimary,
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: lightScheme.primary),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: lightScheme.primary,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.all(lightScheme.primary),
      ),
      radioTheme: RadioThemeData(
        fillColor: MaterialStateProperty.all(lightScheme.primary),
      ),
      cardTheme: CardThemeData(
        color: Colors.transparent,
        elevation: 0,
        shadowColor: Colors.transparent,
      ),
      dividerTheme: DividerThemeData(
        color: lightScheme.primary.withOpacity(0.3),
        thickness: 1,
        space: 32,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: lightScheme.primary,
        inactiveTrackColor: lightScheme.primary.withOpacity(0.3),
        thumbColor: lightScheme.primary,
        overlayColor: lightScheme.primary.withOpacity(0.2),
        valueIndicatorColor: lightScheme.primary,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: lightScheme.primary,
        linearTrackColor: lightScheme.primary.withOpacity(0.2),
      ),
      tabBarTheme: TabBarThemeData(
        indicatorColor: lightScheme.primary,
        labelColor: lightScheme.primary,
        unselectedLabelColor: lightScheme.onSurface.withOpacity(0.6),
        indicatorSize: TabBarIndicatorSize.label,
      ),
    );

    final darkTheme = ThemeData(
      colorScheme: darkScheme,
      useMaterial3: true,
      dividerColor: darkScheme.primary.withOpacity(0.3),
      scaffoldBackgroundColor: darkScheme.background,
      appBarTheme: AppBarTheme(
        backgroundColor: darkScheme.background,
        foregroundColor: darkScheme.onSurface,
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: darkScheme.primary),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: darkScheme.primary,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.all(darkScheme.primary),
        trackColor: MaterialStateProperty.all(
          darkScheme.primary.withOpacity(0.5),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.all(darkScheme.primary),
      ),
      radioTheme: RadioThemeData(
        fillColor: MaterialStateProperty.all(darkScheme.primary),
      ),
      cardTheme: CardThemeData(
        color: Colors.transparent,
        elevation: 0,
        shadowColor: Colors.transparent,
      ),

      dividerTheme: DividerThemeData(
        color: darkScheme.primary.withOpacity(0.3),
        thickness: 1,
        space: 32,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: darkScheme.primary,
        inactiveTrackColor: darkScheme.primary.withOpacity(0.3),
        thumbColor: darkScheme.primary,
        overlayColor: darkScheme.primary.withOpacity(0.2),
        valueIndicatorColor: darkScheme.primary,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: darkScheme.primary,
        linearTrackColor: darkScheme.primary.withOpacity(0.2),
      ),
      tabBarTheme: TabBarThemeData(
        indicatorColor: darkScheme.primary,
        labelColor: darkScheme.primary,
        unselectedLabelColor: darkScheme.onSurface.withOpacity(0.6),
        indicatorSize: TabBarIndicatorSize.label,
      ),
    );

    // final lightTheme = ThemeData(
    //   colorScheme: lightScheme,
    //   useMaterial3: true,
    //   appBarTheme: AppBarTheme(
    //     backgroundColor: lightScheme.primary,
    //     foregroundColor: lightScheme.onPrimary,
    //   ),
    //   cardTheme: CardTheme(
    //     color: lightScheme.background,
    //     elevation: 0,
    //     shadowColor: Colors.transparent,
    //   ),
    // );

    // final darkTheme = ThemeData(
    //   colorScheme: darkScheme,
    //   useMaterial3: true,
    //   scaffoldBackgroundColor: darkScheme.background,
    //   appBarTheme: AppBarTheme(
    //     backgroundColor: darkScheme.background,
    //     foregroundColor: darkScheme.onSurface,
    //   ),
    //   textButtonTheme: TextButtonThemeData(
    //     style: TextButton.styleFrom(foregroundColor: darkScheme.primary),
    //   ),
    //   cardTheme: CardTheme(
    //     color: darkScheme.background,
    //     elevation: 0,
    //     shadowColor: Colors.transparent,
    //   ),
    // );

    return ShowCaseWidget(
      builder: (context) {
        return MaterialApp(
          title: 'LibreTrac',
          themeMode: mode,
          theme: lightTheme,
          darkTheme: darkTheme,
          home: const HomeScreen(),
        );
      }
    );
  }
}




// class LibreTracApp extends ConsumerStatefulWidget {
//   const LibreTracApp({super.key});

//   @override
//   ConsumerState<LibreTracApp> createState() => _LibreTracAppState();
// }

// class _LibreTracAppState extends ConsumerState<LibreTracApp> {
//   Color seed = Colors.purple;
//   bool isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     _loadCustomColor();
//   }

//   Future<Color?> getCustomColor(String key) async {
//     final prefs = await SharedPreferences.getInstance();
//     final hex = prefs.getString(key);
//     if (hex == null) return null;
//     try {
//       return Color(int.parse(hex, radix: 16));
//     } catch (_) {
//       return null;
//     }
//   }

//   Future<void> _loadCustomColor() async {
//     final custom = await getCustomColor('primary_seed_color');
//     if (mounted) {
//       setState(() {
//         seed = custom ?? Colors.purple;
//         isLoading = false;
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final mode = ref.watch(themeModeProvider);
//     if (isLoading) return const SizedBox.shrink();

//     final lightScheme = ColorScheme.fromSeed(
//       seedColor: seed,
//       brightness: Brightness.light,
//     );
//     final darkScheme = ColorScheme.fromSeed(
//       seedColor: seed,
//       brightness: Brightness.dark,
//       surface: const Color(0xFF1A1A1A),
//       background: const Color(0xFF121212),
//     );

//     final lightTheme = ThemeData(
//       colorScheme: lightScheme,
//       useMaterial3: true,
//       appBarTheme: AppBarTheme(
//         backgroundColor: lightScheme.primary,
//         foregroundColor: lightScheme.onPrimary,
//       ),
//       cardTheme: CardTheme(
//         color: lightScheme.background,
//         elevation: 0,
//         shadowColor: Colors.transparent,
//       ),
//     );

//     final darkTheme = ThemeData(
//       colorScheme: darkScheme,
//       useMaterial3: true,
//       scaffoldBackgroundColor: darkScheme.background,
//       appBarTheme: AppBarTheme(
//         backgroundColor: darkScheme.background,
//         foregroundColor: darkScheme.onSurface,
//       ),
//       textButtonTheme: TextButtonThemeData(
//         style: TextButton.styleFrom(foregroundColor: darkScheme.primary),
//       ),
//       cardTheme: CardTheme(
//         color: darkScheme.background,
//         elevation: 0,
//         shadowColor: Colors.transparent,
//       ),
//     );

//     return MaterialApp(
//       title: 'LibreTrac',
//       themeMode: mode,
//       theme: lightTheme,
//       darkTheme: darkTheme,
//       home: const HomeScreen(),
//     );
//   }
// }
