import 'package:console_deck_ui/pages/skin_creator_page.dart';
import 'package:flutter/material.dart';
import 'l10n/app_translations.dart';
import 'pages/home_page.dart';
import 'pages/modules_page.dart';
import 'pages/settings_page.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';

enum BackendStatus { connected, notConfigured, backendDown }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  BackendStatus _status = BackendStatus.backendDown;
  Timer? _statusTimer;
  bool _isCheckingBackend = false;
  late final List<Widget> _persistentPages;

  @override
  void initState() {
    super.initState();
    _persistentPages = const [
      ModulesPage(),
      SkinCreatorPage(),
      SettingsPage(),
    ];
    _checkBackendStatus();
    _statusTimer = Timer.periodic(
      const Duration(seconds: 3),
      (timer) => _checkBackendStatus(),
    );
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    super.dispose();
  }

  void _navigateTo(int index) {
    if (_selectedIndex == index) {
      return;
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _checkBackendStatus() async {
    if (_isCheckingBackend) {
      return;
    }
    _isCheckingBackend = true;
    BackendStatus newStatus = _status;

    try {
      final response = await http
          .get(Uri.parse('http://127.0.0.1:8000/status'))
          .timeout(const Duration(seconds: 2));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final isConfigured = body['configured'] == true;
        newStatus =
            isConfigured ? BackendStatus.connected : BackendStatus.notConfigured;
      } else {
        newStatus = BackendStatus.backendDown;
      }
    } catch (e) {
      newStatus = BackendStatus.backendDown;
    } finally {
      _isCheckingBackend = false;
    }

    if (mounted && newStatus != _status) {
      setState(() {
        _status = newStatus;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentLocale = Localizations.localeOf(context);

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              _navigateTo(index);
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
                icon: const Icon(Icons.add_box),
                selectedIcon: const Icon(Icons.add_box_rounded),
                label: Text(AppStrings.get(currentLocale, AppKeys.skinCreator)),
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
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: [
                HomePage(
                  status: _status,
                  onGoToSettings: () => _navigateTo(3),
                ),
                ..._persistentPages,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
