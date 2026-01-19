import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme_state.dart';
import '../locale_state.dart';
import '../l10n/app_translations.dart';
import 'package:url_launcher/url_launcher.dart';

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
              child: Column(
                children: [
                  // Scrollable Top Section (Settings & Report)
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        const SizedBox(height: 20),

                        // Theme Switcher
                        ValueListenableBuilder<ThemeMode>(
                          valueListenable: themeNotifier,
                          builder: (context, themeMode, child) {
                            final isDark = themeMode == ThemeMode.dark;
                            return Card(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      isDark
                                          ? Icons.dark_mode
                                          : Icons.light_mode,
                                    ),
                                    const SizedBox(width: 16),
                                    Text(
                                      AppStrings.get(
                                        currentLocale,
                                        isDark
                                            ? AppKeys.themeDark
                                            : AppKeys.themeLight,
                                      ),
                                    ),
                                    const Spacer(),
                                    Switch(
                                      value: isDark,
                                      onChanged: (val) =>
                                          themeNotifier.toggle(),
                                    ),
                                  ],
                                ),
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
                                Text(
                                  AppStrings.get(
                                    currentLocale,
                                    AppKeys.language,
                                  ),
                                ),
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

                        const SizedBox(height: 20),

                        // Report Issue Button
                        Center(
                          child: TextButton.icon(
                            icon: const Icon(
                              Icons.bug_report,
                              color: Colors.orange,
                            ),
                            label: Text(
                              AppStrings.get(
                                currentLocale,
                                AppKeys.reportProblem,
                              ),
                              style: const TextStyle(color: Colors.orange),
                            ),
                            onPressed: () => _reportProblem(context),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Bottom Section (Links & Footer)
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Links Section
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildLinkIcon(
                              context,
                              Icons.language,
                              'https://lucadilo.com/',
                            ),
                            const SizedBox(width: 8),
                            _buildLinkIcon(
                              context,
                              'assets/icons/makerworld.svg',
                              'https://makerworld.com/it/@luca_dilo',
                              iconSize: 26, // Reduced slightly
                            ),
                            const SizedBox(width: 8),
                            _buildLinkIcon(
                              context,
                              'assets/icons/instagram.svg',
                              'https://www.instagram.com/lucadilo_3d/',
                            ),
                            const SizedBox(width: 8),
                            _buildLinkIcon(
                              context,
                              'assets/icons/tiktok.svg',
                              'https://www.tiktok.com/@lucadilo7',
                              iconSize: 26,
                            ),
                            const SizedBox(width: 8),
                            _buildLinkIcon(
                              context,
                              'assets/icons/youtube.svg',
                              'https://www.youtube.com/@Luca_Dilo',
                              iconSize: 35,
                              paddingTop: 3,
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Version Footer
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/images/console_deck_pro_front.png',
                              width: 60,
                            ),
                            const SizedBox(width: 16),
                            Text(
                              '${AppStrings.get(currentLocale, AppKeys.appVersion)} 0.1.0',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
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

  Widget _buildLinkIcon(
    BuildContext context,
    dynamic iconSource, // IconData or String (asset path)
    String url, {
    double? iconSize,
    double? paddingTop,
  }) {
    final double size = iconSize ?? 30.0;
    Widget iconWidget;
    if (iconSource is IconData) {
      iconWidget = Icon(iconSource, size: size);
    } else if (iconSource is String) {
      // Use SVG for string assets
      iconWidget = SvgPicture.asset(
        iconSource,
        width: size,
        height: size,
        colorFilter: ColorFilter.mode(
          Theme.of(context).iconTheme.color ?? Colors.black,
          BlendMode.srcIn,
        ),
      );
    } else {
      iconWidget = SizedBox(width: size, height: size);
    }

    if (paddingTop != null) {
      iconWidget = Padding(
        padding: EdgeInsets.only(top: paddingTop),
        child: iconWidget,
      );
    }

    return IconButton(
      icon: iconWidget,
      onPressed: () => _launchUrl(url),
      style: IconButton.styleFrom(
        hoverColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
    );
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }

  Future<void> _reportProblem(BuildContext context) async {
    final currentLocale = Localizations.localeOf(context);
    final String subject = Uri.encodeComponent(
      AppStrings.get(currentLocale, AppKeys.reportSubject),
    );
    // Gmail web link expects 'body' parameter but creating a full pre-filled email via URL often has length limits or encoding issues.
    // We will try to map common fields.
    // https://mail.google.com/mail/?view=cm&fs=1&to=email@example.com&su=Hello&body=BODY

    final String body = Uri.encodeComponent(
      '${AppStrings.get(currentLocale, AppKeys.reportBodyPrototype)} \n\n'
      'Date: ${DateTime.now().toString()}\n',
    );

    final Uri gmailUrl = Uri.parse(
      'https://mail.google.com/mail/?view=cm&fs=1&to=lucadilo3d@gmail.com&su=$subject&body=$body',
    );

    if (!await launchUrl(gmailUrl, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch gmail');
    }
  }
}
