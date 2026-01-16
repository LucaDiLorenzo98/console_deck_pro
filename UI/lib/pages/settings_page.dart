import 'package:flutter/material.dart';
import '../theme_state.dart';
import '../locale_state.dart';
import '../l10n/app_translations.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Listen to locale changes to rebuild text
    return ValueListenableBuilder<Locale>(
      valueListenable: localeNotifier,
      builder: (context, currentLocale, child) {
        return Scaffold(
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    AppStrings.get(currentLocale, AppKeys.settings),
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 20),

                  // Theme Switcher
                  ValueListenableBuilder<ThemeMode>(
                    valueListenable: themeNotifier,
                    builder: (context, themeMode, child) {
                      final isDark = themeMode == ThemeMode.dark;
                      return Card(
                        child: SwitchListTile(
                          title: Text(
                            AppStrings.get(
                              currentLocale,
                              isDark ? AppKeys.themeDark : AppKeys.themeLight,
                            ),
                          ),
                          secondary: Icon(
                            isDark ? Icons.dark_mode : Icons.light_mode,
                          ),
                          value: isDark,
                          onChanged: (val) => themeNotifier.toggle(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  // Language Selector
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.language),
                          const SizedBox(width: 16),
                          Text(AppStrings.get(currentLocale, AppKeys.language)),
                          const Spacer(),
                          DropdownButton<String>(
                            value: currentLocale.languageCode,
                            underline: const SizedBox(),
                            items: const [
                              DropdownMenuItem(
                                value: 'en',
                                child: Text('English (EN)'),
                              ),
                              DropdownMenuItem(
                                value: 'it',
                                child: Text('Italiano (IT)'),
                              ),
                              DropdownMenuItem(
                                value: 'es',
                                child: Text('Español (ES)'),
                              ),
                              DropdownMenuItem(
                                value: 'fr',
                                child: Text('Français (FR)'),
                              ),
                              DropdownMenuItem(
                                value: 'de',
                                child: Text('Deutsch (DE)'),
                              ),
                              DropdownMenuItem(
                                value: 'zh',
                                child: Text('中文 (ZH)'),
                              ),
                              DropdownMenuItem(
                                value: 'ja',
                                child: Text('日本語 (JA)'),
                              ),
                            ],
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                localeNotifier.setLocale(newValue);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 100), // Spacer for footer
                  // Footer
                  Center(
                    child: Column(
                      children: [
                        Image.asset(
                          'assets/images/console_deck_pro_front.png',
                          width: 80,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '${AppStrings.get(currentLocale, AppKeys.appVersion)} 0.1.0',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
