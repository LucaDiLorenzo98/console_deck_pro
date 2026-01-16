import 'package:flutter/material.dart';
import '../l10n/app_translations.dart';

class ModulesPage extends StatelessWidget {
  const ModulesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final currentLocale = Localizations.localeOf(context);
    return Center(
      child: Text(AppStrings.get(currentLocale, AppKeys.modulesPageTitle)),
    );
  }
}
