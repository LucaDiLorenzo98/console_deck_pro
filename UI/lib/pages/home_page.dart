import 'package:console_deck_ui/home.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../l10n/app_translations.dart';
import '../services/config_service.dart';
import '../widgets/hotkey_input_field.dart';

class HomePage extends StatefulWidget {
  final BackendStatus status;
  final VoidCallback onGoToSettings;

  const HomePage({
    super.key,
    required this.status,
    required this.onGoToSettings,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Temporary storage for button configurations
  // Index -> {type, value}
  final Map<int, Map<String, String>> _buttonConfigs = {};

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final fullConfig = await ConfigService.loadConfig();
    final mappingsRoot =
        fullConfig['mappings'] as Map<String, dynamic>? ?? const {};
    final mappings =
        mappingsRoot['main'] as Map<String, dynamic>? ?? const {};

    if (mounted) {
      setState(() {
        for (int i = 0; i < 9; i++) {
          final key = 'btn_${i + 1}';
          if (mappings.containsKey(key)) {
            _buttonConfigs[i] = ConfigService.parseConfigEntry(mappings[key]);
          }
        }
      });
    }
  }

  List<String> _servicesForDomain(String domain) {
    switch (domain) {
      case 'scene':
        return ['turn_on'];
      case 'script':
        return ['turn_on'];
      case 'automation':
        return ['trigger', 'turn_on', 'turn_off'];
      case 'media_player':
        return ['media_play_pause', 'media_stop', 'turn_on', 'turn_off'];
      default:
        return ['turn_on', 'turn_off', 'toggle'];
    }
  }

  Future<Map<String, String>?> _showEntityPickerDialog(
      String host, String token) async {
    List<Map<String, String>> entities = [];
    List<Map<String, String>> filtered = [];
    String? error;
    bool loading = true;
    bool fetched = false;

    return showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) {
          if (!fetched) {
            fetched = true;
            () async {
              try {
                final cleanHost =
                    host.replaceAll(RegExp(r'/+$'), '');
                final resp = await http
                    .get(Uri.parse('$cleanHost/api/states'),
                        headers: {'Authorization': 'Bearer $token'})
                    .timeout(const Duration(seconds: 8));
                if (resp.statusCode == 200) {
                  final data = jsonDecode(resp.body) as List;
                  final list = data.map<Map<String, String>>((e) {
                    final eid = (e['entity_id'] ?? '').toString();
                    return {
                      'entity_id': eid,
                      'friendly_name':
                          (e['attributes']?['friendly_name'] ?? eid)
                              .toString(),
                      'domain':
                          eid.contains('.') ? eid.split('.')[0] : eid,
                    };
                  }).toList()
                    ..sort((a, b) =>
                        a['entity_id']!.compareTo(b['entity_id']!));
                  setSt(() {
                    entities = list;
                    filtered = list;
                    loading = false;
                  });
                } else {
                  setSt(() {
                    error = 'HTTP ${resp.statusCode}';
                    loading = false;
                  });
                }
              } catch (e) {
                setSt(() {
                  error = e.toString();
                  loading = false;
                });
              }
            }();
          }

          return AlertDialog(
            title: const Text('Select Entity'),
            contentPadding:
                const EdgeInsets.fromLTRB(24, 20, 24, 0),
            content: SizedBox(
              width: 400,
              height: 480,
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : error != null
                      ? Center(
                          child: Text('Error: $error',
                              style:
                                  const TextStyle(color: Colors.red)))
                      : Column(children: [
                          TextField(
                            decoration: const InputDecoration(
                              hintText: 'Search...',
                              prefixIcon: Icon(Icons.search),
                              border: OutlineInputBorder(),
                              isDense: true,
                              contentPadding:
                                  EdgeInsets.symmetric(vertical: 10),
                            ),
                            onChanged: (v) {
                              final q = v.toLowerCase();
                              setSt(() {
                                filtered = entities
                                    .where((e) =>
                                        e['entity_id']!.contains(q) ||
                                        e['friendly_name']!
                                            .toLowerCase()
                                            .contains(q))
                                    .toList();
                              });
                            },
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: ListView.builder(
                              itemCount: filtered.length,
                              itemBuilder: (_, i) {
                                final e = filtered[i];
                                return ListTile(
                                  dense: true,
                                  title: Text(e['friendly_name']!),
                                  subtitle: Text(e['entity_id']!,
                                      style: const TextStyle(
                                          fontSize: 11)),
                                  onTap: () =>
                                      Navigator.of(ctx).pop(e),
                                );
                              },
                            ),
                          ),
                        ]),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(null),
                child: const Text('Cancel'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showActionDialog(int index) async {
    final currentLocale = Localizations.localeOf(context);
    String selectedType = _buttonConfigs[index]?['type'] ?? 'None';
    final String? currentValue = _buttonConfigs[index]?['value'];

    final TextEditingController linkController = TextEditingController(
      text: selectedType == 'Link' ? currentValue : '',
    );
    final TextEditingController appController = TextEditingController(
      text: selectedType == 'App' ? currentValue : '',
    );
    final TextEditingController hotkeyController = TextEditingController(
      text: selectedType == 'Hotkey' ? currentValue : '',
    );
    final TextEditingController audioController = TextEditingController(
      text: selectedType == 'Audio' ? currentValue : '',
    );

    String? selectedAppPath = selectedType == 'App' ? currentValue : null;
    String? selectedAudioPath = selectedType == 'Audio' ? currentValue : null;

    // HA state
    final haParts = (selectedType == 'HomeAssistant' && currentValue != null)
        ? currentValue.split('|')
        : <String>[];
    String? haEntityId = haParts.isNotEmpty ? haParts[0] : null;
    String haService = haParts.length > 1 ? haParts[1] : 'turn_on';
    String? haError;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                '${AppStrings.get(currentLocale, AppKeys.configureButton)} ${index + 1}',
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButton<String>(
                      value: selectedType,
                      isExpanded: true,
                      items: <String>['None', 'Link', 'App', 'Hotkey', 'Audio', 'HomeAssistant']
                          .map<DropdownMenuItem<String>>((String value) {
                            String label = value;
                            if (value == 'None') {
                              label = AppStrings.get(currentLocale, AppKeys.typeNone);
                            } else if (value == 'Link') {
                              label = AppStrings.get(currentLocale, AppKeys.typeLink);
                            } else if (value == 'App') {
                              label = AppStrings.get(currentLocale, AppKeys.typeApp);
                            } else if (value == 'Hotkey') {
                              label = AppStrings.get(currentLocale, AppKeys.typeHotkey);
                            } else if (value == 'HomeAssistant') {
                              label = 'Home Assistant';
                            }
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(label),
                            );
                          })
                          .toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setDialogState(() {
                            selectedType = newValue;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                    if (selectedType == 'Link')
                      TextField(
                        controller: linkController,
                        decoration: InputDecoration(
                          labelText: AppStrings.get(currentLocale, AppKeys.url),
                          hintText: AppStrings.get(
                            currentLocale,
                            AppKeys.urlHint,
                          ),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    if (selectedType == 'App')
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: appController,
                              readOnly: true,
                              decoration: InputDecoration(
                                labelText: AppStrings.get(
                                  currentLocale,
                                  AppKeys.executablePath,
                                ),
                                border: const OutlineInputBorder(),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.folder_open),
                            onPressed: () async {
                              FilePickerResult? result = await FilePicker
                                  .platform
                                  .pickFiles(
                                    type: FileType.custom,
                                    allowedExtensions: ['exe', 'bat', 'cmd'],
                                  );

                              if (result != null) {
                                selectedAppPath = result.files.single.path;
                                appController.text = selectedAppPath!;
                              }
                            },
                          ),
                        ],
                      ),
                    if (selectedType == 'Hotkey')
                      HotkeyInputField(
                        controller: hotkeyController,
                        labelText: AppStrings.get(
                          currentLocale,
                          AppKeys.hotkeyCombo,
                        ),
                        hintText: AppStrings.get(
                          currentLocale,
                          AppKeys.hotkeyHint,
                        ),
                        clearTooltip: AppStrings.get(
                          currentLocale,
                          AppKeys.clear,
                        ),
                      ),
                    if (selectedType == 'Audio')
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: audioController,
                              readOnly: true,
                              decoration: const InputDecoration(
                                labelText: 'Audio file',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.file_open),
                            onPressed: () async {
                              FilePickerResult? result = await FilePicker
                                  .platform
                                  .pickFiles(
                                    type: FileType.custom,
                                    allowedExtensions: [
                                      'wav',
                                      'mp3',
                                      'ogg',
                                      'flac',
                                      'm4a',
                                    ],
                                  );
                              if (result != null) {
                                selectedAudioPath = result.files.single.path;
                                audioController.text = selectedAudioPath!;
                              }
                            },
                          ),
                        ],
                      ),
                    if (selectedType == 'HomeAssistant')
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  haEntityId ?? 'No entity selected',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: haEntityId == null
                                        ? Theme.of(context).hintColor
                                        : null,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () async {
                                  final cfg = await ConfigService.loadHaConfig();
                                  final host = cfg['host'] ?? '';
                                  final token = cfg['token'] ?? '';
                                  if (host.isEmpty || token.isEmpty) {
                                    setDialogState(() {
                                      haError = 'Configure Home Assistant in Settings first';
                                    });
                                    return;
                                  }
                                  setDialogState(() { haError = null; });
                                  final picked = await _showEntityPickerDialog(host, token);
                                  if (picked != null) {
                                    final domain = picked['domain'] ?? '';
                                    setDialogState(() {
                                      haEntityId = picked['entity_id'];
                                      haService = _servicesForDomain(domain).first;
                                      haError = null;
                                    });
                                  }
                                },
                                child: const Text('Select entity'),
                              ),
                            ],
                          ),
                          if (haError != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(haError!,
                                  style: TextStyle(
                                      color: Theme.of(context).colorScheme.error,
                                      fontSize: 12)),
                            ),
                          if (haEntityId != null) ...[
                            const SizedBox(height: 8),
                            DropdownButton<String>(
                              value: haService,
                              isExpanded: true,
                              items: _servicesForDomain(
                                haEntityId!.contains('.')
                                    ? haEntityId!.split('.')[0]
                                    : '',
                              )
                                  .map((s) => DropdownMenuItem(
                                      value: s, child: Text(s)))
                                  .toList(),
                              onChanged: (v) =>
                                  setDialogState(() => haService = v ?? haService),
                            ),
                          ],
                        ],
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: Text(AppStrings.get(currentLocale, AppKeys.cancel)),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: Text(AppStrings.get(currentLocale, AppKeys.save)),
                  onPressed: () async {
                    if (selectedType == 'HomeAssistant') {
                      if (haEntityId != null && haEntityId!.isNotEmpty) {
                        setState(() {
                          _buttonConfigs[index] = {
                            'type': 'HomeAssistant',
                            'value': '$haEntityId|$haService',
                          };
                        });
                        await ConfigService.saveHaMapping(
                          'btn_${index + 1}',
                          haEntityId!,
                          haService,
                        );
                      }
                      if (context.mounted) Navigator.of(context).pop();
                      return;
                    }

                    String value = '';
                    if (selectedType == 'Link') value = linkController.text;
                    if (selectedType == 'App') value = appController.text;
                    if (selectedType == 'Hotkey') value = hotkeyController.text;
                    if (selectedType == 'Audio') value = audioController.text;

                    setState(() {
                      _buttonConfigs[index] = {
                        'type': selectedType,
                        'value': value,
                      };
                    });

                    await ConfigService.saveMapping(
                      'btn_${index + 1}',
                      selectedType,
                      value,
                    );

                    if (context.mounted) Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentLocale = Localizations.localeOf(context);
    // Fixed dimensions for the background image
    const double imageWidth = 700;
    const double imageHeight =
        500; // Adjusted for rectangular aspect ratio (approx)

    // Button layout configuration (estimated - adjust as needed)
    // Adjusted for 700x500 image size
    const double startX = 72; // Shifted right (was 62)
    // Reduced startY significantly as top whitespace is gone
    const double startY = 58; // Shifted up (was 62)
    const double buttonSize = 110; // Kept same
    const double gap = 24; // Kept same

    return Column(
      children: [
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: SizedBox(
                  width: imageWidth,
                  height: imageHeight,
                  child: Stack(
                    children: [
                      // 1. Background Image
                      Image.asset(
                        'assets/images/console_deck_pro_front.png',
                        width: imageWidth,
                        height: imageHeight,
                        fit: BoxFit.cover,
                      ),

                      // 2. Overlay Buttons
                      ...List.generate(9, (index) {
                        // Calculate row and column (3x3 grid)
                        final int row = index ~/ 3;
                        final int col = index % 3;

                        // Calculate position
                        final double left = startX + (col * (buttonSize + gap));
                        final double top = startY + (row * (buttonSize + gap));

                        return Positioned(
                          left: left,
                          top: top,
                          width: buttonSize,
                          height: buttonSize,
                          child: Material(
                            color: Colors.transparent, // Transparent for production
                            borderRadius: BorderRadius.circular(
                              20,
                            ), // Match button roundness approx
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () => _showActionDialog(index),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '${index + 1}',
                                      style: const TextStyle(
                                        fontSize: 40,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    if (_buttonConfigs.containsKey(index)) ...[
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.black54,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          () {
                                            final type =
                                                _buttonConfigs[index]!['type']!;
                                            if (type == 'Link') {
                                              return AppStrings.get(
                                                currentLocale,
                                                AppKeys.typeLink,
                                              );
                                            } else if (type == 'App') {
                                              return AppStrings.get(
                                                currentLocale,
                                                AppKeys.typeApp,
                                              );
                                            } else if (type == 'Hotkey') {
                                              return AppStrings.get(
                                                currentLocale,
                                                AppKeys.typeHotkey,
                                              );
                                            } else if (type == 'HomeAssistant') {
                                              final v = _buttonConfigs[index]!['value'] ?? '';
                                              final eid = v.contains('|') ? v.split('|')[0] : v;
                                              final name = eid.contains('.') ? eid.split('.').last : eid;
                                              return 'HA: $name';
                                            }
                                            return type;
                                          }(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }),

                      // 3. Volume Knob (Circle) - Top Right
                      Positioned(
                        left: 458, // Shifted left significantly to match gold circle
                        top: 45, // Shifted down slightly as requested
                        width: 200, // Increased width to 200 (160 + 40 spacer)
                        height: 160,
                        child: Tooltip(
                          message: AppStrings.get(currentLocale, AppKeys.knobTooltip),
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 160,
                                height: 160,
                                decoration: const BoxDecoration(
                                  color: Colors
                                      .transparent, // Transparent for production
                                  shape: BoxShape.circle,
                                ),
                              ),
                              // Spacer to shift tooltip center to the right
                              const SizedBox(width: 40),
                            ],
                          ),
                        ),
                      ),

                      // 4. OLED Screen (Square) - Bottom Right
                      Positioned(
                        left: 485,
                        top: 295,
                        width: 160, // Increased to shift center right
                        height: 160, // Increased to shift center down
                        child: Tooltip(
                          message: AppStrings.get(
                            currentLocale,
                            AppKeys.screenTooltip,
                          ),
                          padding: const EdgeInsets.all(12),
                          child: Align(
                            alignment: Alignment.topLeft, // Keep visible box at orig
                            child: Container(
                              width: 120, // Original size
                              height: 120, // Original size
                              decoration: BoxDecoration(
                                color:
                                    Colors.transparent, // Transparent for production
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // 5. Magnetic Connector (Rectangle) - Left Side
                      Positioned(
                        left: -20, // Shifted right to fix hover area
                        top: 190,
                        width: 80, // Increased width (original 30 + 50 padding)
                        height: 120,
                        child: Tooltip(
                          message: AppStrings.get(
                            currentLocale,
                            AppKeys.magnetTooltip,
                          ),
                          padding: const EdgeInsets.all(12),
                          child: Align(
                            alignment:
                                Alignment.centerRight, // Keep visible box right
                            child: Container(
                              width: 30, // Original visible width
                              color: Colors.transparent, // Transparent for production
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        _buildAlertBanner(currentLocale),
      ],
    );
  }

  Widget _buildAlertBanner(Locale locale) {
    if (widget.status == BackendStatus.backendDown) {
      return Container(
        width: double.infinity,
        color: Theme.of(context).colorScheme.errorContainer,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.get(locale, AppKeys.alertBackendDownTitle),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppStrings.get(locale, AppKeys.alertBackendDownText),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    if (widget.status != BackendStatus.notConfigured) {
      return const SizedBox.shrink(); // Don't show anything if not needed
    }

    return Container(
      width: double.infinity,
      color: Theme.of(context).colorScheme.tertiaryContainer,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.info_outline,
            color: Theme.of(context).colorScheme.onTertiaryContainer,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              AppStrings.get(locale, AppKeys.alertNotConfiguredText),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onTertiaryContainer,
              ),
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: widget.onGoToSettings,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.tertiary,
              foregroundColor: Theme.of(context).colorScheme.onTertiary,
            ),
            child:
                Text(AppStrings.get(locale, AppKeys.alertNotConfiguredButton)),
          ),
        ],
      ),
    );
  }
}
