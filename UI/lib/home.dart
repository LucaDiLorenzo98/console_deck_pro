import 'package:flutter/material.dart';
import 'l10n/app_translations.dart';
import 'pages/home_page.dart';
import 'pages/modules_page.dart';
import 'pages/settings_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [HomePage(), ModulesPage(), SettingsPage()];

  @override
  Widget build(BuildContext context) {
    final currentLocale = Localizations.localeOf(context);

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            labelType: NavigationRailLabelType.all,
            destinations: <NavigationRailDestination>[
              NavigationRailDestination(
                icon: const Icon(Icons.home),
                selectedIcon: const Icon(Icons.home_filled),
                label: Text(AppStrings.get(currentLocale, AppKeys.home)),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.view_module),
                selectedIcon: const Icon(Icons.view_module_rounded),
                label: Text(AppStrings.get(currentLocale, AppKeys.modules)),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.settings),
                selectedIcon: const Icon(Icons.settings_applications),
                label: Text(AppStrings.get(currentLocale, AppKeys.settings)),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          // Main Content Area
          Expanded(child: _pages[_selectedIndex]),
        ],
      ),
    );
  }
}
