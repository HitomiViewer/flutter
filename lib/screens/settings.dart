import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:prompt_dialog/prompt_dialog.dart';
import 'package:provider/provider.dart';
import 'package:settings_ui/settings_ui.dart';

import '../store.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({Key? key}) : super(key: key);

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  bool toggle = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SettingsList(
        // platform: {
        //       TargetPlatform.android: DevicePlatform.android,
        //       TargetPlatform.iOS: DevicePlatform.iOS,
        //       TargetPlatform.windows: DevicePlatform.windows,
        //       TargetPlatform.macOS: DevicePlatform.macOS,
        //       TargetPlatform.linux: DevicePlatform.linux,
        //       TargetPlatform.fuchsia: DevicePlatform.fuchsia,
        //     }[Theme.of(context).platform] ??
        //     DevicePlatform.web,
        sections: [
          SettingsSection(
            title: const Text('Common'),
            tiles: <SettingsTile>[
              SettingsTile.navigation(
                leading: const Icon(Icons.language),
                title: const Text('Language'),
                value: Text(context.watch<Store>().language),
                onPressed: (context) async => context.read<Store>().setLanguage(
                    await prompt(context) ?? context.watch<Store>().language),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
