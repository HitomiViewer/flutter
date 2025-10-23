import 'dart:convert';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hitomiviewer/services/favorite.dart';
import 'package:hitomiviewer/services/gemma.dart';
import 'package:hitomiviewer/app_router.gr.dart';
import 'package:package_info_plus/package_info_plus.dart';
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
  final gemmaService = GemmaService();

  @override
  void initState() {
    super.initState();
    // 모델 상태 확인
    gemmaService.checkModelStatus();
    gemmaService.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    gemmaService.removeListener(() {});
    super.dispose();
  }

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

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Imported'),
                      ),
                    );
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

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Uploaded'),
                            ),
                          );
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

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Downloaded'),
                            ),
                          );
                        },
                      ),
                      SettingsTile.navigation(
                        leading: const Icon(Icons.merge_type),
                        title: const Text('Merge'),
                        onPressed: (context) async {
                          final store = context.read<Store>();
                          String accessToken =
                              await refresh(store.refreshToken);
                          store.setAccessToken(accessToken);

                          int before = store.favorite.length;
                          store.mergeFavorite(await getFavorites(accessToken));
                          int after = store.favorite.length;

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Merged $before -> $after'),
                            ),
                          );
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
            title: const Text('AI 모델'),
            tiles: [
              SettingsTile(
                leading: Icon(
                  gemmaService.status == ModelStatus.installed
                      ? Icons.check_circle
                      : Icons.cloud_download,
                ),
                title: const Text('Gemma 3 Nano 4B'),
                description: Text(_getModelStatusText()),
                onPressed: (context) async {
                  if (gemmaService.status == ModelStatus.downloading) {
                    // 다운로드 중이면 무시
                    return;
                  }
                  
                  if (gemmaService.status == ModelStatus.installed) {
                    // 이미 설치됨 - 삭제 확인
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('모델 삭제'),
                        content: const Text('설치된 모델을 삭제하시겠습니까?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('취소'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('삭제'),
                          ),
                        ],
                      ),
                    );
                    
                    if (confirm == true) {
                      try {
                        await gemmaService.deleteModel();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('모델이 삭제되었습니다')),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('삭제 실패: $e')),
                          );
                        }
                      }
                    }
                  } else {
                    // 다운로드 시작
                    try {
                      await gemmaService.downloadModel(
                        onProgress: (progress) {
                          // 진행률은 gemmaService에서 자동으로 notifyListeners 호출
                        },
                      );
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('모델 다운로드 완료')),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('다운로드 실패: $e')),
                        );
                      }
                    }
                  }
                },
              ),
              SettingsTile.navigation(
                leading: const Icon(Icons.high_quality),
                title: const Text('기본 분석 품질'),
                value: Text(context.watch<Store>().imageQuality ==
                        ImageQuality.thumbnail
                    ? '썸네일 (권장)'
                    : '원본 (고품질)'),
                onPressed: (context) async {
                  final quality = await showDialog<ImageQuality>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('분석 품질 선택'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          RadioListTile<ImageQuality>(
                            title: const Text('썸네일 (권장)'),
                            subtitle:
                                const Text('~300KB, 빠른 처리 (3-5초/이미지)'),
                            value: ImageQuality.thumbnail,
                            groupValue: context.read<Store>().imageQuality,
                            onChanged: (value) => Navigator.pop(context, value),
                          ),
                          RadioListTile<ImageQuality>(
                            title: const Text('원본 (고품질)'),
                            subtitle: const Text(
                                '수MB, 상세 분석 (10-30초/이미지)\n데이터 사용량 증가'),
                            value: ImageQuality.original,
                            groupValue: context.read<Store>().imageQuality,
                            onChanged: (value) => Navigator.pop(context, value),
                          ),
                        ],
                      ),
                    ),
                  );
                  
                  if (quality != null) {
                    await context.read<Store>().setDefaultImageQuality(quality);
                  }
                },
              ),
              SettingsTile.navigation(
                leading: const Icon(Icons.analytics),
                title: const Text('좋아요 갤러리 분석'),
                description: Text(
                    '${context.watch<Store>().analyzedFavoriteCount}/${context.watch<Store>().favorite.length} 분석 완료'),
                onPressed: (context) {
                  context.router.pushNamed('/batch-analysis');
                },
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
          ),
          SettingsSection(
            title: const Text('App Info'),
            tiles: <SettingsTile>[
              SettingsTile(
                leading: const Icon(Icons.info),
                title: const Text('Name'),
                value: FutureBuilder<PackageInfo>(
                  future: PackageInfo.fromPlatform(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return Text(snapshot.data!.appName);
                    } else if (snapshot.hasError) {
                      return Text('${snapshot.error}');
                    }
                    return const CircularProgressIndicator();
                  },
                ),
              ),
              SettingsTile(
                leading: const Icon(Icons.info),
                title: const Text('Version'),
                value: FutureBuilder<PackageInfo>(
                  future: PackageInfo.fromPlatform(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return Text(snapshot.data!.version);
                    } else if (snapshot.hasError) {
                      return Text('${snapshot.error}');
                    }
                    return const CircularProgressIndicator();
                  },
                ),
              ),
            ],
          ),
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

  String _getModelStatusText() {
    switch (gemmaService.status) {
      case ModelStatus.notInstalled:
        return '미설치 - 탭하여 다운로드';
      case ModelStatus.downloading:
        return '다운로드 중 (${(gemmaService.downloadProgress * 100).toStringAsFixed(0)}%)';
      case ModelStatus.installed:
        return '설치됨 (~3.2GB) - 탭하여 삭제';
      case ModelStatus.error:
        return '오류: ${gemmaService.errorMessage ?? "알 수 없음"}';
    }
  }
}
