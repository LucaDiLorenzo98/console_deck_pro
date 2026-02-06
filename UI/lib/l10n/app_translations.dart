import 'package:flutter/material.dart';

class AppKeys {
  static const String home = 'home';
  static const String modules = 'modules';
  static const String skinCreator = 'Skin Creator';
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
  static const String typeNone = 'type_none';
  static const String typeLink = 'type_link';
  static const String typeApp = 'type_app';
  static const String typeHotkey = 'type_hotkey';
  static const String actionVolume = 'action_volume';
  static const String actionBrightness = 'action_brightness';
  static const String url = 'url';
  static const String urlHint = 'url_hint';
  static const String executablePath = 'executable_path';
  static const String hotkeyCombo = 'hotkey_combo';
  static const String hotkeyHint = 'hotkey_hint';
  static const String cancel = 'cancel';
  static const String save = 'save';
  static const String modulesPageTitle = 'modules_page_title';
  static const String selectModuleHint = 'select_module_hint';

  // Module Names
  static const String moduleMedia = 'module_media';
  static const String moduleKnobs = 'module_knobs';
  static const String moduleSliders = 'module_sliders';
  static const String moduleTouch = 'module_touch';
  static const String moduleSwitch = 'module_switch';
  static const String moduleExtendedBtn = 'module_extended_btn';
  static const String modulePiano = 'module_piano';
  static const String moduleModeling = 'module_modeling';

  // Media Module Actions
  static const String mediaPlayPause = 'media_play_pause';
  static const String mediaNext = 'media_next';
  static const String mediaPrev = 'media_prev';
  static const String mediaVolUp = 'media_vol_up';
  static const String mediaVolDown = 'media_vol_down';

  // Settings Links
  static const String visitWebsite = 'visit_website';
  static const String visitMakerWorld = 'visit_makerworld';
  static const String socialNetworks = 'social_networks';
  static const String reportProblem = 'report_problem';
  static const String reportSubject = 'report_subject';
  static const String reportBodyPrototype = 'report_body_prototype';
  static const String browse = 'browse';
  static const String generate = 'generate';
  // Upload / Skin generation messages
  static const String uploadSuccess = 'upload_success';
  static const String uploadAuthError = 'upload_auth_error';
  static const String uploadTooLarge = 'upload_too_large';
  static const String uploadInvalidSvg = 'upload_invalid_svg';
  static const String uploadTooManyRequests = 'upload_too_many_requests';
  static const String uploadComplexLogo = 'upload_complex_logo';
  static const String uploadServerError = 'upload_server_error';
  static const String uploadTimeout = 'upload_timeout';
  static const String fileNotFound = 'file_not_found';
  static const String openFolder = 'open_folder';
  static const String fileSavedPrefix = 'file_saved_prefix';
  static const String errorPrefix = 'error_prefix';
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
      AppKeys.typeNone: 'None',
      AppKeys.typeLink: 'Link',
      AppKeys.typeApp: 'App',
      AppKeys.typeHotkey: 'Hotkey',
      AppKeys.actionVolume: 'Volume',
      AppKeys.actionBrightness: 'Brightness',
      AppKeys.url: 'URL',
      AppKeys.urlHint: 'https://example.com',
      AppKeys.executablePath: 'Executable Path',
      AppKeys.hotkeyCombo: 'Hotkey Combo',
      AppKeys.hotkeyHint: 'CTRL+C',
      AppKeys.cancel: 'Cancel',
      AppKeys.save: 'Save',
      AppKeys.modulesPageTitle: 'Modules Page',
      AppKeys.selectModuleHint: 'Select a module to configure',
      AppKeys.moduleMedia: 'Media',
      AppKeys.moduleKnobs: 'Knobs',
      AppKeys.moduleSliders: 'Sliders',
      AppKeys.moduleTouch: 'Touch',
      AppKeys.moduleSwitch: 'Switches',
      AppKeys.moduleExtendedBtn: 'Extended Buttons',
      AppKeys.modulePiano: 'Piano',
      AppKeys.moduleModeling: 'Modeling',
      AppKeys.mediaPlayPause: 'Play/Pause',
      AppKeys.mediaNext: 'Next Track',
      AppKeys.mediaPrev: 'Previous Track',
      AppKeys.mediaVolUp: 'Volume Up',
      AppKeys.mediaVolDown: 'Volume Down',
      AppKeys.visitWebsite: 'Visit Website',
      AppKeys.visitMakerWorld: 'Visit MakerWorld',
      AppKeys.socialNetworks: 'Social Networks',
      AppKeys.reportProblem: 'Report a Problem',
      AppKeys.reportSubject: 'Console Deck PRO Report Issue',
      AppKeys.reportBodyPrototype: 'Issue Description: ',
      AppKeys.browse: 'Browse',
      AppKeys.generate: 'Generate',
      // Upload / Skin generation messages
      AppKeys.uploadSuccess: 'Success! Your 3D file is ready.',
      AppKeys.uploadAuthError: 'App authentication failed.',
      AppKeys.uploadTooLarge: 'File is too large. Maximum 5MB.',
      AppKeys.uploadInvalidSvg: 'Uploaded file is not a valid SVG.',
      AppKeys.uploadTooManyRequests: 'Too many requests. Please wait and try again later!',
      AppKeys.uploadComplexLogo: 'The logo is too complex for 3D rendering.',
      AppKeys.uploadServerError: 'An unexpected server error occurred.',
      AppKeys.uploadTimeout: 'Operation timed out. Please try again.',
      AppKeys.fileNotFound: 'File not found',
      AppKeys.fileSavedPrefix: 'File saved:',
      AppKeys.errorPrefix: 'Error:',
      AppKeys.openFolder: 'Open Folder',
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
      AppKeys.typeNone: 'Nessuno',
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
      AppKeys.selectModuleHint: 'Seleziona un modulo per configurarlo',
      AppKeys.moduleMedia: 'Media',
      AppKeys.moduleKnobs: 'Manopole',
      AppKeys.moduleSliders: 'Slider',
      AppKeys.moduleTouch: 'Touch',
      AppKeys.moduleSwitch: 'Interruttori',
      AppKeys.moduleExtendedBtn: 'Pulsanti Estesi',
      AppKeys.modulePiano: 'Piano',
      AppKeys.moduleModeling: 'Modellazione',
      AppKeys.mediaPlayPause: 'Play/Pausa',
      AppKeys.mediaNext: 'Traccia Successiva',
      AppKeys.mediaPrev: 'Traccia Precedente',
      AppKeys.mediaVolUp: 'Volume Su',
      AppKeys.mediaVolDown: 'Volume Giù',
      AppKeys.visitWebsite: 'Visita il Sito',
      AppKeys.visitMakerWorld: 'Visita MakerWorld',
      AppKeys.socialNetworks: 'Social Network',
      AppKeys.reportProblem: 'Segnala un Problema',
      AppKeys.reportSubject: 'Segnalazione Problema Console Deck PRO',
      AppKeys.reportBodyPrototype: 'Descrizione del problema: ',
      AppKeys.browse: 'Sfoglia',
      AppKeys.generate: 'Genera',
      // Upload / Skin generation messages (Italian)
      AppKeys.uploadSuccess: 'Successo! Il tuo file 3D è pronto.',
      AppKeys.uploadAuthError: "Errore di autenticazione dell'app.",
      AppKeys.uploadTooLarge: "Il file è troppo pesante. Massimo 5MB.",
      AppKeys.uploadInvalidSvg: "Il file caricato non è un SVG valido.",
      AppKeys.uploadTooManyRequests: "Troppe richieste. Fai una pausa e riprova più tardi!",
      AppKeys.uploadComplexLogo: "Il logo è troppo complesso per il rendering 3D.",
      AppKeys.uploadServerError: "C'è stato un problema imprevisto sul server.",
      AppKeys.uploadTimeout: 'Tempo di attesa scaduto. Riprova più tardi.',
      AppKeys.fileNotFound: 'File non trovato',
      AppKeys.fileSavedPrefix: 'File salvato:',
      AppKeys.errorPrefix: 'Errore:',
      AppKeys.openFolder: 'Apri Cartella',
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
      AppKeys.typeNone: 'Ninguno',
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
      AppKeys.selectModuleHint: 'Selecciona un módulo para configurar',
      AppKeys.moduleMedia: 'Multimedia',
      AppKeys.moduleKnobs: 'Perillas',
      AppKeys.moduleSliders: 'Deslizadores',
      AppKeys.moduleTouch: 'Táctil',
      AppKeys.moduleSwitch: 'Interruptores',
      AppKeys.moduleExtendedBtn: 'Botones Extendidos',
      AppKeys.modulePiano: 'Piano',
      AppKeys.moduleModeling: 'Modelado',
      AppKeys.mediaPlayPause: 'Reproducir/Pausar',
      AppKeys.mediaNext: 'Siguiente Pista',
      AppKeys.mediaPrev: 'Pista Anterior',
      AppKeys.mediaVolUp: 'Subir Volumen',
      AppKeys.mediaVolDown: 'Bajar Volumen',
      AppKeys.visitWebsite: 'Visitar Sitio Web',
      AppKeys.visitMakerWorld: 'Visitar MakerWorld',
      AppKeys.socialNetworks: 'Redes Sociales',
      AppKeys.reportProblem: 'Reportar Problema',
      AppKeys.reportSubject: 'Reporte de Problema Console Deck PRO',
      AppKeys.reportBodyPrototype: 'Descripción del problema: ',
      // Upload messages (fallback to English)
      AppKeys.uploadSuccess: 'Success! Your 3D file is ready.',
      AppKeys.uploadAuthError: 'App authentication failed.',
      AppKeys.uploadTooLarge: 'File is too large. Maximum 5MB.',
      AppKeys.uploadInvalidSvg: 'Uploaded file is not a valid SVG.',
      AppKeys.uploadTooManyRequests: 'Too many requests. Please wait and try again later!',
      AppKeys.uploadComplexLogo: 'The logo is too complex for 3D rendering.',
      AppKeys.uploadServerError: 'An unexpected server error occurred.',
      AppKeys.fileNotFound: 'File not found',
      AppKeys.fileSavedPrefix: 'File saved:',
      AppKeys.errorPrefix: 'Error:',
      AppKeys.openFolder: 'Open Folder',
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
      AppKeys.typeNone: 'Aucun',
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
      AppKeys.selectModuleHint: 'Sélectionnez un module à configurer',
      AppKeys.moduleMedia: 'Média',
      AppKeys.moduleKnobs: 'Boutons',
      AppKeys.moduleSliders: 'Curseurs',
      AppKeys.moduleTouch: 'Tactile',
      AppKeys.moduleSwitch: 'Interrupteurs',
      AppKeys.moduleExtendedBtn: 'Boutons Étendus',
      AppKeys.modulePiano: 'Piano',
      AppKeys.moduleModeling: 'Modélisation',
      AppKeys.mediaPlayPause: 'Lecture/Pause',
      AppKeys.mediaNext: 'Piste Suivante',
      AppKeys.mediaPrev: 'Piste Précédente',
      AppKeys.mediaVolUp: 'Volume +',
      AppKeys.mediaVolDown: 'Volume -',
      AppKeys.visitWebsite: 'Visiter le Site Web',
      AppKeys.visitMakerWorld: 'Visiter MakerWorld',
      AppKeys.socialNetworks: 'Réseaux Sociaux',
      AppKeys.reportProblem: 'Signaler un Problème',
      AppKeys.reportSubject: 'Problème Console Deck PRO',
      AppKeys.reportBodyPrototype: 'Description du problème: ',
      AppKeys.uploadSuccess: 'Success! Your 3D file is ready.',
      AppKeys.uploadAuthError: 'App authentication failed.',
      AppKeys.uploadTooLarge: 'File is too large. Maximum 5MB.',
      AppKeys.uploadInvalidSvg: 'Uploaded file is not a valid SVG.',
      AppKeys.uploadTooManyRequests: 'Too many requests. Please wait and try again later!',
      AppKeys.uploadComplexLogo: 'The logo is too complex for 3D rendering.',
      AppKeys.uploadServerError: 'An unexpected server error occurred.',
      AppKeys.fileNotFound: 'File not found',
      AppKeys.fileSavedPrefix: 'File saved:',
      AppKeys.errorPrefix: 'Error:',
      AppKeys.openFolder: 'Open Folder',
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
      AppKeys.typeNone: 'Keins',
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
      AppKeys.selectModuleHint: 'Wählen Sie ein Modul zum Konfigurieren',
      AppKeys.moduleMedia: 'Medien',
      AppKeys.moduleKnobs: 'Drehregler',
      AppKeys.moduleSliders: 'Schieberegler',
      AppKeys.moduleTouch: 'Touch',
      AppKeys.moduleSwitch: 'Schalter',
      AppKeys.moduleExtendedBtn: 'Erweiterte Tasten',
      AppKeys.modulePiano: 'Klavier',
      AppKeys.moduleModeling: 'Modellierung',
      AppKeys.mediaPlayPause: 'Wiedergabe/Pause',
      AppKeys.mediaNext: 'Nächster Titel',
      AppKeys.mediaPrev: 'Vorheriger Titel',
      AppKeys.mediaVolUp: 'Lautstärke +',
      AppKeys.mediaVolDown: 'Lautstärke -',
      AppKeys.visitWebsite: 'Webseite Besuchen',
      AppKeys.visitMakerWorld: 'Besuche MakerWorld',
      AppKeys.socialNetworks: 'Soziale Netzwerke',
      AppKeys.reportProblem: 'Problem Melden',
      AppKeys.reportSubject: 'Console Deck PRO Problem',
      AppKeys.reportBodyPrototype: 'Problembeschreibung: ',
      AppKeys.uploadSuccess: 'Success! Your 3D file is ready.',
      AppKeys.uploadAuthError: 'App authentication failed.',
      AppKeys.uploadTooLarge: 'File is too large. Maximum 5MB.',
      AppKeys.uploadInvalidSvg: 'Uploaded file is not a valid SVG.',
      AppKeys.uploadTooManyRequests: 'Too many requests. Please wait and try again later!',
      AppKeys.uploadComplexLogo: 'The logo is too complex for 3D rendering.',
      AppKeys.uploadServerError: 'An unexpected server error occurred.',
      AppKeys.fileNotFound: 'File not found',
      AppKeys.fileSavedPrefix: 'File saved:',
      AppKeys.errorPrefix: 'Error:',
      AppKeys.openFolder: 'Open Folder',
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
      AppKeys.typeNone: '无',
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
      AppKeys.selectModuleHint: '选择要配置的模块',
      AppKeys.moduleMedia: '媒体',
      AppKeys.moduleKnobs: '旋钮',
      AppKeys.moduleSliders: '滑块',
      AppKeys.moduleTouch: '触摸',
      AppKeys.moduleSwitch: '开关',
      AppKeys.moduleExtendedBtn: '扩展按钮',
      AppKeys.modulePiano: '钢琴',
      AppKeys.moduleModeling: '建模',
      AppKeys.mediaPlayPause: '播放/暂停',
      AppKeys.mediaNext: '下一首',
      AppKeys.mediaPrev: '上一首',
      AppKeys.mediaVolUp: '音量 +',
      AppKeys.mediaVolDown: '音量 -',
      AppKeys.visitWebsite: '访问网站',
      AppKeys.visitMakerWorld: '访问 MakerWorld',
      AppKeys.socialNetworks: '社交网络',
      AppKeys.reportProblem: '报告问题',
      AppKeys.reportSubject: 'Console Deck PRO 问题报告',
      AppKeys.reportBodyPrototype: '问题描述: ',
      AppKeys.uploadSuccess: 'Success! Your 3D file is ready.',
      AppKeys.uploadAuthError: 'App authentication failed.',
      AppKeys.uploadTooLarge: 'File is too large. Maximum 5MB.',
      AppKeys.uploadInvalidSvg: 'Uploaded file is not a valid SVG.',
      AppKeys.uploadTooManyRequests: 'Too many requests. Please wait and try again later!',
      AppKeys.uploadComplexLogo: 'The logo is too complex for 3D rendering.',
      AppKeys.uploadServerError: 'An unexpected server error occurred.',
      AppKeys.fileNotFound: 'File not found',
      AppKeys.fileSavedPrefix: 'File saved:',
      AppKeys.errorPrefix: 'Error:',
      AppKeys.openFolder: 'Open Folder',
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
      AppKeys.typeNone: 'なし',
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
      AppKeys.selectModuleHint: '設定するモジュールを選択してください',
      AppKeys.moduleMedia: 'メディア',
      AppKeys.moduleKnobs: 'ノブ',
      AppKeys.moduleSliders: 'スライダー',
      AppKeys.moduleTouch: 'タッチ',
      AppKeys.moduleSwitch: 'スイッチ',
      AppKeys.moduleExtendedBtn: '拡張ボタン',
      AppKeys.modulePiano: 'ピアノ',
      AppKeys.moduleModeling: 'モデリング',
      AppKeys.mediaPlayPause: '再生/一時停止',
      AppKeys.mediaNext: '次のトラック',
      AppKeys.mediaPrev: '前のトラック',
      AppKeys.mediaVolUp: '音量アップ',
      AppKeys.mediaVolDown: '音量ダウン',
      AppKeys.visitWebsite: 'ウェブサイトへ',
      AppKeys.visitMakerWorld: 'MakerWorldへ',
      AppKeys.socialNetworks: 'ソーシャルネットワーク',
      AppKeys.reportProblem: '問題を報告',
      AppKeys.reportSubject: 'Console Deck PRO 問題報告',
      AppKeys.reportBodyPrototype: '問題の説明: ',
      AppKeys.uploadSuccess: 'Success! Your 3D file is ready.',
      AppKeys.uploadAuthError: 'App authentication failed.',
      AppKeys.uploadTooLarge: 'File is too large. Maximum 5MB.',
      AppKeys.uploadInvalidSvg: 'Uploaded file is not a valid SVG.',
      AppKeys.uploadTooManyRequests: 'Too many requests. Please wait and try again later!',
      AppKeys.uploadComplexLogo: 'The logo is too complex for 3D rendering.',
      AppKeys.uploadServerError: 'An unexpected server error occurred.',
      AppKeys.fileNotFound: 'File not found',
      AppKeys.fileSavedPrefix: 'File saved:',
      AppKeys.errorPrefix: 'Error:',
      AppKeys.openFolder: 'Open Folder',
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
