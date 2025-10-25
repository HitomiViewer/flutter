import 'dart:convert';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hitomiviewer/services/favorite.dart';
import 'package:hitomiviewer/services/image_embedding.dart';
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
  final embeddingService = ImageEmbeddingService();

  @override
  void initState() {
    super.initState();
    // PE-Core 모델은 앱 시작 시 초기화됨
    embeddingService.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    embeddingService.removeListener(() {});
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<Store>();

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
            title: const Text('이미지 분석'),
            tiles: [
              // 모델 정보
              SettingsTile(
                leading: Icon(
                  embeddingService.status == ModelStatus.loaded
                      ? Icons.check_circle
                      : embeddingService.status == ModelStatus.error
                          ? Icons.error
                          : embeddingService.status == ModelStatus.loading
                              ? Icons.hourglass_empty
                              : Icons.download,
                ),
                title: const Text('PE-Core-L14-336'),
                description: Text(_getPECoreStatusText()),
                onPressed: (context) async {
                  // 에러 상태일 때 가이드 표시
                  if (embeddingService.status == ModelStatus.error) {
                    await showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('모델 로드 실패'),
                        content: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                embeddingService.errorMessage ?? '알 수 없는 오류',
                                style: const TextStyle(color: Colors.red),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                '모델 변환 방법:\n\n'
                                '1. 터미널에서 프로젝트 디렉토리로 이동\n\n'
                                '2. tools/README.md 파일을 참고하여 Python 환경 설정\n\n'
                                '3. python tools/convert_pe_core.py 실행\n\n'
                                '4. 변환된 모델이 assets/models/에 저장됨\n\n'
                                '5. 앱을 다시 빌드하세요\n\n'
                                '자세한 내용은 tools/README.md를 확인하세요.',
                                style: TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('확인'),
                          ),
                        ],
                      ),
                    );
                    return;
                  }

                  // 로드된 상태일 때 모델 정보 표시
                  if (embeddingService.status == ModelStatus.loaded) {
                    await showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('모델 정보'),
                        content: const Text(
                          'PE-Core-L14-336\n\n'
                          '• Vision Encoder: 336x336px, 1024-dim\n'
                          '• Text Encoder: 32 tokens, 1024-dim\n'
                          '• 이미지 유사도 검색\n'
                          '• 텍스트 기반 이미지 검색\n\n'
                          'Facebook Research의 최신 CLIP 기반 모델입니다.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('확인'),
                          ),
                        ],
                      ),
                    );
                  }
                },
              ),

              // 분석된 갤러리 수 표시
              if (embeddingService.status == ModelStatus.loaded)
                SettingsTile(
                  leading: const Icon(Icons.photo_library, color: Colors.blue),
                  title: const Text('분석된 갤러리'),
                  description: Text(
                    '${store.galleryEmbeddings.length}개 / ${store.favorite.length}개',
                  ),
                  trailing: Text(
                    '${((store.galleryEmbeddings.length / (store.favorite.isEmpty ? 1 : store.favorite.length)) * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),

              // 추천도 캐시 초기화
              if (embeddingService.status == ModelStatus.loaded)
                SettingsTile(
                  leading: const Icon(Icons.refresh, color: Colors.blue),
                  title: const Text('추천도 캐시 초기화'),
                  description: Text(
                    store.recommendationScores.isEmpty
                        ? '캐시된 추천도 없음'
                        : '캐시된 추천도 ${store.recommendationScores.length}개 삭제',
                  ),
                  onPressed: store.recommendationScores.isEmpty
                      ? null
                      : (context) async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('추천도 캐시 초기화'),
                        content: const Text(
                          '저장된 추천도를 모두 삭제하고 다시 계산합니다.\n'
                          '추천 탭을 다시 방문하면 새로운 기준으로 계산됩니다.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('취소'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('초기화'),
                          ),
                        ],
                      ),
                    );

                    if (confirmed == true) {
                      store.clearRecommendationScores();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('추천도 캐시가 초기화되었습니다')),
                        );
                      }
                    }
                  },
                ),

              // 사용 가능한 기능 안내
              if (embeddingService.status == ModelStatus.loaded &&
                  store.galleryEmbeddings.isNotEmpty)
                SettingsTile(
                  leading: const Icon(Icons.auto_awesome, color: Colors.purple),
                  title: const Text('AI 기능 사용하기'),
                  description: const Text('검색 > AI 검색 / 갤러리 상세 > 유사 이미지 찾기'),
                  onPressed: (context) async {
                    await showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Row(
                          children: const [
                            Icon(Icons.auto_awesome, color: Colors.purple),
                            SizedBox(width: 8),
                            Text('AI 기능 안내'),
                          ],
                        ),
                        content: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFeatureItem(
                                '🔍 텍스트로 이미지 검색',
                                '검색 화면 > AI 검색 탭\n예: "빨간 머리 소녀", "판타지 배경"',
                              ),
                              const Divider(),
                              _buildFeatureItem(
                                '🖼️ 유사 이미지 찾기',
                                '갤러리 상세 화면 > 보라색 버튼\n비슷한 스타일의 이미지를 자동으로 찾습니다',
                              ),
                              const Divider(),
                              _buildFeatureItem(
                                '📊 배치 분석',
                                '설정 > 배치 분석\n모든 즐겨찾기 갤러리를 한 번에 분석합니다',
                              ),
                            ],
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('확인'),
                          ),
                        ],
                      ),
                    );
                  },
                ),

              // 모델 초기화 버튼 (에러 시)
              if (embeddingService.status == ModelStatus.error)
                SettingsTile(
                  leading: const Icon(Icons.refresh),
                  title: const Text('모델 다시 로드'),
                  description: const Text('모델 초기화를 다시 시도합니다'),
                  onPressed: (context) async {
                    final messenger = ScaffoldMessenger.of(context);
                    try {
                      await embeddingService.initialize();
                      if (mounted) {
                        messenger.showSnackBar(
                          const SnackBar(content: Text('모델 로드 성공')),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        messenger.showSnackBar(
                          SnackBar(content: Text('모델 로드 실패: $e')),
                        );
                      }
                    }
                  },
                ),

              // 분석 상태
              SettingsTile(
                leading: const Icon(Icons.analytics),
                title: const Text('분석 완료'),
                description: Text(
                    '${context.watch<Store>().analyzedFavoriteCount}/${context.watch<Store>().favorite.length} 이미지'),
                onPressed: null,
              ),

              // 좋아요 갤러리 분석
              SettingsTile.navigation(
                leading: const Icon(Icons.play_arrow),
                title: const Text('좋아요 갤러리 분석'),
                description: const Text('탭하여 배치 분석 시작'),
                onPressed: (context) {
                  context.router.pushNamed('/batch-analysis');
                },
              ),

              // 분석 데이터 삭제
              SettingsTile(
                leading: const Icon(Icons.delete),
                title: const Text('분석 데이터 삭제'),
                description: const Text('모든 임베딩 데이터 삭제'),
                onPressed: (context) async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('데이터 삭제'),
                      content: const Text('모든 분석 데이터를 삭제하시겠습니까?'),
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
                    await context.read<Store>().clearEmbeddings();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('분석 데이터가 삭제되었습니다')),
                      );
                    }
                  }
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

  Widget _buildFeatureItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  String _getPECoreStatusText() {
    switch (embeddingService.status) {
      case ModelStatus.notLoaded:
        return '모델 파일 없음 - 변환 필요';
      case ModelStatus.loading:
        return '로딩 중...';
      case ModelStatus.loaded:
        return '준비됨 (Vision + Text) - 탭하여 정보 보기';
      case ModelStatus.error:
        return '로드 실패 - 탭하여 자세히 보기';
    }
  }
}
