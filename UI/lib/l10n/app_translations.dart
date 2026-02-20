import 'package:flutter/material.dart';

class AppKeys {
  static const String home = 'home';
  static const String modules = 'modules';
  static const String skinCreator = 'skin_creator';
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
  static const String modulePiano = 'module.piano';
  static const String moduleModeling = 'module.modeling';
  static const String serialPort = 'settings.serialPort';
  static const String selectPort = 'settings.selectPort';
  static const String noPortsFound = 'settings.noPortsFound';
  static const String portSaved = 'settings.portSaved';
  static const String backendConnectionError =
      'settings.backendConnectionError';
  static const String statusConnected = 'status.connected';
  static const String statusNotConfigured = 'status.notConfigured';
  static const String statusBackendDown = 'status.backendDown';
  static const String configPromptTitle = 'config.promptTitle';
  static const String configPromptBody = 'config.promptBody';
  static const String configPromptButton = 'config.promptButton';
  static const String alertNotConfiguredText = 'alert.notConfigured.text';
  static const String alertNotConfiguredButton = 'alert.notConfigured.button';

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
  static const String clear = 'clear';
}

class AppStrings {
  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      AppKeys.home: 'Home',
      AppKeys.modules: 'Modules',
      AppKeys.skinCreator: 'Skin Creator',
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
      AppKeys.moduleModeling: '3D Modeling',
      AppKeys.serialPort: 'Serial Port',
      AppKeys.selectPort: 'Select a port',
      AppKeys.noPortsFound: 'No ports found',
      AppKeys.portSaved: 'Port saved:',
      AppKeys.backendConnectionError:
          'Error: Could not connect to the backend script. Make sure it is running.',
      AppKeys.statusConnected: 'Connected',
      AppKeys.statusNotConfigured: 'Port not configured',
      AppKeys.statusBackendDown: 'Backend Down',
      AppKeys.configPromptTitle: 'Configuration Required',
      AppKeys.configPromptBody:
          'The serial port is not configured. Please go to settings to select the correct port for your device.',
      AppKeys.configPromptButton: 'Go to Settings',
      AppKeys.alertNotConfiguredText:
          'Serial port not configured. Please select a port to connect to the device.',
      AppKeys.alertNotConfiguredButton: 'Open Settings',
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
      AppKeys.uploadTooManyRequests:
          'Too many requests. Please wait and try again later!',
      AppKeys.uploadComplexLogo: 'The logo is too complex for 3D rendering.',
      AppKeys.uploadServerError: 'An unexpected server error occurred.',
      AppKeys.uploadTimeout: 'Operation timed out. Please try again.',
      AppKeys.fileNotFound: 'File not found',
      AppKeys.fileSavedPrefix: 'File saved:',
      AppKeys.errorPrefix: 'Error:',
      AppKeys.openFolder: 'Open Folder',
      AppKeys.clear: 'Clear',
    },
    'it': {
      AppKeys.home: 'Home',
      AppKeys.modules: 'Moduli',
      AppKeys.skinCreator: 'Creatore Skin',
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
      AppKeys.actionVolume: 'Volume',
      AppKeys.actionBrightness: 'Luminosita',
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
      AppKeys.modulePiano: 'Pianoforte',
      AppKeys.moduleModeling: 'Modellazione 3D',
      AppKeys.serialPort: 'Porta Seriale',
      AppKeys.selectPort: 'Seleziona una porta',
      AppKeys.noPortsFound: 'Nessuna porta trovata',
      AppKeys.portSaved: 'Porta salvata:',
      AppKeys.backendConnectionError:
          'Errore: Impossibile connettersi allo script di backend. Assicurati che sia in esecuzione.',
      AppKeys.statusConnected: 'Connesso',
      AppKeys.statusNotConfigured: 'Porta non configurata',
      AppKeys.statusBackendDown: 'Backend non attivo',
      AppKeys.configPromptTitle: 'Configurazione Richiesta',
      AppKeys.configPromptBody:
          'La porta seriale non è configurata. Vai alle impostazioni per selezionare la porta corretta per il tuo dispositivo.',
      AppKeys.configPromptButton: 'Vai alle Impostazioni',
      AppKeys.alertNotConfiguredText:
          'Porta seriale non configurata. Seleziona un porto per connetterti al dispositivo.',
      AppKeys.alertNotConfiguredButton: 'Apri Impostazioni',
      AppKeys.mediaPlayPause: 'Play/Pausa',
      AppKeys.mediaNext: 'Traccia Successiva',
      AppKeys.mediaPrev: 'Traccia Precedente',
      AppKeys.mediaVolUp: 'Volume +',
      AppKeys.mediaVolDown: 'Volume -',
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
      AppKeys.uploadTooManyRequests:
          "Troppe richieste. Fai una pausa e riprova più tardi!",
      AppKeys.uploadComplexLogo:
          "Il logo è troppo complesso per il rendering 3D.",
      AppKeys.uploadServerError: "C'è stato un problema imprevisto sul server.",
      AppKeys.uploadTimeout: 'Tempo di attesa scaduto. Riprova più tardi.',
      AppKeys.fileNotFound: 'File non trovato',
      AppKeys.fileSavedPrefix: 'File salvato:',
      AppKeys.errorPrefix: 'Errore:',
      AppKeys.openFolder: 'Apri Cartella',
      AppKeys.clear: 'Pulisci',
    },
    'es': {
      AppKeys.home: 'Inicio',
      AppKeys.modules: 'Módulos',
      AppKeys.skinCreator: 'Creador de Skin',
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
      AppKeys.moduleModeling: 'Modelado 3D',
      AppKeys.serialPort: 'Puerto Serie',
      AppKeys.selectPort: 'Seleccione un puerto',
      AppKeys.noPortsFound: 'No se encontraron puertos',
      AppKeys.portSaved: 'Puerto guardado:',
      AppKeys.backendConnectionError:
          'Error: No se pudo conectar con el script del backend. Asegúrese de que se esté ejecutando.',
      AppKeys.statusConnected: 'Conectado',
      AppKeys.statusNotConfigured: 'Puerto no configurado',
      AppKeys.statusBackendDown: 'Backend inactivo',
      AppKeys.configPromptTitle: 'Configuración Requerida',
      AppKeys.configPromptBody:
          'El puerto serie no está configurado. Vaya a la configuración para seleccionar el puerto correcto para su dispositivo.',
      AppKeys.configPromptButton: 'Ir a Configuración',
      AppKeys.alertNotConfiguredText:
          'Puerto serie no configurado. Seleziona un porto per connetterti al dispositivo.',
      AppKeys.alertNotConfiguredButton: 'Abrir Configuración',
      AppKeys.mediaPlayPause: 'Reproducir/Pausar',
      AppKeys.mediaNext: 'Siguiente Pista',
      AppKeys.mediaPrev: 'Pista Anterior',
      AppKeys.mediaVolUp: 'Volume +',
      AppKeys.mediaVolDown: 'Volume -',
      AppKeys.visitWebsite: 'Visitar Sitio Web',
      AppKeys.visitMakerWorld: 'Besuche MakerWorld',
      AppKeys.socialNetworks: 'Redes Sociales',
      AppKeys.reportProblem: 'Reportar Problema',
      AppKeys.reportSubject: 'Reporte de Problema Console Deck PRO',
      AppKeys.reportBodyPrototype: 'Descripción del problema: ',
      // Upload messages (fallback to English)
      AppKeys.uploadSuccess: 'Success! Your 3D file is ready.',
      AppKeys.uploadAuthError: 'App authentication failed.',
      AppKeys.uploadTooLarge: 'File is too large. Maximum 5MB.',
      AppKeys.uploadInvalidSvg: 'Uploaded file is not a valid SVG.',
      AppKeys.uploadTooManyRequests:
          'Too many requests. Please wait and try again later!',
      AppKeys.uploadComplexLogo: 'The logo is too complex for 3D rendering.',
      AppKeys.uploadServerError: 'An unexpected server error occurred.',
      AppKeys.fileNotFound: 'File not found',
      AppKeys.fileSavedPrefix: 'File saved:',
      AppKeys.errorPrefix: 'Error:',
      AppKeys.openFolder: 'Open Folder',
      AppKeys.clear: 'Limpiar',
    },
    'fr': {
      AppKeys.home: 'Accueil',
      AppKeys.modules: 'Modules',
      AppKeys.skinCreator: 'Createur de Skin',
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
      AppKeys.moduleModeling: 'Modélisation 3D',
      AppKeys.serialPort: 'Port Série',
      AppKeys.selectPort: 'Sélectionnez un port',
      AppKeys.noPortsFound: 'Aucun port trouvé',
      AppKeys.portSaved: 'Port enregistré :',
      AppKeys.backendConnectionError:
          'Erreur : Impossible de se connecter au script backend. Assurez-vous qu\'il est en cours d\'exécution.',
      AppKeys.statusConnected: 'Connecté',
      AppKeys.statusNotConfigured: 'Port non configuré',
      AppKeys.statusBackendDown: 'Backend inactif',
      AppKeys.configPromptTitle: 'Configuration Requise',
      AppKeys.configPromptBody:
          'Le port série n\'est pas configuré. Veuillez accéder aux paramètres pour sélectionner le port correct pour votre appareil.',
      AppKeys.configPromptButton: 'Aller aux Paramètres',
      AppKeys.alertNotConfiguredText:
          'Port série non configuré. Veuillez sélectionner un port pour vous connecter à l\'appareil.',
      AppKeys.alertNotConfiguredButton: 'Ouvrir les Paramètres',
      AppKeys.mediaPlayPause: 'Lecture/Pause',
      AppKeys.mediaNext: 'Piste Suivante',
      AppKeys.mediaPrev: 'Piste Précédente',
      AppKeys.mediaVolUp: 'Volume +',
      AppKeys.mediaVolDown: 'Volume -',
      AppKeys.visitWebsite: 'Visiter le Site Web',
      AppKeys.visitMakerWorld: 'Besuche MakerWorld',
      AppKeys.socialNetworks: 'Réseaux Sociaux',
      AppKeys.reportProblem: 'Signaler un Problème',
      AppKeys.reportSubject: 'Problème Console Deck PRO',
      AppKeys.reportBodyPrototype: 'Description du problème: ',
      AppKeys.uploadSuccess: 'Success! Your 3D file is ready.',
      AppKeys.uploadAuthError: 'App authentication failed.',
      AppKeys.uploadTooLarge: 'File is too large. Maximum 5MB.',
      AppKeys.uploadInvalidSvg: 'Uploaded file is not a valid SVG.',
      AppKeys.uploadTooManyRequests:
          'Too many requests. Please wait and try again later!',
      AppKeys.uploadComplexLogo: 'The logo is too complex for 3D rendering.',
      AppKeys.uploadServerError: 'An unexpected server error occurred.',
      AppKeys.fileNotFound: 'File not found',
      AppKeys.fileSavedPrefix: 'File saved:',
      AppKeys.errorPrefix: 'Error:',
      AppKeys.openFolder: 'Open Folder',
      AppKeys.clear: 'Effacer',
    },
    'de': {
      AppKeys.home: 'Startseite',
      AppKeys.modules: 'Module',
      AppKeys.skinCreator: 'Skin-Generator',
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
      AppKeys.moduleModeling: '3D-Modellierung',
      AppKeys.serialPort: 'Serieller Anschluss',
      AppKeys.selectPort: 'Wählen Sie einen Port aus',
      AppKeys.noPortsFound: 'Keine Ports gefunden',
      AppKeys.portSaved: 'Port gespeichert:',
      AppKeys.backendConnectionError:
          'Fehler: Konnte keine Verbindung zum Backend-Skript herstellen. Stellen Sie sicher, dass es läuft.',
      AppKeys.statusConnected: 'Verbunden',
      AppKeys.statusNotConfigured: 'Port nicht konfiguriert',
      AppKeys.statusBackendDown: 'Backend inaktiv',
      AppKeys.configPromptTitle: 'Konfiguration Erforderlich',
      AppKeys.configPromptBody:
          'Der serielle Port ist nicht konfiguriert. Bitte gehen Sie zu den Einstellungen, um den richtigen Port für Ihr Gerät auszuwählen.',
      AppKeys.configPromptButton: 'Zu den Einstellungen',
      AppKeys.alertNotConfiguredText:
          'Serieller Port nicht konfiguriert. Bitte wählen Sie einen Port aus, um eine Verbindung zum Gerät herzustellen.',
      AppKeys.alertNotConfiguredButton: 'Einstellungen öffnen',
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
      AppKeys.uploadTooManyRequests:
          'Too many requests. Please wait and try again later!',
      AppKeys.uploadComplexLogo: 'The logo is too complex for 3D rendering.',
      AppKeys.uploadServerError: 'An unexpected server error occurred.',
      AppKeys.fileNotFound: 'File not found',
      AppKeys.fileSavedPrefix: 'File saved:',
      AppKeys.errorPrefix: 'Error:',
      AppKeys.openFolder: 'Open Folder',
      AppKeys.clear: 'Löschen',
    },
    'zh': {
      AppKeys.home: '首页',
      AppKeys.modules: '模块',
      AppKeys.skinCreator: '皮肤生成器',
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
      AppKeys.moduleModeling: '3D建模',
      AppKeys.serialPort: '串口',
      AppKeys.selectPort: '选择一个端口',
      AppKeys.noPortsFound: '未找到端口',
      AppKeys.portSaved: '端口已保存:',
      AppKeys.backendConnectionError: '错误：无法连接到后端脚本。请确保它正在运行。',
      AppKeys.statusConnected: '已连接',
      AppKeys.statusNotConfigured: '端口未配置',
      AppKeys.statusBackendDown: '后端无响应',
      AppKeys.configPromptTitle: '需要配置',
      AppKeys.configPromptBody: '串行端口未配置。请转到设置以选择您设备的正确端口。',
      AppKeys.configPromptButton: '前往设置',
      AppKeys.alertNotConfiguredText: '串行端口未配置。请选择一个端口以连接到设备。',
      AppKeys.alertNotConfiguredButton: '打开设置',
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
      AppKeys.uploadTooManyRequests:
          'Too many requests. Please wait and try again later!',
      AppKeys.uploadComplexLogo: 'The logo is too complex for 3D rendering.',
      AppKeys.uploadServerError: 'An unexpected server error occurred.',
      AppKeys.fileNotFound: 'File not found',
      AppKeys.fileSavedPrefix: 'File saved:',
      AppKeys.errorPrefix: 'Error:',
      AppKeys.openFolder: 'Open Folder',
      AppKeys.clear: '清除',
    },
    'ja': {
      AppKeys.home: 'ホーム',
      AppKeys.modules: 'モジュール',
      AppKeys.skinCreator: 'スキンクリエーター',
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
      AppKeys.moduleModeling: '3Dモデリング',
      AppKeys.serialPort: 'シリアルポート',
      AppKeys.selectPort: 'ポートを選択',
      AppKeys.noPortsFound: 'ポートが見つかりません',
      AppKeys.portSaved: 'ポートが保存されました:',
      AppKeys.backendConnectionError:
          'エラー：バックエンドスクリプトに接続できませんでした。実行していることを確認してください。',
      AppKeys.statusConnected: '接続済み',
      AppKeys.statusNotConfigured: 'ポートが設定されていません',
      AppKeys.statusBackendDown: 'バックエンドがダウンしています',
      AppKeys.configPromptTitle: '設定が必要です',
      AppKeys.configPromptBody:
          'シリアルポートが設定されていません。設定に移動して、デバイスの正しいポートを選択してください。',
      AppKeys.configPromptButton: '設定に移動',
      AppKeys.alertNotConfiguredText:
          'シリアルポートが設定されていません。デバイスに接続するポートを選択してください。',
      AppKeys.alertNotConfiguredButton: '設定を開く',
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
      AppKeys.uploadTooManyRequests:
          'Too many requests. Please wait and try again later!',
      AppKeys.uploadComplexLogo: 'The logo is too complex for 3D rendering.',
      AppKeys.uploadServerError: 'An unexpected server error occurred.',
      AppKeys.fileNotFound: 'File not found',
      AppKeys.fileSavedPrefix: 'File saved:',
      AppKeys.errorPrefix: 'Error:',
      AppKeys.openFolder: 'Open Folder',
      AppKeys.clear: 'クリア',
    },
  };

  static String get(Locale locale, String key) {
    final localized = _localizedValues[locale.languageCode];
    if (localized != null && localized.containsKey(key)) {
      return localized[key]!;
    }
    // Fallback to English when the selected locale misses a key.
    return _localizedValues['en']![key] ?? key;
  }
}
