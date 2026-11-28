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
      return _readConfigFile(file);
    } catch (e) {
      if (kDebugMode) {
        print('Error loading config: $e');
      }
    }
    return {
      'serial': {'port': null, 'baud_rate': 115200},
      'mappings': {
        'main': <String, dynamic>{},
        'modules': <String, dynamic>{},
      },
    };
  }

  static bool _isMainMappingKey(String key) => key.startsWith('btn_');

  static Map<String, dynamic> _normalizeMappings(Map<String, dynamic> config) {
    final raw = Map<String, dynamic>.from((config['mappings'] as Map?) ?? const {});
    Map<String, dynamic> main;
    Map<String, dynamic> modules;

    if (raw.containsKey('main') || raw.containsKey('modules')) {
      main = Map<String, dynamic>.from((raw['main'] as Map?) ?? const {});
      modules = Map<String, dynamic>.from((raw['modules'] as Map?) ?? const {});
    } else {
      main = <String, dynamic>{};
      modules = <String, dynamic>{};
      raw.forEach((k, v) {
        if (_isMainMappingKey(k)) {
          main[k] = v;
        } else {
          modules[k] = v;
        }
      });
    }

    final normalized = <String, dynamic>{'main': main, 'modules': modules};
    config['mappings'] = normalized;
    return normalized;
  }

  // Save specific mapping
  static Future<void> saveMapping(String key, String type, String value) async {
    try {
      final file = await _configFile;
      final config = await _readConfigFile(file);
      final mappings = _normalizeMappings(config);
      final mainMappings = Map<String, dynamic>.from(
        (mappings['main'] as Map?) ?? const {},
      );
      final moduleMappings = Map<String, dynamic>.from(
        (mappings['modules'] as Map?) ?? const {},
      );
      final target = _isMainMappingKey(key) ? mainMappings : moduleMappings;

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
        case 'Audio':
          entry['action'] = 'play_audio';
          entry['value'] = value;
          break;
        case 'Volume':
          entry['action'] = 'set_volume';
          break;
        case 'None':
          target.remove(key);
          mappings['main'] = mainMappings;
          mappings['modules'] = moduleMappings;
          config['mappings'] = mappings;
          await _writeConfig(file, config);
          return;
        default:
          return;
      }

      target[key] = entry;
      mappings['main'] = mainMappings;
      mappings['modules'] = moduleMappings;
      config['mappings'] = mappings;
      await _writeConfig(file, config);
    } catch (e) {
      if (kDebugMode) {
        print('Error saving config: $e');
      }
    }
  }

  static Future<void> saveLanguage(String languageCode) async {
    try {
      final file = await _configFile;
      final config = await _readConfigFile(file);
      config['language'] = languageCode;
      await _writeConfig(file, config);
    } catch (e) {
      if (kDebugMode) print('Error saving language: $e');
    }
  }

  static Future<void> saveHaConfig(String host, String token) async {
    try {
      final file = await _configFile;
      final config = await _readConfigFile(file);
      config['home_assistant'] = {'host': host, 'token': token};
      await _writeConfig(file, config);
    } catch (e) {
      if (kDebugMode) print('Error saving HA config: $e');
    }
  }

  static Future<Map<String, String>> loadHaConfig() async {
    try {
      final config = await loadConfig();
      final ha = config['home_assistant'] as Map?;
      if (ha != null) {
        return {
          'host': ha['host']?.toString() ?? '',
          'token': ha['token']?.toString() ?? '',
        };
      }
    } catch (e) {
      if (kDebugMode) print('Error loading HA config: $e');
    }
    return {'host': '', 'token': ''};
  }

  static Future<void> saveHaMapping(String key, String entityId, String service) async {
    try {
      final file = await _configFile;
      final config = await _readConfigFile(file);
      final mappings = _normalizeMappings(config);
      final mainMappings = Map<String, dynamic>.from((mappings['main'] as Map?) ?? const {});
      mainMappings[key] = {
        'action': 'home_assistant',
        'service': service,
        'entity_id': entityId,
      };
      mappings['main'] = mainMappings;
      config['mappings'] = mappings;
      await _writeConfig(file, config);
    } catch (e) {
      if (kDebugMode) print('Error saving HA mapping: $e');
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
        'mappings': {
          'main': <String, dynamic>{},
          'modules': <String, dynamic>{},
        },
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
        _normalizeMappings(normalized);
        return normalized;
      }
    } catch (_) {
      // Fall through to a safe default config.
    }

    return {
      'serial': {'port': null, 'baud_rate': 115200},
      'mappings': {
        'main': <String, dynamic>{},
        'modules': <String, dynamic>{},
      },
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
    } else if (action == 'play_audio') {
      type = 'Audio';
      value = val?.toString() ?? '';
    } else if (action == 'set_volume') {
      type = 'Volume';
    } else if (action == 'set_brightness') {
      // Screen brightness was removed: show the control as unassigned.
      type = 'None';
    } else if (action == 'home_assistant') {
      type = 'HomeAssistant';
      final entityId = (entry['entity_id'] ?? '').toString();
      final service = (entry['service'] ?? 'turn_on').toString();
      value = '$entityId|$service';
    }

    return {'type': type, 'value': value};
  }
}
