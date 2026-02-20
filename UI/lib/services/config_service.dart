import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:http/http.dart' as http;

class ConfigService {
  static const String _appName = "ConsoleDeckPro";
  static const String _fileName = "config.json";
  static const String _backendBaseUrl = "http://127.0.0.1:8000";

  static Future<File> get _configFile async {
    Directory appDir;
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
    } else {
      // For other platforms, use the standard sandboxed directory.
      final directory = await getApplicationSupportDirectory();
      appDir = Directory(p.join(directory.path, _appName));
    }

    if (!await appDir.exists()) {
      await appDir.create(recursive: true);
    }
    final filePath = p.join(appDir.path, _fileName);
    if (kDebugMode) {
      print('[ConfigService] Using corrected config file path: $filePath');
    }
    return File(filePath);
  }

  // Load config map
  static Future<Map<String, dynamic>> loadConfig() async {
    try {
      final file = await _configFile;
      return _readConfigFile(file);
    } catch (e) {
      if (kDebugMode) {
        print('Error loading config: $e');
      }
    }
    return {
      'serial': {'port': null, 'baud_rate': 115200},
      'mappings': <String, dynamic>{},
    };
  }

  // Save specific mapping
  static Future<void> saveMapping(String key, String type, String value) async {
    try {
      final file = await _configFile;
      final config = await _readConfigFile(file);
      final mappings = Map<String, dynamic>.from(
        (config['mappings'] as Map?) ?? const {},
      );
      config['mappings'] = mappings;

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
          mappings.remove(key);
          await _writeConfig(file, config);
          return;
        default:
          return;
      }

      mappings[key] = entry;
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
      final config = await _readConfigFile(file);
      final serial = Map<String, dynamic>.from(
        (config['serial'] as Map?) ?? const {},
      );
      final currentPort = serial['port'] as String?;
      if (currentPort == port) {
        return;
      }
      serial['port'] = port;
      config['serial'] = serial;

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
      await http
          .post(Uri.parse('$_backendBaseUrl/reload'))
          .timeout(const Duration(seconds: 1));
    } catch (e) {
      if (kDebugMode) {
        print('Error triggering reload: $e');
      }
    }
  }

  static Future<Map<String, dynamic>> _readConfigFile(File file) async {
    if (!await file.exists()) {
      return {
        'serial': {'port': null, 'baud_rate': 115200},
        'mappings': <String, dynamic>{},
      };
    }

    try {
      final content = await file.readAsString();
      if (content.trim().isEmpty) {
        return {
          'serial': {'port': null, 'baud_rate': 115200},
          'mappings': <String, dynamic>{},
        };
      }

      final decoded = jsonDecode(content);
      if (decoded is Map) {
        final normalized = Map<String, dynamic>.from(decoded);
        final serial = Map<String, dynamic>.from(
          (normalized['serial'] as Map?) ?? const {},
        );
        serial.putIfAbsent('port', () => null);
        serial.putIfAbsent('baud_rate', () => 115200);
        normalized['serial'] = serial;
        normalized['mappings'] = Map<String, dynamic>.from(
          (normalized['mappings'] as Map?) ?? const {},
        );
        return normalized;
      }
    } catch (_) {
      // Fall through to a safe default config.
    }

    return {
      'serial': {'port': null, 'baud_rate': 115200},
      'mappings': <String, dynamic>{},
    };
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
      } else if (val is String) {
        value = val;
      }
    } else if (action == 'set_volume') {
      type = 'Volume';
    } else if (action == 'set_brightness') {
      type = 'Brightness';
    }

    return {'type': type, 'value': value};
  }
}
