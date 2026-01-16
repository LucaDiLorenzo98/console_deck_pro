import 'package:flutter/material.dart';

class AppKeys {
  static const String home = 'home';
  static const String modules = 'modules';
  static const String settings = 'settings';
  static const String themeLight = 'theme_light';
  static const String themeDark = 'theme_dark';
  static const String language = 'language';
  static const String knobTooltip = 'knob_tooltip';
  static const String screenTooltip = 'screen_tooltip';
  static const String magnetTooltip = 'magnet_tooltip';
  static const String appVersion = 'app_version';

  // Dialogs & Interactions
  static const String configureButton = 'configure_button';
  static const String typeLink = 'type_link';
  static const String typeApp = 'type_app';
  static const String typeHotkey = 'type_hotkey';
  static const String url = 'url';
  static const String urlHint = 'url_hint';
  static const String executablePath = 'executable_path';
  static const String hotkeyCombo = 'hotkey_combo';
  static const String hotkeyHint = 'hotkey_hint';
  static const String cancel = 'cancel';
  static const String save = 'save';
  static const String modulesPageTitle = 'modules_page_title';
}

class AppStrings {
  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      AppKeys.home: 'Home',
      AppKeys.modules: 'Modules',
      AppKeys.settings: 'Settings',
      AppKeys.themeLight: 'Light Theme',
      AppKeys.themeDark: 'Dark Theme',
      AppKeys.language: 'Language',
      AppKeys.knobTooltip:
          'Rotate to adjust volume.\nHold to enter settings.\nPress to mute/unmute.',
      AppKeys.screenTooltip: 'OLED Display.\nShows selected information.',
      AppKeys.magnetTooltip: 'Magnetic Connector.\nAttach modules here.',
      AppKeys.appVersion: 'Console Deck PRO',
      AppKeys.configureButton: 'Configure Button',
      AppKeys.typeLink: 'Link',
      AppKeys.typeApp: 'App',
      AppKeys.typeHotkey: 'Hotkey',
      AppKeys.url: 'URL',
      AppKeys.urlHint: 'https://example.com',
      AppKeys.executablePath: 'Executable Path',
      AppKeys.hotkeyCombo: 'Hotkey Combo',
      AppKeys.hotkeyHint: 'CTRL+C',
      AppKeys.cancel: 'Cancel',
      AppKeys.save: 'Save',
      AppKeys.modulesPageTitle: 'Modules Page',
    },
    'it': {
      AppKeys.home: 'Home',
      AppKeys.modules: 'Moduli',
      AppKeys.settings: 'Impostazioni',
      AppKeys.themeLight: 'Tema Chiaro',
      AppKeys.themeDark: 'Tema Scuro',
      AppKeys.language: 'Lingua',
      AppKeys.knobTooltip:
          'Ruota per regolare il volume.\nTieni premuto per le impostazioni.\nPremi per mutare.',
      AppKeys.screenTooltip:
          'Display OLED.\nMostra le informazioni selezionate.',
      AppKeys.magnetTooltip: 'Connettore Magnetico.\nCollega qui i moduli.',
      AppKeys.appVersion: 'Console Deck PRO',
      AppKeys.configureButton: 'Configura Pulsante',
      AppKeys.typeLink: 'Link',
      AppKeys.typeApp: 'App',
      AppKeys.typeHotkey: 'Hotkey',
      AppKeys.url: 'URL',
      AppKeys.urlHint: 'https://compra.com',
      AppKeys.executablePath: 'Percorso Eseguibile',
      AppKeys.hotkeyCombo: 'Combinazione Tasti',
      AppKeys.hotkeyHint: 'CTRL+C',
      AppKeys.cancel: 'Annulla',
      AppKeys.save: 'Salva',
      AppKeys.modulesPageTitle: 'Pagina Moduli',
    },
    'es': {
      AppKeys.home: 'Inicio',
      AppKeys.modules: 'Módulos',
      AppKeys.settings: 'Ajustes',
      AppKeys.themeLight: 'Tema Claro',
      AppKeys.themeDark: 'Tema Oscuro',
      AppKeys.language: 'Idioma',
      AppKeys.knobTooltip:
          'Girar para ajustar volumen.\nMantener para ajustes.\nPresionar para silenciar.',
      AppKeys.screenTooltip:
          'Pantalla OLED.\nMuestra información seleccionada.',
      AppKeys.magnetTooltip: 'Conector Magnético.\nConectar módulos aquí.',
      AppKeys.appVersion: 'Console Deck PRO',
      AppKeys.configureButton: 'Configurar Botón',
      AppKeys.typeLink: 'Enlace',
      AppKeys.typeApp: 'App',
      AppKeys.typeHotkey: 'Atajo',
      AppKeys.url: 'URL',
      AppKeys.urlHint: 'https://ejemplo.com',
      AppKeys.executablePath: 'Ruta Ejecutable',
      AppKeys.hotkeyCombo: 'Combinación',
      AppKeys.hotkeyHint: 'CTRL+C',
      AppKeys.cancel: 'Cancelar',
      AppKeys.save: 'Guardar',
      AppKeys.modulesPageTitle: 'Página de Módulos',
    },
    'fr': {
      AppKeys.home: 'Accueil',
      AppKeys.modules: 'Modules',
      AppKeys.settings: 'Paramètres',
      AppKeys.themeLight: 'Thème Clair',
      AppKeys.themeDark: 'Thème Sombre',
      AppKeys.language: 'Langue',
      AppKeys.knobTooltip:
          'Tourner pour régler le volume.\nMaintenir pour les paramètres.\nAppuyer pour couper le son.',
      AppKeys.screenTooltip:
          'Écran OLED.\nAffiche les informations sélectionnées.',
      AppKeys.magnetTooltip:
          'Connecteur Magnétique.\nAttacher les modules ici.',
      AppKeys.appVersion: 'Console Deck PRO',
      AppKeys.configureButton: 'Configurer Bouton',
      AppKeys.typeLink: 'Lien',
      AppKeys.typeApp: 'App',
      AppKeys.typeHotkey: 'Raccourci',
      AppKeys.url: 'URL',
      AppKeys.urlHint: 'https://exemple.com',
      AppKeys.executablePath: 'Chemin Exécutable',
      AppKeys.hotkeyCombo: 'Combinaison',
      AppKeys.hotkeyHint: 'CTRL+C',
      AppKeys.cancel: 'Annuler',
      AppKeys.save: 'Sauvegarder',
      AppKeys.modulesPageTitle: 'Page Modules',
    },
    'de': {
      AppKeys.home: 'Startseite',
      AppKeys.modules: 'Module',
      AppKeys.settings: 'Einstellungen',
      AppKeys.themeLight: 'Helles Design',
      AppKeys.themeDark: 'Dunkles Design',
      AppKeys.language: 'Sprache',
      AppKeys.knobTooltip:
          'Drehen für Lautstärke.\nHalten für Einstellungen.\nDrücken für Stumm.',
      AppKeys.screenTooltip: 'OLED-Display.\nZeigt ausgewählte Informationen.',
      AppKeys.magnetTooltip:
          'Magnetischer Anschluss.\nModule hier anschließen.',
      AppKeys.appVersion: 'Console Deck PRO',
      AppKeys.configureButton: 'Taste Konfigurieren',
      AppKeys.typeLink: 'Link',
      AppKeys.typeApp: 'App',
      AppKeys.typeHotkey: 'Hotkey',
      AppKeys.url: 'URL',
      AppKeys.urlHint: 'https://beispiel.de',
      AppKeys.executablePath: 'Pfad',
      AppKeys.hotkeyCombo: 'Tastenkombination',
      AppKeys.hotkeyHint: 'STRG+C',
      AppKeys.cancel: 'Abbrechen',
      AppKeys.save: 'Speichern',
      AppKeys.modulesPageTitle: 'Modulseite',
    },
    'zh': {
      AppKeys.home: '首页',
      AppKeys.modules: '模块',
      AppKeys.settings: '设置',
      AppKeys.themeLight: '浅色主题',
      AppKeys.themeDark: '深色主题',
      AppKeys.language: '语言',
      AppKeys.knobTooltip: '旋转调节音量。\n长按进入设置。\n按下静音/取消静音。',
      AppKeys.screenTooltip: 'OLED 显示屏。\n显示选定的信息。',
      AppKeys.magnetTooltip: '磁性连接器。\n在此连接模块。',
      AppKeys.appVersion: 'Console Deck PRO',
      AppKeys.configureButton: '配置按钮',
      AppKeys.typeLink: '链接',
      AppKeys.typeApp: '应用',
      AppKeys.typeHotkey: '热键',
      AppKeys.url: 'URL',
      AppKeys.urlHint: 'https://example.com',
      AppKeys.executablePath: '执行路径',
      AppKeys.hotkeyCombo: '组合键',
      AppKeys.hotkeyHint: 'CTRL+C',
      AppKeys.cancel: '取消',
      AppKeys.save: '保存',
      AppKeys.modulesPageTitle: '模块页面',
    },
    'ja': {
      AppKeys.home: 'ホーム',
      AppKeys.modules: 'モジュール',
      AppKeys.settings: '設定',
      AppKeys.themeLight: 'ライトテーマ',
      AppKeys.themeDark: 'ダークテーマ',
      AppKeys.language: '言語',
      AppKeys.knobTooltip: '回して音量を調整。\n長押しで設定。\n押してミュート。',
      AppKeys.screenTooltip: 'OLED ディスプレイ。\n選択した情報を表示します。',
      AppKeys.magnetTooltip: '磁気コネクタ。\nここにモジュールを取り付けます。',
      AppKeys.appVersion: 'Console Deck PRO',
      AppKeys.configureButton: 'ボタン設定',
      AppKeys.typeLink: 'リンク',
      AppKeys.typeApp: 'アプリ',
      AppKeys.typeHotkey: 'ホットキー',
      AppKeys.url: 'URL',
      AppKeys.urlHint: 'https://example.com',
      AppKeys.executablePath: '実行パス',
      AppKeys.hotkeyCombo: 'キーの組み合わせ',
      AppKeys.hotkeyHint: 'CTRL+C',
      AppKeys.cancel: 'キャンセル',
      AppKeys.save: '保存',
      AppKeys.modulesPageTitle: 'モジュールページ',
    },
  };

  static String get(Locale locale, String key) {
    // Check full language code (e.g., 'en', 'it')
    if (_localizedValues.containsKey(locale.languageCode)) {
      return _localizedValues[locale.languageCode]![key] ?? key;
    }
    // Default to English if not found
    return _localizedValues['en']![key] ?? key;
  }
}
