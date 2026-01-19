import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

class ConfigService {
  static const String _fileName =
      '../config.json'; // Relative to executable/root

  // Load config map
  static Future<Map<String, dynamic>> loadConfig() async {
    try {
      final file = File(_fileName);
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
      final file = File(_fileName);
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

  static Future<void> _writeConfig(
    File file,
    Map<String, dynamic> config,
  ) async {
    const JsonEncoder encoder = JsonEncoder.withIndent('    ');
    await file.writeAsString(encoder.convert(config));
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
