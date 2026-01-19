class ModuleConfig {
  final String id;
  final String nameKey; // AppKeys constant
  final String imagePath;
  final List<ModuleHotspot> hotspots;

  const ModuleConfig({
    required this.id,
    required this.nameKey,
    required this.imagePath,
    this.hotspots = const [],
  });
}

class ModuleHotspot {
  final String id;
  final double left;
  final double top;
  final double width;
  final double height;
  final String defaultType; // 'Link', 'App', 'Hotkey'
  final String? defaultValue;
  final String tooltipKey; // AppKeys constant
  final bool isRound;

  const ModuleHotspot({
    required this.id,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    this.defaultType = 'Link',
    this.defaultValue,
    required this.tooltipKey,
    this.isRound = false,
  });
}
