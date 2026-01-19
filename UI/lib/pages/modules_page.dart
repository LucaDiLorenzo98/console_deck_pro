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
      id: 'extended_btn',
      nameKey: AppKeys.moduleExtendedBtn,
      imagePath: 'assets/images/ext_btn_module.png',
      hotspots: [
        // 2x3 Grid - 75x75, shifted slightly left
        ModuleHotspot(
          id: 'btn1',
          left: 160,
          top: 110,
          width: 75,
          height: 75,
          tooltipKey: 'Button 1',
        ),
        ModuleHotspot(
          id: 'btn2',
          left: 250,
          top: 110,
          width: 75,
          height: 75,
          tooltipKey: 'Button 2',
        ),
        ModuleHotspot(
          id: 'btn3',
          left: 160,
          top: 200,
          width: 75,
          height: 75,
          tooltipKey: 'Button 3',
        ),
        ModuleHotspot(
          id: 'btn4',
          left: 250,
          top: 200,
          width: 75,
          height: 75,
          tooltipKey: 'Button 4',
        ),
        ModuleHotspot(
          id: 'btn5',
          left: 160,
          top: 290,
          width: 75,
          height: 75,
          tooltipKey: 'Button 5',
        ),
        ModuleHotspot(
          id: 'btn6',
          left: 250,
          top: 290,
          width: 75,
          height: 75,
          tooltipKey: 'Button 6',
        ),
      ],
    ),
    ModuleConfig(
      id: 'sliders',
      nameKey: AppKeys.moduleSliders,
      imagePath: 'assets/images/sliders_module.png',
      hotspots: [
        // 2 Vertical Areas - Shortened, Moved Up & Left
        ModuleHotspot(
          id: 'slider_left',
          left: 165,
          top: 120,
          width: 60,
          height: 250,
          tooltipKey: 'Left Slider',
        ),
        ModuleHotspot(
          id: 'slider_right',
          left: 260,
          top: 120,
          width: 60,
          height: 250,
          tooltipKey: 'Right Slider',
        ),
      ],
    ),
    ModuleConfig(
      id: 'knobs',
      nameKey: AppKeys.moduleKnobs,
      imagePath: 'assets/images/knobs_module.png',
      hotspots: [
        // 2 Circular Areas (Vertical) - Reduced size to 120, closer together
        ModuleHotspot(
          id: 'knob1',
          left: 188,
          top: 105,
          width: 110,
          height: 110,
          tooltipKey: 'Knob 1',
          isRound: true,
        ),
        ModuleHotspot(
          id: 'knob2',
          left: 188,
          top: 260,
          width: 110,
          height: 110,
          tooltipKey: 'Knob 2',
          isRound: true,
        ),
      ],
    ),
    ModuleConfig(
      id: 'touch',
      nameKey: AppKeys.moduleTouch,
      imagePath: 'assets/images/touch_module.png',
      hotspots: [
        // 3 Vertical Squares
        ModuleHotspot(
          id: 'touch1',
          left: 213,
          top: 105,
          width: 80,
          height: 80,
          tooltipKey: 'Touch 1',
        ),
        ModuleHotspot(
          id: 'touch2',
          left: 213,
          top: 197,
          width: 80,
          height: 80,
          tooltipKey: 'Touch 2',
        ),
        ModuleHotspot(
          id: 'touch3',
          left: 213,
          top: 290,
          width: 80,
          height: 80,
          tooltipKey: 'Touch 3',
        ),
      ],
    ),
    ModuleConfig(
      id: 'switch',
      nameKey: AppKeys.moduleSwitch,
      imagePath: 'assets/images/switch_module.png',
      hotspots: [
        // 2x3 Grid - 65x65, centered (shifted right to 178/268)
        ModuleHotspot(
          id: 'sw1',
          left: 170,
          top: 120,
          width: 65,
          height: 65,
          tooltipKey: 'Switch 1',
        ),
        ModuleHotspot(
          id: 'sw2',
          left: 265,
          top: 120,
          width: 65,
          height: 65,
          tooltipKey: 'Switch 2',
        ),
        ModuleHotspot(
          id: 'sw3',
          left: 170,
          top: 215,
          width: 65,
          height: 65,
          tooltipKey: 'Switch 3',
        ),
        ModuleHotspot(
          id: 'sw4',
          left: 265,
          top: 215,
          width: 65,
          height: 65,
          tooltipKey: 'Switch 4',
        ),
        ModuleHotspot(
          id: 'sw5',
          left: 170,
          top: 305,
          width: 65,
          height: 65,
          tooltipKey: 'Switch 5',
        ),
        ModuleHotspot(
          id: 'sw6',
          left: 265,
          top: 305,
          width: 65,
          height: 65,
          tooltipKey: 'Switch 6',
        ),
      ],
    ),
    ModuleConfig(
      id: 'media',
      nameKey: AppKeys.moduleMedia,
      imagePath: 'assets/images/media_module.png',
      hotspots: [
        // 2 Circular Areas (Top) + 1 Rectangular Area (Bottom)
        ModuleHotspot(
          id: 'media_knob_l',
          left: 55,
          top: 135,
          width: 160,
          height: 160,
          isRound: true,
          tooltipKey: 'Media Knob Left',
        ),
        ModuleHotspot(
          id: 'media_knob_r',
          left: 295,
          top: 135,
          width: 160,
          height: 160,
          isRound: true,
          tooltipKey: 'Media Knob Right',
        ),
        ModuleHotspot(
          id: 'media_bar',
          left: 160,
          top: 320,
          width: 200,
          height: 30,
          tooltipKey: 'Media Bar',
        ),
      ],
    ),
    ModuleConfig(
      id: 'piano',
      nameKey: AppKeys.modulePiano,
      imagePath: 'assets/images/piano_module.png',
      hotspots: [
        // 7 White Keys (Bottom Area) - Tight spacing (2px gap)
        ModuleHotspot(
          id: 'key1',
          left: 75,
          top: 260,
          width: 50,
          height: 110,
          tooltipKey: 'Key 1',
        ),
        ModuleHotspot(
          id: 'key2',
          left: 127,
          top: 260,
          width: 50,
          height: 110,
          tooltipKey: 'Key 2',
        ),
        ModuleHotspot(
          id: 'key3',
          left: 179,
          top: 260,
          width: 50,
          height: 110,
          tooltipKey: 'Key 3',
        ),
        ModuleHotspot(
          id: 'key4',
          left: 231,
          top: 260,
          width: 50,
          height: 110,
          tooltipKey: 'Key 4',
        ),
        ModuleHotspot(
          id: 'key5',
          left: 283,
          top: 260,
          width: 50,
          height: 110,
          tooltipKey: 'Key 5',
        ),
        ModuleHotspot(
          id: 'key6',
          left: 335,
          top: 260,
          width: 50,
          height: 110,
          tooltipKey: 'Key 6',
        ),
        ModuleHotspot(
          id: 'key7',
          left: 387,
          top: 260,
          width: 50,
          height: 110,
          tooltipKey: 'Key 7',
        ),
        // 5 Black Keys (Top Area) - Lowered (Top=125)
        ModuleHotspot(
          id: 'black1',
          left: 112,
          top: 150,
          width: 35,
          height: 110,
          tooltipKey: 'Black 1',
        ),
        ModuleHotspot(
          id: 'black2',
          left: 163,
          top: 150,
          width: 35,
          height: 110,
          tooltipKey: 'Black 2',
        ),
        ModuleHotspot(
          id: 'black3',
          left: 264,
          top: 150,
          width: 35,
          height: 110,
          tooltipKey: 'Black 3',
        ),
        ModuleHotspot(
          id: 'black4',
          left: 316,
          top: 150,
          width: 35,
          height: 110,
          tooltipKey: 'Black 4',
        ),
        ModuleHotspot(
          id: 'black5',
          left: 366,
          top: 150,
          width: 35,
          height: 110,
          tooltipKey: 'Black 5',
        ),
      ],
    ),
    ModuleConfig(
      id: 'modeling',
      nameKey: AppKeys.moduleModeling,
      imagePath: 'assets/images/modeling_module.png',
      hotspots: [
        // 1 Circular (TR), 2 Rect (TL), 1 Sq (Center), 1 Rect (BR) - Centered
        ModuleHotspot(
          id: 'mod_rect1',
          left: 117,
          top: 125,
          width: 60,
          height: 130,
          tooltipKey: 'Rect 1',
        ),
        ModuleHotspot(
          id: 'mod_rect2',
          left: 180,
          top: 125,
          width: 60,
          height: 65,
          tooltipKey: 'Rect 2',
        ),
        ModuleHotspot(
          id: 'mod_circ',
          left: 258,
          top: 106,
          width: 110,
          height: 110,
          isRound: true,
          tooltipKey: 'Circle',
        ),

        ModuleHotspot(
          id: 'mod_sq',
          left: 200,
          top: 215,
          width: 70,
          height: 70,
          tooltipKey: 'Square',
        ),

        ModuleHotspot(
          id: 'mod_wheel',
          left: 320,
          top: 270,
          width: 50,
          height: 90,
          tooltipKey: 'Wheel',
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
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _showConfigDialog(module, hotspot),
                            hoverColor: Colors.black.withValues(alpha: 0.3),
                            highlightColor: Colors.black.withValues(alpha: 0.5),
                            splashColor: Colors.black.withValues(alpha: 0.5),
                            customBorder: hotspot.isRound
                                ? const CircleBorder()
                                : RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                            child: Container(
                              decoration: BoxDecoration(
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
