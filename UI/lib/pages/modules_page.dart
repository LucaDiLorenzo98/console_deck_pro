import 'package:flutter/material.dart';
import '../l10n/app_translations.dart';
import '../models/module_model.dart';
import 'package:file_picker/file_picker.dart';

class ModulesPage extends StatefulWidget {
  const ModulesPage({super.key});

  @override
  State<ModulesPage> createState() => _ModulesPageState();
}

class _ModulesPageState extends State<ModulesPage> {
  int? _selectedModuleIndex;

  // Store configurations: moduleIndex -> hotspotId -> {type, value}
  final Map<int, Map<String, Map<String, String>>> _moduleConfigs = {};

  final List<ModuleConfig> _modules = const [
    ModuleConfig(
      id: 'extended_btn', // Renamed id
      nameKey: AppKeys.moduleExtendedBtn, // Renamed key
      imagePath: 'assets/images/ext_btn_module.png',
      hotspots: [
        // 2x3 Grid - Recalibrated: 90x90 squares, tighter spacing (Vertically compressed)
        ModuleHotspot(
          id: 'btn1',
          left: 155,
          top: 95, // Shifted down from 70
          width: 90,
          height: 90,
          tooltipKey: 'Button 1',
        ),
        ModuleHotspot(
          id: 'btn2',
          left: 255,
          top: 95,
          width: 90,
          height: 90,
          tooltipKey: 'Button 2',
        ),
        ModuleHotspot(
          id: 'btn3',
          left: 155,
          top: 205, // Kept centered
          width: 90,
          height: 90,
          tooltipKey: 'Button 3',
        ),
        ModuleHotspot(
          id: 'btn4',
          left: 255,
          top: 205,
          width: 90,
          height: 90,
          tooltipKey: 'Button 4',
        ),
        ModuleHotspot(
          id: 'btn5',
          left: 155,
          top: 315, // Shifted up from 340
          width: 90,
          height: 90,
          tooltipKey: 'Button 5',
        ),
        ModuleHotspot(
          id: 'btn6',
          left: 255,
          top: 315,
          width: 90,
          height: 90,
          tooltipKey: 'Button 6',
        ),
      ],
    ),
    ModuleConfig(
      id: 'sliders',
      nameKey: AppKeys.moduleSliders,
      imagePath: 'assets/images/sliders_module.png',
      hotspots: [
        // 4 Vertical Zones
        ModuleHotspot(
          id: 'side_l',
          left: 0,
          top: 20,
          width: 125,
          height: 460,
          tooltipKey: 'Side Left',
        ),
        ModuleHotspot(
          id: 'slider_l',
          left: 125,
          top: 20,
          width: 125,
          height: 460,
          tooltipKey: 'Slider Lefft',
        ),
        ModuleHotspot(
          id: 'slider_r',
          left: 250,
          top: 20,
          width: 125,
          height: 460,
          tooltipKey: 'Slider Right',
        ),
        ModuleHotspot(
          id: 'side_r',
          left: 375,
          top: 20,
          width: 125,
          height: 460,
          tooltipKey: 'Side Right',
        ),
      ],
    ),
    ModuleConfig(
      id: 'knobs',
      nameKey: AppKeys.moduleKnobs,
      imagePath: 'assets/images/knobs_module.png',
      hotspots: [
        // 2 Round Knobs + 1 Slider
        ModuleHotspot(
          id: 'knob1',
          left: 50,
          top: 60,
          width: 170,
          height: 170,
          tooltipKey: 'Knob 1',
          isRound: true,
        ),
        ModuleHotspot(
          id: 'knob2',
          left: 280,
          top: 60,
          width: 170,
          height: 170,
          tooltipKey: 'Knob 2',
          isRound: true,
        ),
        ModuleHotspot(
          id: 'slider',
          left: 140,
          top: 310,
          width: 220,
          height: 60,
          tooltipKey: 'Slider',
        ),
      ],
    ),
    ModuleConfig(
      id: 'touch',
      nameKey: AppKeys.moduleTouch,
      imagePath: 'assets/images/touch_module.png',
      hotspots: [
        // 1x3 Vertical Stack
        ModuleHotspot(
          id: 'touch1',
          left: 50,
          top: 50,
          width: 400,
          height: 130,
          tooltipKey: 'Button 1',
        ),
        ModuleHotspot(
          id: 'touch2',
          left: 50,
          top: 185,
          width: 400,
          height: 130,
          tooltipKey: 'Button 2',
        ),
        ModuleHotspot(
          id: 'touch3',
          left: 50,
          top: 320,
          width: 400,
          height: 130,
          tooltipKey: 'Button 3',
        ),
      ],
    ),
    ModuleConfig(
      id: 'switch',
      nameKey: AppKeys.moduleSwitch,
      imagePath: 'assets/images/mech_switch_module.png',
      hotspots: [
        // 2x3 Grid - Optimized coordinates
        ModuleHotspot(
          id: 'sw1',
          left: 20,
          top: 40,
          width: 220,
          height: 130,
          tooltipKey: 'Switch 1',
        ),
        ModuleHotspot(
          id: 'sw2',
          left: 260,
          top: 40,
          width: 220,
          height: 130,
          tooltipKey: 'Switch 2',
        ),
        ModuleHotspot(
          id: 'sw3',
          left: 20,
          top: 185,
          width: 220,
          height: 130,
          tooltipKey: 'Switch 3',
        ),
        ModuleHotspot(
          id: 'sw4',
          left: 260,
          top: 185,
          width: 220,
          height: 130,
          tooltipKey: 'Switch 4',
        ),
        ModuleHotspot(
          id: 'sw5',
          left: 20,
          top: 330,
          width: 220,
          height: 130,
          tooltipKey: 'Switch 5',
        ),
        ModuleHotspot(
          id: 'sw6',
          left: 260,
          top: 330,
          width: 220,
          height: 130,
          tooltipKey: 'Switch 6',
        ),
      ],
    ),
    ModuleConfig(
      id: 'media',
      nameKey: AppKeys.moduleMedia,
      imagePath: 'assets/images/media_module.png',
      hotspots: [
        // Play/Pause - Center
        ModuleHotspot(
          id: 'mediaPlayPause',
          left: 230,
          top: 230,
          width: 40,
          height: 40,
          tooltipKey: AppKeys.mediaPlayPause,
        ),
        // Previous - Left of Play
        ModuleHotspot(
          id: 'mediaPrev',
          left: 170,
          top: 230,
          width: 40,
          height: 40,
          tooltipKey: AppKeys.mediaPrev,
        ),
        // Next - Right of Play
        ModuleHotspot(
          id: 'mediaNext',
          left: 290,
          top: 230,
          width: 40,
          height: 40,
          tooltipKey: AppKeys.mediaNext,
        ),
        // Vol Down - Bottom Left? (Guessing standard layout)
        ModuleHotspot(
          id: 'mediaVolDown',
          left: 170, // Aligned with Prev
          top: 290,
          width: 40,
          height: 40,
          tooltipKey: AppKeys.mediaVolDown,
        ),
        // Vol Up - Bottom Right?
        ModuleHotspot(
          id: 'mediaVolUp',
          left: 290, // Aligned with Next
          top: 290,
          width: 40,
          height: 40,
          tooltipKey: AppKeys.mediaVolUp,
        ),
      ],
    ),
    ModuleConfig(
      id: 'piano',
      nameKey: AppKeys.modulePiano,
      imagePath: 'assets/images/piano_module.png',
      hotspots: [
        // Piano Keys (Simulated as one block for now or 7 keys)
        // Assuming simple 7 key layout
        ModuleHotspot(
          id: 'key1',
          left: 70,
          top: 200,
          width: 40,
          height: 150,
          tooltipKey: 'C',
        ),
        ModuleHotspot(
          id: 'key2',
          left: 120,
          top: 200,
          width: 40,
          height: 150,
          tooltipKey: 'D',
        ),
        ModuleHotspot(
          id: 'key3',
          left: 170,
          top: 200,
          width: 40,
          height: 150,
          tooltipKey: 'E',
        ),
        ModuleHotspot(
          id: 'key4',
          left: 220,
          top: 200,
          width: 40,
          height: 150,
          tooltipKey: 'F',
        ),
        ModuleHotspot(
          id: 'key5',
          left: 270,
          top: 200,
          width: 40,
          height: 150,
          tooltipKey: 'G',
        ),
        ModuleHotspot(
          id: 'key6',
          left: 320,
          top: 200,
          width: 40,
          height: 150,
          tooltipKey: 'A',
        ),
        ModuleHotspot(
          id: 'key7',
          left: 370,
          top: 200,
          width: 40,
          height: 150,
          tooltipKey: 'B',
        ),
      ],
    ),
    ModuleConfig(
      id: 'modeling',
      nameKey: AppKeys.moduleModeling,
      imagePath: 'assets/images/modeling_module.png',
      hotspots: [
        // Space Mouse / Joystick Center
        ModuleHotspot(
          id: 'joy',
          left: 150,
          top: 150,
          width: 200,
          height: 200,
          tooltipKey: 'Joystick',
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final currentLocale = Localizations.localeOf(context);

    return Row(
      children: [
        // Left Column: Scrollable List
        SizedBox(
          width: 200, // Reduced width to give more space to detail view
          child: Container(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            child: ListView.separated(
              itemCount: _modules.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final module = _modules[index];
                final isSelected = _selectedModuleIndex == index;
                return ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  tileColor: isSelected
                      ? Theme.of(context).colorScheme.secondaryContainer
                      : null,
                  leading: Image.asset(
                    module.imagePath,
                    width: 50,
                    height: 50,
                    fit: BoxFit.contain,
                  ),
                  title: Text(
                    AppStrings.get(currentLocale, module.nameKey),
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  onTap: () {
                    setState(() {
                      _selectedModuleIndex = index;
                    });
                  },
                );
              },
            ),
          ),
        ),

        // Right Column: Detail View
        Expanded(
          child: Container(
            color: Theme.of(context).colorScheme.surface,
            child: _selectedModuleIndex == null
                ? _buildPlaceholder(currentLocale)
                : _buildModuleDetail(
                    currentLocale,
                    _modules[_selectedModuleIndex!],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholder(Locale locale) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.touch_app_outlined,
            size: 64,
            color: Theme.of(context).disabledColor,
          ),
          const SizedBox(height: 16),
          Text(
            AppStrings.get(locale, AppKeys.selectModuleHint),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Theme.of(context).disabledColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModuleDetail(Locale locale, ModuleConfig module) {
    return Center(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: SizedBox(
            width: 650,
            height: 650,
            child: FittedBox(
              fit: BoxFit.contain,
              child: SizedBox(
                width: 500,
                height: 500,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Image.asset(module.imagePath, fit: BoxFit.contain),
                    ),
                    // Render Hotspots
                    ...module.hotspots.asMap().entries.map((entry) {
                      final index = entry.key;
                      final hotspot = entry.value;

                      return Positioned(
                        left: hotspot.left,
                        top: hotspot.top,
                        width: hotspot.width,
                        height: hotspot.height,
                        child: Material(
                          color: Colors
                              .transparent, // Material handles the shape via InkWell/Ink if needed, but easier to use Container decoration
                          child: InkWell(
                            onTap: () => _showConfigDialog(module, hotspot),
                            customBorder: hotspot.isRound
                                ? const CircleBorder()
                                : RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.blue.withValues(alpha: 0.3),
                                shape: hotspot.isRound
                                    ? BoxShape.circle
                                    : BoxShape.rectangle,
                                borderRadius: hotspot.isRound
                                    ? null
                                    : BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 24,
                                    shadows: [
                                      Shadow(
                                        offset: Offset(1, 1),
                                        blurRadius: 2,
                                        color: Colors.black,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showConfigDialog(
    ModuleConfig module,
    ModuleHotspot hotspot,
  ) async {
    final currentLocale = Localizations.localeOf(context);
    final moduleIndex = _modules.indexOf(module);

    // Get current config or defaults
    final currentConfig =
        _moduleConfigs[moduleIndex]?[hotspot.id] ??
        {'type': hotspot.defaultType, 'value': hotspot.defaultValue ?? ''};

    String selectedType = currentConfig['type'] ?? 'Link';

    final TextEditingController linkController = TextEditingController(
      text: selectedType == 'Link' ? currentConfig['value'] : '',
    );
    final TextEditingController appController = TextEditingController(
      text: selectedType == 'App' ? currentConfig['value'] : '',
    );
    final TextEditingController hotkeyController = TextEditingController(
      text: selectedType == 'Hotkey' ? currentConfig['value'] : '',
    );
    String? selectedAppPath = selectedType == 'App'
        ? currentConfig['value']
        : null;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                AppStrings.get(currentLocale, AppKeys.configureButton),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButton<String>(
                      value: selectedType,
                      isExpanded: true,
                      items: <String>['Link', 'App', 'Hotkey']
                          .map<DropdownMenuItem<String>>((String value) {
                            String label = value;
                            if (value == 'Link') {
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
                      TextField(
                        controller: hotkeyController,
                        decoration: InputDecoration(
                          labelText: AppStrings.get(
                            currentLocale,
                            AppKeys.hotkeyCombo,
                          ),
                          hintText: AppStrings.get(
                            currentLocale,
                            AppKeys.hotkeyHint,
                          ),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: Text(AppStrings.get(currentLocale, AppKeys.cancel)),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                TextButton(
                  child: Text(AppStrings.get(currentLocale, AppKeys.save)),
                  onPressed: () {
                    String value = '';
                    if (selectedType == 'Link') value = linkController.text;
                    if (selectedType == 'App') value = appController.text;
                    if (selectedType == 'Hotkey') value = hotkeyController.text;

                    setState(() {
                      if (!_moduleConfigs.containsKey(moduleIndex)) {
                        _moduleConfigs[moduleIndex] = {};
                      }
                      _moduleConfigs[moduleIndex]![hotspot.id] = {
                        'type': selectedType,
                        'value': value,
                      };
                    });
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
}
