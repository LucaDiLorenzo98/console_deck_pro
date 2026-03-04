import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import '../l10n/app_translations.dart';
import '../models/module_model.dart';
import '../services/config_service.dart';
import '../services/special_module_audio_service.dart';
import 'package:file_picker/file_picker.dart';
import '../widgets/hotkey_input_field.dart';

class ModulesPage extends StatefulWidget {
  const ModulesPage({super.key});

  @override
  State<ModulesPage> createState() => _ModulesPageState();
}

class _ModulesPageState extends State<ModulesPage> {
  int? _selectedModuleIndex;

  // Store configurations: moduleIndex -> hotspotId -> {type, value}
  final Map<int, Map<String, Map<String, String>>> _moduleConfigs = {};
  final SpecialModuleAudioService _audioService = SpecialModuleAudioService();

  Map<String, dynamic> _mediaConfig = {
    'left_track': '',
    'right_track': '',
    'crossfader': 0.5,
  };

  final Map<String, Map<String, String>> _pianoKeyConfigs = {};
  bool _isLeftDeckPlaying = false;
  bool _isRightDeckPlaying = false;

  static const Map<String, String> _defaultPianoNotes = {
    'piano_key_1': 'C4',
    'piano_key_2': 'D4',
    'piano_key_3': 'E4',
    'piano_key_4': 'F4',
    'piano_key_5': 'G4',
    'piano_key_6': 'A4',
    'piano_key_7': 'B4',
    'piano_black_1': 'C#4',
    'piano_black_2': 'D#4',
    'piano_black_3': 'F#4',
    'piano_black_4': 'G#4',
    'piano_black_5': 'A#4',
  };

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    final fullConfig = await ConfigService.loadConfig();
    final mappings = Map<String, dynamic>.from(
      (fullConfig['mappings'] as Map?) ?? const {},
    );
    final specialModules = Map<String, dynamic>.from(
      (fullConfig['special_modules'] as Map?) ?? const {},
    );
    final mediaConfig = Map<String, dynamic>.from(
      (specialModules['media'] as Map?) ?? const {},
    );
    final pianoConfig = Map<String, dynamic>.from(
      (specialModules['piano'] as Map?) ?? const {},
    );
    final pianoKeysRaw = Map<String, dynamic>.from(
      (pianoConfig['keys'] as Map?) ?? const {},
    );

    final normalizedMediaConfig = {
      'left_track': mediaConfig['left_track']?.toString() ?? '',
      'right_track': mediaConfig['right_track']?.toString() ?? '',
      'crossfader': (mediaConfig['crossfader'] as num?)?.toDouble() ?? 0.5,
    };

    final normalizedPianoConfigs = <String, Map<String, String>>{};
    for (final entry in _defaultPianoNotes.entries) {
      final raw = pianoKeysRaw[entry.key];
      final map = raw is Map ? Map<String, dynamic>.from(raw) : {};
      normalizedPianoConfigs[entry.key] = {
        'note': map['note']?.toString() ?? entry.value,
        'file_path': map['file_path']?.toString() ?? '',
      };
    }

    final crossfader = (normalizedMediaConfig['crossfader'] as double)
        .clamp(0.0, 1.0)
        .toDouble();
    await _audioService.setCrossfader(crossfader);

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
        _mediaConfig = normalizedMediaConfig;
        _pianoKeyConfigs
          ..clear()
          ..addAll(normalizedPianoConfigs);
      });
    }
  }

  final List<ModuleConfig> _modules = const [
    // ... existing modules ... (no change to this list, I'm just replacing top of file)
    ModuleConfig(
      id: 'extended_btn',
      nameKey: AppKeys.moduleExtendedBtn,
      imagePath: 'assets/images/ext_btn_module.png',
      hotspots: [
        // 2x3 Grid - 75x75, shifted slightly left
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
        // 2 Vertical Areas - Shortened, Moved Up & Left
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
        // 2 Circular Areas (Vertical) - Reduced size to 120, closer together
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
        // 3 Vertical Squares
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
    ModuleConfig(
      id: 'switch',
      nameKey: AppKeys.moduleSwitch,
      imagePath: 'assets/images/switch_module.png',
      hotspots: [
        // 2x3 Grid - 65x65, centered (shifted right to 178/268)
        ModuleHotspot(
          id: 'switch_1',
          left: 170,
          top: 120,
          width: 65,
          height: 65,
          tooltipKey: 'Switch 1',
        ),
        ModuleHotspot(
          id: 'switch_2',
          left: 265,
          top: 120,
          width: 65,
          height: 65,
          tooltipKey: 'Switch 2',
        ),
        ModuleHotspot(
          id: 'switch_3',
          left: 170,
          top: 215,
          width: 65,
          height: 65,
          tooltipKey: 'Switch 3',
        ),
        ModuleHotspot(
          id: 'switch_4',
          left: 265,
          top: 215,
          width: 65,
          height: 65,
          tooltipKey: 'Switch 4',
        ),
        ModuleHotspot(
          id: 'switch_5',
          left: 170,
          top: 305,
          width: 65,
          height: 65,
          tooltipKey: 'Switch 5',
        ),
        ModuleHotspot(
          id: 'switch_6',
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
          id: 'media_knob_1',
          left: 55,
          top: 135,
          width: 160,
          height: 160,
          isRound: true,
          tooltipKey: 'Media Knob Left',
        ),
        ModuleHotspot(
          id: 'media_knob_2',
          left: 295,
          top: 135,
          width: 160,
          height: 160,
          isRound: true,
          tooltipKey: 'Media Knob Right',
        ),
        ModuleHotspot(
          id: 'media_bar_1',
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
          id: 'piano_key_1',
          left: 75,
          top: 260,
          width: 50,
          height: 110,
          tooltipKey: 'Key 1',
        ),
        ModuleHotspot(
          id: 'piano_key_2',
          left: 127,
          top: 260,
          width: 50,
          height: 110,
          tooltipKey: 'Key 2',
        ),
        ModuleHotspot(
          id: 'piano_key_3',
          left: 179,
          top: 260,
          width: 50,
          height: 110,
          tooltipKey: 'Key 3',
        ),
        ModuleHotspot(
          id: 'piano_key_4',
          left: 231,
          top: 260,
          width: 50,
          height: 110,
          tooltipKey: 'Key 4',
        ),
        ModuleHotspot(
          id: 'piano_key_5',
          left: 283,
          top: 260,
          width: 50,
          height: 110,
          tooltipKey: 'Key 5',
        ),
        ModuleHotspot(
          id: 'piano_key_6',
          left: 335,
          top: 260,
          width: 50,
          height: 110,
          tooltipKey: 'Key 6',
        ),
        ModuleHotspot(
          id: 'piano_key_7',
          left: 387,
          top: 260,
          width: 50,
          height: 110,
          tooltipKey: 'Key 7',
        ),
        // 5 Black Keys (Top Area) - Lowered (Top=125)
        ModuleHotspot(
          id: 'piano_black_1',
          left: 112,
          top: 150,
          width: 35,
          height: 110,
          tooltipKey: 'Black 1',
        ),
        ModuleHotspot(
          id: 'piano_black_2',
          left: 163,
          top: 150,
          width: 35,
          height: 110,
          tooltipKey: 'Black 2',
        ),
        ModuleHotspot(
          id: 'piano_black_3',
          left: 264,
          top: 150,
          width: 35,
          height: 110,
          tooltipKey: 'Black 3',
        ),
        ModuleHotspot(
          id: 'piano_black_4',
          left: 316,
          top: 150,
          width: 35,
          height: 110,
          tooltipKey: 'Black 4',
        ),
        ModuleHotspot(
          id: 'piano_black_5',
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
          id: 'modeling_rect_1',
          left: 117,
          top: 125,
          width: 60,
          height: 130,
          tooltipKey: 'Rect 1',
        ),
        ModuleHotspot(
          id: 'modeling_rect_2',
          left: 180,
          top: 125,
          width: 60,
          height: 65,
          tooltipKey: 'Rect 2',
        ),
        ModuleHotspot(
          id: 'modeling_circle',
          left: 258,
          top: 106,
          width: 110,
          height: 110,
          isRound: true,
          tooltipKey: 'Circle',
        ),
        ModuleHotspot(
          id: 'modeling_square',
          left: 200,
          top: 215,
          width: 70,
          height: 70,
          tooltipKey: 'Square',
        ),
        ModuleHotspot(
          id: 'modeling_wheel',
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
    final isMediaModule = module.id == 'media';
    final isPianoModule = module.id == 'piano';

    return Column(
      children: [
        Expanded(
          child: Center(
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
                            child:
                                Image.asset(module.imagePath, fit: BoxFit.contain),
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
                                  onTap: () => _handleHotspotTap(module, hotspot),
                                  onLongPress: (isMediaModule || isPianoModule)
                                      ? () => _handleSpecialHotspotLongPress(
                                            module,
                                            hotspot,
                                          )
                                      : null,
                                  hoverColor: Colors.black.withValues(alpha: 0.3),
                                  highlightColor:
                                      Colors.black.withValues(alpha: 0.5),
                                  splashColor:
                                      Colors.black.withValues(alpha: 0.5),
                                  customBorder: hotspot.isRound
                                      ? const CircleBorder()
                                      : RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
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
          ),
        ),
        if (isMediaModule) _buildMediaControlPanel(locale),
        if (isPianoModule) _buildPianoControlPanel(locale),
      ],
    );
  }

  Future<void> _handleHotspotTap(ModuleConfig module, ModuleHotspot hotspot) async {
    if (module.id == 'media') {
      if (hotspot.id == 'media_knob_1') {
        await _toggleDeck(DeckSide.left);
      } else if (hotspot.id == 'media_knob_2') {
        await _toggleDeck(DeckSide.right);
      } else if (hotspot.id == 'media_bar_1') {
        await _setCrossfader(0.5, persist: true);
      }
      return;
    }

    if (module.id == 'piano') {
      await _playPianoKey(hotspot.id);
      return;
    }

    await _showConfigDialog(module, hotspot);
  }

  Future<void> _handleSpecialHotspotLongPress(
    ModuleConfig module,
    ModuleHotspot hotspot,
  ) async {
    if (module.id == 'media') {
      if (hotspot.id == 'media_knob_1') {
        await _pickDeckTrack(DeckSide.left);
      } else if (hotspot.id == 'media_knob_2') {
        await _pickDeckTrack(DeckSide.right);
      } else if (hotspot.id == 'media_bar_1') {
        await _setCrossfader(0.5, persist: true);
      }
      return;
    }

    if (module.id == 'piano') {
      await _showPianoKeyDialog(hotspot.id);
    }
  }

  Widget _buildMediaControlPanel(Locale locale) {
    final crossfader = (_mediaConfig['crossfader'] as num?)?.toDouble() ?? 0.5;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            AppStrings.get(locale, AppKeys.mediaHintLongPress),
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildDeckCard(
                  locale: locale,
                  side: DeckSide.left,
                  title: AppStrings.get(locale, AppKeys.mediaDeckLeft),
                  isPlaying: _isLeftDeckPlaying,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDeckCard(
                  locale: locale,
                  side: DeckSide.right,
                  title: AppStrings.get(locale, AppKeys.mediaDeckRight),
                  isPlaying: _isRightDeckPlaying,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(AppStrings.get(locale, AppKeys.mediaCrossfader)),
              Expanded(
                child: Slider(
                  value: crossfader,
                  min: 0,
                  max: 1,
                  onChanged: (value) => _setCrossfader(value),
                  onChangeEnd: (value) => _setCrossfader(value, persist: true),
                ),
              ),
              IconButton(
                tooltip: AppStrings.get(locale, AppKeys.mediaResetCrossfader),
                onPressed: () => _setCrossfader(0.5, persist: true),
                icon: const Icon(Icons.restore),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeckCard({
    required Locale locale,
    required DeckSide side,
    required String title,
    required bool isPlaying,
  }) {
    final track = _trackForDeck(side);
    final hasTrack = track.isNotEmpty;
    final subtitle = hasTrack
        ? p.basename(track)
        : AppStrings.get(locale, AppKeys.mediaNoTrackSelected);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _pickDeckTrack(side),
                  icon: const Icon(Icons.library_music),
                  label: Text(AppStrings.get(locale, AppKeys.mediaSelectTrack)),
                ),
                FilledButton.icon(
                  onPressed: hasTrack ? () => _toggleDeck(side) : null,
                  icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                  label: Text(AppStrings.get(locale, AppKeys.mediaTogglePlay)),
                ),
                OutlinedButton.icon(
                  onPressed: hasTrack ? () => _stopDeck(side) : null,
                  icon: const Icon(Icons.stop),
                  label: Text(AppStrings.get(locale, AppKeys.mediaStop)),
                ),
                OutlinedButton.icon(
                  onPressed: hasTrack
                      ? () => _jogDeck(side, const Duration(seconds: -2))
                      : null,
                  icon: const Icon(Icons.replay_10),
                  label: Text(AppStrings.get(locale, AppKeys.mediaJogBackward)),
                ),
                OutlinedButton.icon(
                  onPressed: hasTrack
                      ? () => _jogDeck(side, const Duration(seconds: 2))
                      : null,
                  icon: const Icon(Icons.forward_10),
                  label: Text(AppStrings.get(locale, AppKeys.mediaJogForward)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPianoControlPanel(Locale locale) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            AppStrings.get(locale, AppKeys.pianoHintTap),
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            AppStrings.get(locale, AppKeys.pianoHintLongPress),
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _trackForDeck(DeckSide side) {
    return side == DeckSide.left
        ? (_mediaConfig['left_track'] as String? ?? '')
        : (_mediaConfig['right_track'] as String? ?? '');
  }

  Future<void> _pickDeckTrack(DeckSide side) async {
    final picked = await _pickAudioFile();
    if (picked == null) {
      return;
    }

    setState(() {
      if (side == DeckSide.left) {
        _mediaConfig['left_track'] = picked;
        _isLeftDeckPlaying = false;
      } else {
        _mediaConfig['right_track'] = picked;
        _isRightDeckPlaying = false;
      }
    });

    await _saveMediaConfig();
  }

  Future<void> _toggleDeck(DeckSide side) async {
    final locale = Localizations.localeOf(context);
    final path = _trackForDeck(side);
    if (path.isEmpty) {
      _showMessage(AppStrings.get(locale, AppKeys.mediaNoTrackSelected));
      return;
    }

    try {
      final playing = await _audioService.toggleDeckPlayback(
        side,
        filePath: path,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        if (side == DeckSide.left) {
          _isLeftDeckPlaying = playing;
        } else {
          _isRightDeckPlaying = playing;
        }
      });
    } catch (e) {
      _showMessage('$e');
    }
  }

  Future<void> _stopDeck(DeckSide side) async {
    await _audioService.stopDeck(side);
    if (!mounted) {
      return;
    }
    setState(() {
      if (side == DeckSide.left) {
        _isLeftDeckPlaying = false;
      } else {
        _isRightDeckPlaying = false;
      }
    });
  }

  Future<void> _jogDeck(DeckSide side, Duration delta) async {
    await _audioService.jogDeck(side, delta);
  }

  Future<void> _setCrossfader(double value, {bool persist = false}) async {
    final clamped = value.clamp(0.0, 1.0).toDouble();
    setState(() {
      _mediaConfig['crossfader'] = clamped;
    });
    await _audioService.setCrossfader(clamped);
    if (persist) {
      await _saveMediaConfig();
    }
  }

  Future<void> _saveMediaConfig() async {
    await ConfigService.saveSpecialModuleConfig(
      'media',
      {
        'left_track': _mediaConfig['left_track'] ?? '',
        'right_track': _mediaConfig['right_track'] ?? '',
        'crossfader': _mediaConfig['crossfader'] ?? 0.5,
      },
      removeMappingKeys: const [
        'media_knob_1',
        'media_knob_2',
        'media_bar_1',
      ],
    );
  }

  Future<void> _playPianoKey(String keyId) async {
    final locale = Localizations.localeOf(context);
    final config = _pianoKeyConfigs[keyId] ??
        {
          'note': _defaultPianoNotes[keyId] ?? 'C4',
          'file_path': '',
        };
    final note = config['note'] ?? (_defaultPianoNotes[keyId] ?? 'C4');
    final filePath = config['file_path'] ?? '';

    if (filePath.isNotEmpty && !File(filePath).existsSync()) {
      _showMessage(AppStrings.get(locale, AppKeys.audioFileMissing));
    }

    try {
      await _audioService.playPiano(
        note: note,
        customFilePath: filePath,
      );
    } catch (e) {
      _showMessage('$e');
    }
  }

  Future<void> _showPianoKeyDialog(String keyId) async {
    final locale = Localizations.localeOf(context);
    final current = _pianoKeyConfigs[keyId] ??
        {
          'note': _defaultPianoNotes[keyId] ?? 'C4',
          'file_path': '',
        };
    final String note = current['note'] ?? (_defaultPianoNotes[keyId] ?? 'C4');
    String selectedFilePath = current['file_path'] ?? '';

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final hasCustom = selectedFilePath.isNotEmpty;
            return AlertDialog(
              title: Text(
                '${AppStrings.get(locale, AppKeys.configureButton)} $keyId',
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Note: $note'),
                  const SizedBox(height: 8),
                  Text(
                    hasCustom
                        ? '${AppStrings.get(locale, AppKeys.pianoAssignedFile)}: ${p.basename(selectedFilePath)}'
                        : AppStrings.get(locale, AppKeys.pianoUseDefaultNote),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(AppStrings.get(locale, AppKeys.cancel)),
                ),
                TextButton(
                  onPressed: () async {
                    final picked = await _pickAudioFile();
                    if (picked == null) {
                      return;
                    }
                    setDialogState(() {
                      selectedFilePath = picked;
                    });
                  },
                  child: Text(AppStrings.get(locale, AppKeys.pianoPickAudio)),
                ),
                TextButton(
                  onPressed: () async {
                    await _audioService.playPiano(
                      note: note,
                      customFilePath: selectedFilePath,
                    );
                  },
                  child: Text(AppStrings.get(locale, AppKeys.pianoPlaySample)),
                ),
                TextButton(
                  onPressed: () async {
                    setState(() {
                      _pianoKeyConfigs[keyId] = {
                        'note': note,
                        'file_path': '',
                      };
                    });
                    await _savePianoConfig();
                    if (mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                  child: Text(AppStrings.get(locale, AppKeys.pianoResetToNote)),
                ),
                TextButton(
                  onPressed: () async {
                    setState(() {
                      _pianoKeyConfigs[keyId] = {
                        'note': note,
                        'file_path': selectedFilePath,
                      };
                    });
                    await _savePianoConfig();
                    if (mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                  child: Text(AppStrings.get(locale, AppKeys.save)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _savePianoConfig() async {
    final keys = <String, dynamic>{};
    for (final entry in _defaultPianoNotes.entries) {
      final keyId = entry.key;
      final current = _pianoKeyConfigs[keyId] ??
          {
            'note': entry.value,
            'file_path': '',
          };
      keys[keyId] = {
        'note': current['note'] ?? entry.value,
        'file_path': current['file_path'] ?? '',
      };
    }

    await ConfigService.saveSpecialModuleConfig(
      'piano',
      {'keys': keys},
      removeMappingKeys: _defaultPianoNotes.keys.toList(),
    );
  }

  Future<String?> _pickAudioFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'wav', 'ogg', 'flac', 'aac', 'm4a'],
    );
    return result?.files.single.path;
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _showConfigDialog(
    ModuleConfig module,
    ModuleHotspot hotspot,
  ) async {
    if (module.id == 'media' || module.id == 'piano') {
      return;
    }
    final currentLocale = Localizations.localeOf(context);
    final moduleIndex = _modules.indexOf(module);

    // Get current config or defaults
    final currentConfig =
        _moduleConfigs[moduleIndex]?[hotspot.id] ??
        {'type': hotspot.defaultType, 'value': hotspot.defaultValue ?? ''};

    String selectedType = currentConfig['type'] ?? 'None';

    // Determine available types based on module
    final bool isAnalog = module.id == 'sliders' || module.id == 'knobs';
    final bool isModelingRestricted =
        module.id == 'modeling' &&
        [
          'modeling_rect_1',
          'modeling_rect_2',
          'modeling_circle',
        ].contains(hotspot.id);

    final List<String> availableTypes;
    if (isModelingRestricted) {
      availableTypes = ['None', 'Hotkey'];
    } else if (isAnalog) {
      availableTypes = ['None', 'Volume', 'Brightness'];
    } else {
      availableTypes = ['None', 'Link', 'App', 'Hotkey'];
    }

    // Ensure selectedType is valid for this specific hotspot
    if (!availableTypes.contains(selectedType)) {
      selectedType = 'None';
    }

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
                '${AppStrings.get(currentLocale, AppKeys.configureButton)} ${hotspot.id}', // Use hotspot name or ID
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButton<String>(
                      value: availableTypes.contains(selectedType)
                          ? selectedType
                          : 'None',
                      isExpanded: true,
                      items: availableTypes.map<DropdownMenuItem<String>>((
                        String value,
                      ) {
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
                        } else if (value == 'Volume') {
                          label = AppStrings.get(
                            currentLocale,
                            AppKeys.actionVolume,
                          );
                        } else if (value == 'Brightness') {
                          label = AppStrings.get(
                            currentLocale,
                            AppKeys.actionBrightness,
                          );
                        }

                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(label),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setDialogState(() {
                            selectedType = newValue;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                    // Only show extra fields for Standard modules
                    if (!isAnalog) ...[
                      if (selectedType == 'Link')
                        TextField(
                          controller: linkController,
                          decoration: InputDecoration(
                            labelText: AppStrings.get(
                              currentLocale,
                              AppKeys.url,
                            ),
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
                  ],
                  ),
                ),
                // The extra parenthesis that caused the error was here. It has been removed.
                actions: [
                  TextButton(
                    child: Text(AppStrings.get(currentLocale, AppKeys.cancel)),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  TextButton(
                    child: Text(AppStrings.get(currentLocale, AppKeys.save)),
                    onPressed: () async {
                      String value = '';
                      if (selectedType == 'Link') value = linkController.text;
                      if (selectedType == 'App') value = appController.text;
                      if (selectedType == 'Hotkey') value = hotkeyController.text;

                      setState(() {
                        if (_moduleConfigs[moduleIndex] == null) {
                          _moduleConfigs[moduleIndex] = {};
                        }
                        _moduleConfigs[moduleIndex]![hotspot.id] = {
                          'type': selectedType,
                          'value': value,
                        };
                      });

                      await ConfigService.saveMapping(
                        hotspot.id,
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
}
