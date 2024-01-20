import 'dart:convert';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hitomiviewer/services/favorite.dart';
import 'package:hitomiviewer/app_router.gr.dart';
import 'package:prompt_dialog/prompt_dialog.dart';
import 'package:provider/provider.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:share_plus/share_plus.dart';

import '../../services/auth.dart';
import '../../store.dart';

@RoutePage()
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
              SettingsTile.navigation(
                leading: const Icon(Icons.block),
                title: const Text('Blacklist'),
                onPressed: (context) =>
                    context.router.pushNamed('/settings/blacklist'),
              ),
            ],
          ),
          SettingsSection(
            title: const Text('Favorite'),
            tiles: <SettingsTile>[
              SettingsTile.navigation(
                leading: const Icon(Icons.import_export),
                title: const Text('Import'),
                onPressed: (context) async {
                  final String? result = await prompt(context);
                  if (result != null) {
                    List<int> favorite = json.decode(result).cast<int>();
                    Provider.of<Store>(context, listen: false)
                        .setFavorite(favorite);
                  }
                },
              ),
              SettingsTile.navigation(
                leading: const Icon(Icons.import_export),
                title: const Text('Export'),
                onPressed: (context) async {
                  final String result = json.encode(
                      Provider.of<Store>(context, listen: false).favorite);
                  Clipboard.setData(ClipboardData(text: result));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Copied to clipboard'),
                    ),
                  );
                },
              ),
              ...context.read<Store>().refreshToken == ''
                  ? []
                  : [
                      SettingsTile.navigation(
                        leading: const Icon(Icons.upload),
                        title: const Text('Upload'),
                        onPressed: (context) async {
                          final store = context.read<Store>();
                          String accessToken =
                              await refresh(store.refreshToken);
                          store.setAccessToken(accessToken);

                          await setFavorites(accessToken, store.favorite);
                        },
                      ),
                      SettingsTile.navigation(
                        leading: const Icon(Icons.download),
                        title: const Text('Download'),
                        onPressed: (context) async {
                          final store = context.read<Store>();
                          String accessToken =
                              await refresh(store.refreshToken);
                          store.setAccessToken(accessToken);

                          store.setFavorite(await getFavorites(accessToken));
                        },
                      ),
                    ],
              SettingsTile(
                leading: const Icon(Icons.share),
                title: const Text('Share'),
                onPressed: (context) async {
                  final String result = json.encode(
                      Provider.of<Store>(context, listen: false).favorite);
                  await Share.share(result);
                },
              ),
            ],
          ),
          SettingsSection(
            title: const Text('Statistics'),
            tiles: [
              SettingsTile(
                leading: const Icon(Icons.view_array),
                title: const Text('Recent Viewed'),
                description:
                    Text('${context.read<Store>().recent.length} items'),
                onPressed: (context) => context.router
                    .push(IdRoute(ids: context.read<Store>().recent)),
              ),
            ],
          ),
          SettingsSection(
            title: const Text('Account'),
            tiles: <SettingsTile>[
              context.read<Store>().refreshToken == ''
                  ? SettingsTile(
                      leading: const Icon(Icons.login),
                      title: const Text('Login'),
                      onPressed: (context) =>
                          context.router.pushNamed('/auth/login'),
                    )
                  : SettingsTile(
                      leading: const Icon(Icons.logout),
                      title: const Text('Logout'),
                      onPressed: (context) async {
                        context.read<Store>().setRefreshToken('');
                      },
                    ),
              ...context.read<Store>().refreshToken == ''
                  ? []
                  : [
                      SettingsTile(
                        leading: const Icon(Icons.account_circle),
                        title: const Text('Info'),
                        onPressed: (context) =>
                            context.router.pushNamed('/auth/info'),
                      )
                    ],
            ],
          )
          // SettingsSection(
          //   title: const Text('Viewer'),
          //   tiles: <SettingsTile>[
          //     SettingsTile.switchTile(
          //       leading: const Icon(Icons.brightness_4),
          //       title: const Text('Dark mode'),
          //       switchValue: context.watch<Store>().darkMode,
          //       onToggle: (bool value) =>
          //           context.read<Store>().setDarkMode(value),
          //     ),
          //     SettingsTile.switchTile(
          //       leading: const Icon(Icons.fullscreen),
          //       title: const Text('Fullscreen'),
          //       switchValue: context.watch<Store>().fullscreen,
          //       onToggle: (bool value) =>
          //           context.read<Store>().setFullscreen(value),
          //     ),
          //     SettingsTile.switchTile(
          //       leading: const Icon(Icons.auto_awesome),
          //       title: const Text('Auto hide'),
          //       switchValue: context.watch<Store>().autoHide,
          //       onToggle: (bool value) =>
          //           context.read<Store>().setAutoHide(value),
          //     ),
          //     SettingsTile.switchTile(
          //       leading: const Icon(Icons.auto_awesome),
          //       title: const Text('Auto hide'),
          //       switchValue: context.watch<Store>().autoHide,
          //       onToggle: (bool value) =>
          //           context.read<Store>().setAutoHide(value),
          //     ),
          //     SettingsTile.switchTile(
          //       leading: const Icon(Icons.auto_awesome),
          //       title: const Text('Auto hide'),
          //       switchValue: context.watch<Store>().autoHide,
          //       onToggle: (bool value) =>
          //           context.read<Store>().setAutoHide(value),
          //     ),
          //     SettingsTile.switchTile(
          //       leading: const Icon(Icons.auto_awesome),
          //       title: const Text('Auto hide'),
          //       switchValue: context.watch<Store>().autoHide,
          //       onToggle: (bool value) =>
          //           context.read<Store>().setAutoHide(value),
          //     ),
          //     SettingsTile.switchTile(
          //       leading: const Icon(Icons.auto_awesome),
          //       title: const Text('Auto hide'),
          //       switchValue: context.watch<Store>().autoHide,
          //       onToggle: (bool value) =>
          //           context.read<Store>().setAutoHide(value),
          //     ),
          //   ],
          // ),
        ],
      ),
    );
  }
}
