import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:emotion_sense/ui/camera_view.dart';
import 'package:emotion_sense/presentation/screens/onboarding_screen.dart';
import 'package:provider/provider.dart';
import 'package:emotion_sense/presentation/providers/history_provider.dart';
import 'package:emotion_sense/data/repositories/history_repository.dart';
import 'package:emotion_sense/presentation/providers/settings_provider.dart';
import 'package:emotion_sense/presentation/providers/camera_provider.dart';

/// App color constants matching the dark UI design.
class AppColors {
  AppColors._();

  static const Color background = Color(0xFF0D0D1A);
  static const Color surface = Color(0xFF1A1A2E);
  static const Color surfaceLight = Color(0xFF252540);
  static const Color primary = Color(0xFF4D7CFE);
  static const Color primaryLight = Color(0xFF6B8FFF);
  static const Color accent = Color(0xFF00E676);
  static const Color accentGold = Color(0xFFFFD700);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0C8);
  static const Color textTertiary = Color(0xFF6B6B8A);
  static const Color danger = Color(0xFFFF4D6A);
  static const Color cardBorder = Color(0xFF2A2A45);
  static const Color overlay = Color(0xCC000000);

  // Emotion colors
  static const Color happy = Color(0xFF00E676);
  static const Color sad = Color(0xFF448AFF);
  static const Color angry = Color(0xFFFF5252);
  static const Color surprised = Color(0xFFE040FB);
  static const Color neutral = Color(0xFF9E9E9E);
  static const Color funny = Color(0xFF69F0AE);
}

class EmotionApp extends StatelessWidget {
  const EmotionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => CameraProvider()),
        ChangeNotifierProvider(
            create: (_) => HistoryProvider(HistoryRepository())),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          final textTheme = GoogleFonts.poppinsTextTheme(
            ThemeData.dark().textTheme,
          );

          return MaterialApp(
            title: 'EmotionSense',
            debugShowCheckedModeBanner: false,
            themeMode: ThemeMode.dark,
            darkTheme: ThemeData(
              brightness: Brightness.dark,
              scaffoldBackgroundColor: AppColors.background,
              colorScheme: const ColorScheme.dark(
                primary: AppColors.primary,
                secondary: AppColors.accent,
                surface: AppColors.surface,
                error: AppColors.danger,
                onPrimary: Colors.white,
                onSecondary: Colors.black,
                onSurface: AppColors.textPrimary,
              ),
              textTheme: textTheme,
              appBarTheme: AppBarTheme(
                backgroundColor: Colors.transparent,
                elevation: 0,
                centerTitle: true,
                titleTextStyle: textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                iconTheme: const IconThemeData(color: AppColors.textPrimary),
              ),
              cardTheme: CardThemeData(
                color: AppColors.surface,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppColors.cardBorder, width: 1),
                ),
              ),
              switchTheme: SwitchThemeData(
                thumbColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return AppColors.primary;
                  }
                  return AppColors.textTertiary;
                }),
                trackColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return AppColors.primary.withValues(alpha: 0.4);
                  }
                  return AppColors.surfaceLight;
                }),
              ),
              sliderTheme: SliderThemeData(
                activeTrackColor: AppColors.primary,
                inactiveTrackColor: AppColors.surfaceLight,
                thumbColor: AppColors.primary,
                overlayColor: AppColors.primary.withValues(alpha: 0.2),
                valueIndicatorColor: AppColors.primary,
              ),
              useMaterial3: true,
            ),
            home: settings.hasSeenOnboarding
                ? const CameraView()
                : const OnboardingScreen(),
          );
        },
      ),
    );
  }
}
