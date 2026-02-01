import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../locale_state.dart';
import '../l10n/app_translations.dart';

class SkinCreatorPage extends StatefulWidget {
  const SkinCreatorPage({super.key});

  @override
  State<SkinCreatorPage> createState() => _SkinCreatorPageState();
}

class _SkinCreatorPageState extends State<SkinCreatorPage> {
  String? _selectedFilePath;

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
                                color: Theme.of(context).colorScheme.primary),
                            const SizedBox(height: 8),
                            Text("SVG",
                                style: Theme.of(context).textTheme.bodyLarge),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32.0),
                          child: Icon(Icons.arrow_forward_rounded,
                              size: 40,
                              color: Theme.of(context).colorScheme.onSurfaceVariant),
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
                            onPressed: () {
                              // Logic for generating skin
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 32, vertical: 20),
                              textStyle: const TextStyle(fontSize: 20),
                            ),
                            child: Text(AppStrings.get(currentLocale, AppKeys.generate)),
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