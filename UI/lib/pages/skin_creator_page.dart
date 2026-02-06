import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../locale_state.dart';
import '../l10n/app_translations.dart';

class SkinCreatorPage extends StatefulWidget {
  const SkinCreatorPage({super.key});

  @override
  State<SkinCreatorPage> createState() => _SkinCreatorPageState();
}

class _SkinCreatorPageState extends State<SkinCreatorPage> {
  String? _selectedFilePath;
  bool _isUploading = false;
  static const String _apiUrl = 'https://genera-tile-389081992785.us-central1.run.app';
  static const String _apiKey = 'CD_PRO_WIN_SECRET_2026_T9';

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['svg'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFilePath = result.files.single.path;
      });
    }
  }

  Future<void> _uploadSvgAndSave(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      final msg = AppStrings.get(localeNotifier.value, AppKeys.fileNotFound);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      return;
    }

    try {
      final uri = Uri.parse(_apiUrl);
      final request = http.MultipartRequest('POST', uri);
      request.headers['x-api-key'] = _apiKey;
      request.files.add(await http.MultipartFile.fromPath('svg_file', filePath, filename: file.uri.pathSegments.last));

      final streamedResp = await request.send().timeout(const Duration(seconds: 30));
      final resp = await http.Response.fromStream(streamedResp);

      if (resp.statusCode == 200) {
        // Determine filename
        String filename = 'tile_output.bin';
        final contentDisp = resp.headers['content-disposition'];
        if (contentDisp != null) {
          final match = RegExp(r'filename="?([^";]+)"?').firstMatch(contentDisp);
          if (match != null) filename = match.group(1)!;
        }

        // Choose Downloads directory
        Directory? downloadsDir;
        try {
          downloadsDir = await getDownloadsDirectory();
        } catch (_) {
          downloadsDir = null;
        }
        Directory saveDir = downloadsDir ?? await getApplicationDocumentsDirectory();

        final outFile = File('${saveDir.path}${Platform.pathSeparator}$filename');
        await outFile.writeAsBytes(resp.bodyBytes);

        final prefix = AppStrings.get(localeNotifier.value, AppKeys.fileSavedPrefix);
        final openLabel = AppStrings.get(localeNotifier.value, AppKeys.openFolder);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('$prefix ${outFile.path}'),
          action: SnackBarAction(
            label: openLabel,
            onPressed: () => _openFolder(saveDir.path),
          ),
        ));
        // Reset the page to default state for next upload
        setState(() {
          _selectedFilePath = null;
        });
      } else {
        String msg = _messageForStatus(resp.statusCode);
        try {
          if (resp.body.isNotEmpty) msg = resp.body;
        } catch (_) {}
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } on TimeoutException {
      final timeoutMsg = AppStrings.get(localeNotifier.value, AppKeys.uploadTimeout);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(timeoutMsg)));
    } catch (e) {
      final prefix = AppStrings.get(localeNotifier.value, AppKeys.errorPrefix);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$prefix $e')));
    }
  }

  Future<void> _openFolder(String folderPath) async {
    final folderUri = Uri.file(folderPath);
    try {
      if (await canLaunchUrl(folderUri)) {
        await launchUrl(folderUri);
      }
    } catch (e) {
      if (mounted) {
        final prefix = AppStrings.get(localeNotifier.value, AppKeys.errorPrefix);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$prefix $e')));
      }
    }
  }

  String _messageForStatus(int statusCode) {
    switch (statusCode) {
      case 200:
        return AppStrings.get(localeNotifier.value, AppKeys.uploadSuccess);
      case 403:
        return AppStrings.get(localeNotifier.value, AppKeys.uploadAuthError);
      case 413:
        return AppStrings.get(localeNotifier.value, AppKeys.uploadTooLarge);
      case 422:
        return AppStrings.get(localeNotifier.value, AppKeys.uploadInvalidSvg);
      case 429:
        return AppStrings.get(localeNotifier.value, AppKeys.uploadTooManyRequests);
      case 504:
        return AppStrings.get(localeNotifier.value, AppKeys.uploadComplexLogo);
      default:
        return AppStrings.get(localeNotifier.value, AppKeys.uploadServerError);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: localeNotifier,
      builder: (context, currentLocale, child) {
        return Scaffold(
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Column(
                          children: [
                            Icon(Icons.description,
                                size: 64,
                                color: Theme.of(context).colorScheme.secondary),
                            const SizedBox(height: 8),
                            Text("SVG",
                                style: Theme.of(context).textTheme.bodyLarge),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32.0),
                          child: Icon(Icons.arrow_forward_rounded,
                              size: 40,
                              color: Theme.of(context).colorScheme.secondary),
                        ),
                        Column(
                          children: [
                            Icon(Icons.view_in_ar_rounded,
                                size: 64,
                                color: Theme.of(context).colorScheme.secondary),
                            const SizedBox(height: 8),
                            Text("3D Skin",
                                style: Theme.of(context).textTheme.bodyLarge),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 50),
                    if (_selectedFilePath == null)
                      ElevatedButton.icon(
                        onPressed: _pickFile,
                        icon: const Icon(Icons.folder_open),
                        label: Text(AppStrings.get(currentLocale, AppKeys.browse)),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          textStyle: const TextStyle(fontSize: 18),
                        ),
                      )
                    else ...[
                      Text(
                        "File:",
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          _selectedFilePath!,
                          style: Theme.of(context).textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              border: Border.all(color: Theme.of(context).dividerColor),
                              borderRadius: BorderRadius.circular(12),
                              color: Theme.of(context).cardColor,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: SvgPicture.file(
                                File(_selectedFilePath!),
                                colorFilter: ColorFilter.mode(
                                  Theme.of(context).brightness == Brightness.dark
                                      ? Colors.white
                                      : Colors.black,
                                  BlendMode.srcIn,
                                ),
                                placeholderBuilder: (context) => const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: _isUploading ? null : () async {
                              if (_selectedFilePath == null) return;
                              setState(() { _isUploading = true; });
                              try {
                                await _uploadSvgAndSave(_selectedFilePath!);
                              } finally {
                                setState(() { _isUploading = false; });
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 32, vertical: 20),
                              textStyle: const TextStyle(fontSize: 20),
                            ),
                            child: _isUploading
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.onPrimary),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(AppStrings.get(currentLocale, AppKeys.generate)),
                                    ],
                                  )
                                : Text(AppStrings.get(currentLocale, AppKeys.generate)),
                          ),
                          const SizedBox(width: 20),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _selectedFilePath = null;
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.error,
                              foregroundColor: Theme.of(context).colorScheme.onError,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 32, vertical: 20),
                              textStyle: const TextStyle(fontSize: 20),
                            ),
                            child: Text(AppStrings.get(currentLocale, AppKeys.cancel)),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}