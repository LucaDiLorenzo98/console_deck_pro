import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../l10n/app_translations.dart';
import '../models/module_model.dart';
import '../services/config_service.dart';
import '../widgets/hotkey_input_field.dart';

class ModulesPage extends StatefulWidget {
  const ModulesPage({super.key});

  @override
  State<ModulesPage> createState() => _ModulesPageState();
}

class _ModulesPageState extends State<ModulesPage> {
  int? _selectedModuleIndex;

  final Map<int, Map<String, Map<String, String>>> _moduleConfigs = {};

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final fullConfig = await ConfigService.loadConfig();
    final mappingsRoot = Map<String, dynamic>.from(
      (fullConfig['mappings'] as Map?) ?? const {},
    );
    final mappings = Map<String, dynamic>.from(
      (mappingsRoot['modules'] as Map?) ?? const {},
    );

    if (mounted) {
      setState(() {
        for (int mIndex = 0; mIndex < _modules.length; mIndex++) {
          final module = _modules[mIndex];
          for (final hotspot in module.hotspots) {
            if (mappings.containsKey(hotspot.id)) {
              if (_moduleConfigs[mIndex] == null) {
                _moduleConfigs[mIndex] = {};
              }
              _moduleConfigs[mIndex]![hotspot.id] =
                  ConfigService.parseConfigEntry(mappings[hotspot.id]);
            }
          }
        }
      });
    }
  }

  final List<ModuleConfig> _modules = const [
    ModuleConfig(
      id: 'extended_btn',
      nameKey: AppKeys.moduleExtendedBtn,
      imagePath: 'assets/images/ext_btn_module.png',
      hotspots: [
        ModuleHotspot(
          id: 'ext_btn_1',
          left: 160,
          top: 110,
          width: 75,
          height: 75,
          tooltipKey: 'Button 1',
        ),
        ModuleHotspot(
          id: 'ext_btn_2',
          left: 250,
          top: 110,
          width: 75,
          height: 75,
          tooltipKey: 'Button 2',
        ),
        ModuleHotspot(
          id: 'ext_btn_3',
          left: 160,
          top: 200,
          width: 75,
          height: 75,
          tooltipKey: 'Button 3',
        ),
        ModuleHotspot(
          id: 'ext_btn_4',
          left: 250,
          top: 200,
          width: 75,
          height: 75,
          tooltipKey: 'Button 4',
        ),
        ModuleHotspot(
          id: 'ext_btn_5',
          left: 160,
          top: 290,
          width: 75,
          height: 75,
          tooltipKey: 'Button 5',
        ),
        ModuleHotspot(
          id: 'ext_btn_6',
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
        ModuleHotspot(
          id: 'slider_1',
          left: 165,
          top: 120,
          width: 60,
          height: 250,
          tooltipKey: 'Left Slider',
        ),
        ModuleHotspot(
          id: 'slider_2',
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
        ModuleHotspot(
          id: 'knob_1',
          left: 188,
          top: 105,
          width: 110,
          height: 110,
          tooltipKey: 'Knob 1',
          isRound: true,
        ),
        ModuleHotspot(
          id: 'knob_2',
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
        ModuleHotspot(
          id: 'touch_1',
          left: 213,
          top: 105,
          width: 80,
          height: 80,
          tooltipKey: 'Touch 1',
        ),
        ModuleHotspot(
          id: 'touch_2',
          left: 213,
          top: 197,
          width: 80,
          height: 80,
          tooltipKey: 'Touch 2',
        ),
        ModuleHotspot(
          id: 'touch_3',
          left: 213,
          top: 290,
          width: 80,
          height: 80,
          tooltipKey: 'Touch 3',
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final currentLocale = Localizations.localeOf(context);

    return Row(
      children: [
        SizedBox(
          width: 200,
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
    return SingleChildScrollView(
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
    );
  }

  Future<void> _showConfigDialog(
    ModuleConfig module,
    ModuleHotspot hotspot,
  ) async {
    final currentLocale = Localizations.localeOf(context);
    final moduleIndex = _selectedModuleIndex!;

    final currentConfig =
        _moduleConfigs[moduleIndex]?[hotspot.id] ??
        {'type': hotspot.defaultType, 'value': hotspot.defaultValue ?? ''};

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => _ConfigDialog(
        locale: currentLocale,
        module: module,
        hotspot: hotspot,
        currentConfig: currentConfig,
      ),
    );

    if (result == null || !mounted) return;

    setState(() {
      if (_moduleConfigs[moduleIndex] == null) {
        _moduleConfigs[moduleIndex] = {};
      }
      _moduleConfigs[moduleIndex]![hotspot.id] = result;
    });

    await ConfigService.saveMapping(
      hotspot.id,
      result['type']!,
      result['value']!,
    );
  }
}

class _ConfigDialog extends StatefulWidget {
  final Locale locale;
  final ModuleConfig module;
  final ModuleHotspot hotspot;
  final Map<String, String> currentConfig;

  const _ConfigDialog({
    required this.locale,
    required this.module,
    required this.hotspot,
    required this.currentConfig,
  });

  @override
  State<_ConfigDialog> createState() => _ConfigDialogState();
}

class _ConfigDialogState extends State<_ConfigDialog> {
  late String _selectedType;
  late final List<String> _availableTypes;
  late final TextEditingController _linkController;
  late final TextEditingController _appController;
  late final TextEditingController _hotkeyController;
  late final TextEditingController _audioController;

  bool get _isAnalog =>
      widget.module.id == 'sliders' || widget.module.id == 'knobs';

  @override
  void initState() {
    super.initState();
    final config = widget.currentConfig;

    _availableTypes = _isAnalog
        ? ['None', 'Volume']
        : ['None', 'Link', 'App', 'Hotkey', 'Audio'];

    _selectedType = config['type'] ?? 'None';
    if (!_availableTypes.contains(_selectedType)) {
      _selectedType = 'None';
    }

    _linkController = TextEditingController(
      text: _selectedType == 'Link' ? config['value'] : '',
    );
    _appController = TextEditingController(
      text: _selectedType == 'App' ? config['value'] : '',
    );
    _hotkeyController = TextEditingController(
      text: _selectedType == 'Hotkey' ? config['value'] : '',
    );
    _audioController = TextEditingController(
      text: _selectedType == 'Audio' ? config['value'] : '',
    );
  }

  @override
  void dispose() {
    _linkController.dispose();
    _appController.dispose();
    _hotkeyController.dispose();
    _audioController.dispose();
    super.dispose();
  }

  Map<String, String> _buildResult() {
    String value = '';
    if (_selectedType == 'Link') value = _linkController.text;
    if (_selectedType == 'App') value = _appController.text;
    if (_selectedType == 'Hotkey') value = _hotkeyController.text;
    if (_selectedType == 'Audio') value = _audioController.text;
    return {'type': _selectedType, 'value': value};
  }

  @override
  Widget build(BuildContext context) {
    final locale = widget.locale;
    final hotspot = widget.hotspot;

    return AlertDialog(
      title: Text(
        '${AppStrings.get(locale, AppKeys.configureButton)} ${hotspot.id}',
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButton<String>(
              value: _availableTypes.contains(_selectedType)
                  ? _selectedType
                  : 'None',
              isExpanded: true,
              items: _availableTypes.map<DropdownMenuItem<String>>((value) {
                String label = value;
                if (value == 'None') {
                  label = AppStrings.get(locale, AppKeys.typeNone);
                } else if (value == 'Link') {
                  label = AppStrings.get(locale, AppKeys.typeLink);
                } else if (value == 'App') {
                  label = AppStrings.get(locale, AppKeys.typeApp);
                } else if (value == 'Hotkey') {
                  label = AppStrings.get(locale, AppKeys.typeHotkey);
                } else if (value == 'Volume') {
                  label = AppStrings.get(locale, AppKeys.actionVolume);
                } else if (value == 'Brightness') {
                  label = AppStrings.get(locale, AppKeys.actionBrightness);
                } else if (value == 'Audio') {
                  label = AppStrings.get(locale, AppKeys.typeAudio);
                }
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(label),
                );
              }).toList(),
              onChanged: (newValue) {
                if (newValue != null) {
                  setState(() => _selectedType = newValue);
                }
              },
            ),
            const SizedBox(height: 20),
            if (!_isAnalog) ...[
              if (_selectedType == 'Link')
                TextField(
                  controller: _linkController,
                  decoration: InputDecoration(
                    labelText: AppStrings.get(locale, AppKeys.url),
                    hintText: AppStrings.get(locale, AppKeys.urlHint),
                    border: const OutlineInputBorder(),
                  ),
                ),
              if (_selectedType == 'App')
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _appController,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: AppStrings.get(
                            locale,
                            AppKeys.executablePath,
                          ),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.folder_open),
                      onPressed: () async {
                        final result = await FilePicker.platform.pickFiles(
                          type: FileType.custom,
                          allowedExtensions: ['exe', 'bat', 'cmd'],
                        );
                        if (result != null) {
                          setState(() {
                            _appController.text = result.files.single.path!;
                          });
                        }
                      },
                    ),
                  ],
                ),
              if (_selectedType == 'Hotkey')
                HotkeyInputField(
                  controller: _hotkeyController,
                  labelText: AppStrings.get(locale, AppKeys.hotkeyCombo),
                  hintText: AppStrings.get(locale, AppKeys.hotkeyHint),
                  clearTooltip: AppStrings.get(locale, AppKeys.clear),
                ),
              if (_selectedType == 'Audio')
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _audioController,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: AppStrings.get(locale, AppKeys.audioFile),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.file_open),
                      onPressed: () async {
                        final result = await FilePicker.platform.pickFiles(
                          type: FileType.custom,
                          allowedExtensions: [
                            'wav', 'mp3', 'ogg', 'flac', 'm4a',
                          ],
                        );
                        if (result != null) {
                          setState(() {
                            _audioController.text = result.files.single.path!;
                          });
                        }
                      },
                    ),
                  ],
                ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          child: Text(AppStrings.get(locale, AppKeys.cancel)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        TextButton(
          child: Text(AppStrings.get(locale, AppKeys.save)),
          onPressed: () => Navigator.of(context).pop(_buildResult()),
        ),
      ],
    );
  }
}
