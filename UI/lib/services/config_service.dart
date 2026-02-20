import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:http/http.dart' as http;

class ConfigService {
  static const String _appName = "ConsoleDeckPro";
  static const String _fileName = "config.json";

  static Future<File> get _configFile async {
    Directory appDir;
    // Legacy location (pre-unification). Used for one-time migration on desktop.
    Directory? legacyDir;

    // On Windows, path_provider creates a subfolder with the app's ID.
    // The Python script expects the config directly in AppData/Roaming/ConsoleDeckPro.
    // To match this, we get the standard app support directory and navigate up to the parent
    // of the vendor folder (e.g., up from 'com.example') to get to AppData/Roaming.
    if (Platform.isWindows) {
      final appSupportDir = await getApplicationSupportDirectory();
      // appSupportDir.path is .../AppData/Roaming/com.example/console_deck_ui
      // We need to go up two levels to get to AppData/Roaming
      final roamingDir = appSupportDir.parent.parent;
      appDir = Directory(p.join(roamingDir.path, _appName));
    } else if (Platform.isMacOS) {
      // Match Python backend: ~/Library/Application Support/ConsoleDeckPro
      final appSupportDir = await getApplicationSupportDirectory();
      final applicationSupportRoot = appSupportDir.parent; // .../Library/Application Support
      appDir = Directory(p.join(applicationSupportRoot.path, _appName));
      legacyDir = Directory(p.join(appSupportDir.path, _appName));
    } else if (Platform.isLinux) {
      // Match Python backend: $XDG_CONFIG_HOME/ConsoleDeckPro or ~/.config/ConsoleDeckPro
      final xdg = Platform.environment['XDG_CONFIG_HOME'];
      final home = Platform.environment['HOME'];
      final base = (xdg != null && xdg.isNotEmpty)
          ? xdg
          : (home != null && home.isNotEmpty)
              ? p.join(home, '.config')
              : (await getApplicationSupportDirectory()).path;
      appDir = Directory(p.join(base, _appName));
      final appSupportDir = await getApplicationSupportDirectory();
      legacyDir = Directory(p.join(appSupportDir.path, _appName));
    } else {
      // For other platforms, use the standard sandboxed directory.
      final directory = await getApplicationSupportDirectory();
      appDir = Directory(p.join(directory.path, _appName));
    }

    if (!await appDir.exists()) {
      await appDir.create(recursive: true);
    }
    final filePath = p.join(appDir.path, _fileName);

    // One-time migration from legacy desktop location if needed.
    if (legacyDir != null) {
      final legacyPath = p.join(legacyDir.path, _fileName);
      final legacyFile = File(legacyPath);
      final newFile = File(filePath);
      if (!await newFile.exists() && await legacyFile.exists()) {
        try {
          await legacyFile.copy(filePath);
          if (kDebugMode) {
            print('[ConfigService] Migrated config from $legacyPath to $filePath');
          }
        } catch (e) {
          if (kDebugMode) {
            print('[ConfigService] Failed to migrate legacy config: $e');
          }
        }
      }
    }

    if (kDebugMode) {
      print('[ConfigService] Using config file path: $filePath');
    }
    return File(filePath);
  }

  // Load config map
  static Future<Map<String, dynamic>> loadConfig() async {
    try {
      final file = await _configFile;
      if (await file.exists()) {
        final content = await file.readAsString();
        return jsonDecode(content);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading config: $e');
      }
    }
    return {};
  }

  // Save specific mapping
  static Future<void> saveMapping(String key, String type, String value) async {
    try {
      final file = await _configFile;
      Map<String, dynamic> config = {};

      if (await file.exists()) {
        final content = await file.readAsString();
        try {
          config = jsonDecode(content);
        } catch (_) {}
      }

      if (config['mappings'] == null) {
        config['mappings'] = {};
      }

      final Map<String, dynamic> entry = {};

      // Map UI Type to JSON Action
      switch (type) {
        case 'Link':
          entry['action'] = 'open_url';
          entry['value'] = value;
          break;
        case 'App':
          entry['action'] = 'open_app';
          entry['value'] = value;
          break;
        case 'Hotkey':
          entry['action'] = 'hotkey';
          entry['value'] = _parseHotkey(value);
          break;
        case 'Volume':
          entry['action'] = 'set_volume';
          break;
        case 'Brightness':
          entry['action'] = 'set_brightness';
          break;
        case 'None':
          (config['mappings'] as Map).remove(key);
          await _writeConfig(file, config);
          return;
        default:
          return;
      }

      config['mappings'][key] = entry;
      await _writeConfig(file, config);
    } catch (e) {
      if (kDebugMode) {
        print('Error saving config: $e');
      }
    }
  }

  static Future<void> saveSerialPort(String port) async {
    try {
      final file = await _configFile;
      Map<String, dynamic> config = {};

      if (await file.exists()) {
        final content = await file.readAsString();
        try {
          config = jsonDecode(content);
        } catch (_) {}
      }

      if (config['serial'] == null) {
        config['serial'] = {};
      }
      config['serial']['port'] = port;

      await _writeConfig(file, config);
    } catch (e) {
      if (kDebugMode) {
        print('Error saving serial port: $e');
      }
    }
  }

  static Future<void> _writeConfig(
    File file,
    Map<String, dynamic> config,
  ) async {
    const JsonEncoder encoder = JsonEncoder.withIndent('    ');
    await file.writeAsString(encoder.convert(config));

    // Trigger reload in python backend
    try {
      await http.post(Uri.parse('http://127.0.0.1:8000/reload'));
    } catch (e) {
      if (kDebugMode) {
        print('Error triggering reload: $e');
      }
    }
  }

  static List<String> _parseHotkey(String combo) {
    if (combo.isEmpty) return [];
    return combo.toLowerCase().split('+').map((e) => e.trim()).toList();
  }

  // Inverse: JSON Action to UI Type/Value
  static Map<String, String> parseConfigEntry(Map<dynamic, dynamic> entry) {
    final action = entry['action'] as String?;
    final val = entry['value'];

    String type = 'None';
    String value = '';

    if (action == 'open_url') {
      type = 'Link';
      value = val?.toString() ?? '';
    } else if (action == 'open_app') {
      type = 'App';
      value = val?.toString() ?? '';
    } else if (action == 'hotkey') {
      type = 'Hotkey';
      if (val is List) {
        value = val.join('+').toUpperCase(); // Convert ["ctrl", "c"] -> CTRL+C
      }
    } else if (action == 'set_volume') {
      type = 'Volume';
    } else if (action == 'set_brightness') {
      type = 'Brightness';
    }

    return {'type': type, 'value': value};
  }
}
