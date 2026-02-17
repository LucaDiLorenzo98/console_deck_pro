import 'package:console_deck_ui/home.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
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
    final mappings = fullConfig['mappings'] as Map<String, dynamic>? ?? {};

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

    String? selectedAppPath = selectedType == 'App' ? currentValue : null;

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
                      items: <String>['None', 'Link', 'App', 'Hotkey']
                          .map<DropdownMenuItem<String>>((String value) {
                            String label = value;
                            if (value == 'None') {
                              label = AppStrings.get(
                                currentLocale,
                                AppKeys.typeNone,
                              );
                            } else if (value == 'Link') {
                              label = AppStrings.get(
                                currentLocale,
                                AppKeys.typeLink,
                              );
                            } else if (value == 'App') {
                              label = AppStrings.get(
                                currentLocale,
                                AppKeys.typeApp,
                              );
                            } else if (value == 'Hotkey') {
                              label = AppStrings.get(
                                currentLocale,
                                AppKeys.typeHotkey,
                              );
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
                    String value = '';
                    if (selectedType == 'Link') value = linkController.text;
                    if (selectedType == 'App') value = appController.text;
                    if (selectedType == 'Hotkey') value = hotkeyController.text;

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

                    if (mounted) Navigator.of(context).pop();
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
