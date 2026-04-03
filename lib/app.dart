import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
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
            home: kIsWeb
                ? const WebPreviewScreen()
                : settings.hasSeenOnboarding
                    ? const CameraView()
                    : const OnboardingScreen(),
          );
        },
      ),
    );
  }
}

class WebPreviewScreen extends StatelessWidget {
  const WebPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.language_rounded,
                        color: AppColors.primary,
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'EmotionSense Web Preview',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'The browser build is running, but the core ML pipeline is still mobile-only in this project. Face detection, emotion, age, gender, and ethnicity analysis currently depend on native packages that do not run on web.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                    ),
                    const SizedBox(height: 20),
                    const _WebStatusRow(
                      icon: Icons.check_circle_rounded,
                      color: AppColors.accent,
                      text: 'Web app shell and navigation are available.',
                    ),
                    const SizedBox(height: 10),
                    const _WebStatusRow(
                      icon: Icons.warning_amber_rounded,
                      color: AppColors.accentGold,
                      text: 'Native ML analysis is disabled on web preview.',
                    ),
                    const SizedBox(height: 10),
                    const _WebStatusRow(
                      icon: Icons.phone_android_rounded,
                      color: AppColors.primary,
                      text:
                          'Full detection still works on Android emulator/device.',
                    ),
                    const SizedBox(height: 28),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        FilledButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const CameraView(),
                              ),
                            );
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                          ),
                          icon: const Icon(Icons.videocam_rounded),
                          label: const Text('Open Camera Preview'),
                        ),
                        OutlinedButton.icon(
                          onPressed: null,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textSecondary,
                            side: const BorderSide(color: AppColors.cardBorder),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                          ),
                          icon: const Icon(Icons.psychology_alt_rounded),
                          label: const Text('Native Analysis Required'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WebStatusRow extends StatelessWidget {
  const _WebStatusRow({
    required this.icon,
    required this.color,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
          ),
        ),
      ],
    );
  }
}
