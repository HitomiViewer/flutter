import 'dart:convert';
import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:hitomiviewer/services/favorite.dart';
import 'package:hitomiviewer/services/image_embedding.dart';
import 'package:hitomiviewer/services/api_cache.dart';
import 'package:hitomiviewer/app_router.gr.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
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
  int _imageCacheCount = 0;
  int _imageCacheSize = 0;

  @override
  void initState() {
    super.initState();
    // PE-Core 모델은 앱 시작 시 초기화됨
    embeddingService.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
    _loadImageCacheInfo();
  }

  @override
  void dispose() {
    embeddingService.removeListener(() {});
    super.dispose();
  }

  Future<void> _loadImageCacheInfo() async {
    try {
      // 임시 디렉토리에서 flutter_cache_manager 캐시 찾기
      final tempDir = await getTemporaryDirectory();
      final cacheDir = Directory('${tempDir.path}/libCachedImageData');
      
      int count = 0;
      int totalSize = 0;
      
      if (await cacheDir.exists()) {
        final files = cacheDir.listSync(recursive: true);
        
        for (final file in files) {
          if (file is File) {
            count++;
            final fileSize = await file.length();
            totalSize += fileSize;
          }
        }
      }
      
      if (mounted) {
        setState(() {
          _imageCacheCount = count;
          _imageCacheSize = totalSize;
        });
      }
    } catch (e) {
      debugPrint('이미지 캐시 정보 로드 실패: $e');
    }
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
            title: const Text('API 캐시'),
            tiles: [
              // 캐시 통계
              SettingsTile(
                leading: const Icon(Icons.storage, color: Colors.green),
                title: const Text('캐시 통계'),
                description: _buildCacheStats(),
                onPressed: null,
              ),
              
              // 캐시 목록 보기
              SettingsTile.navigation(
                leading: const Icon(Icons.list, color: Colors.purple),
                title: const Text('캐시 목록 보기'),
                description: const Text('저장된 캐시 파일 상세 정보'),
                onPressed: (context) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CacheListScreen(),
                    ),
                  );
                },
              ),
              
              // 만료된 캐시 정리
              SettingsTile(
                leading: const Icon(Icons.cleaning_services, color: Colors.blue),
                title: const Text('만료된 캐시 정리'),
                description: const Text('유효 기간이 지난 캐시만 삭제'),
                onPressed: (context) async {
                  final messenger = ScaffoldMessenger.of(context);
                  try {
                    await ApiCacheService().cleanExpired();
                    if (mounted) {
                      setState(() {}); // 통계 업데이트
                      messenger.showSnackBar(
                        const SnackBar(content: Text('만료된 캐시가 정리되었습니다')),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      messenger.showSnackBar(
                        SnackBar(content: Text('캐시 정리 실패: $e')),
                      );
                    }
                  }
                },
              ),
              
              // 전체 캐시 삭제
              SettingsTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text('전체 캐시 삭제'),
                description: const Text('모든 API 캐시를 삭제합니다'),
                onPressed: (context) async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('캐시 삭제'),
                      content: const Text(
                        '모든 API 캐시를 삭제하시겠습니까?\n\n'
                        '다음 API 요청 시 다시 데이터를 받아옵니다.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('취소'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('삭제', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    final messenger = ScaffoldMessenger.of(context);
                    try {
                      await ApiCacheService().clearAll();
                      if (mounted) {
                        setState(() {}); // 통계 업데이트
                        messenger.showSnackBar(
                          const SnackBar(content: Text('전체 캐시가 삭제되었습니다')),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        messenger.showSnackBar(
                          SnackBar(content: Text('캐시 삭제 실패: $e')),
                        );
                      }
                    }
                  }
                },
              ),
            ],
          ),
          SettingsSection(
            title: const Text('이미지 캐시'),
            tiles: [
              // 이미지 캐시 통계
              SettingsTile(
                leading: const Icon(Icons.image, color: Colors.blue),
                title: const Text('이미지 캐시 통계'),
                description: Text(
                  '${_imageCacheCount}개 파일 | ${_formatBytes(_imageCacheSize)}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                onPressed: null,
              ),
              
              // 이미지 캐시 목록 보기
              SettingsTile.navigation(
                leading: const Icon(Icons.photo_library, color: Colors.purple),
                title: const Text('이미지 캐시 목록 보기'),
                description: const Text('저장된 이미지 파일 상세 정보'),
                onPressed: (context) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ImageCacheListScreen(),
                    ),
                  );
                },
              ),
              
              // 이미지 캐시 새로고침
              SettingsTile(
                leading: const Icon(Icons.refresh, color: Colors.green),
                title: const Text('캐시 정보 새로고침'),
                description: const Text('캐시 통계 업데이트'),
                onPressed: (context) async {
                  await _loadImageCacheInfo();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('캐시 정보가 업데이트되었습니다')),
                    );
                  }
                },
              ),
              
              // 이미지 캐시 전체 삭제
              SettingsTile(
                leading: const Icon(Icons.delete_sweep, color: Colors.red),
                title: const Text('이미지 캐시 삭제'),
                description: const Text('모든 이미지 캐시를 삭제합니다'),
                onPressed: (context) async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('이미지 캐시 삭제'),
                      content: Text(
                        '모든 이미지 캐시를 삭제하시겠습니까?\n\n'
                        '${_imageCacheCount}개 파일 (${_formatBytes(_imageCacheSize)})\n\n'
                        '다음 이미지 로드 시 다시 다운로드됩니다.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('취소'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('삭제', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    final messenger = ScaffoldMessenger.of(context);
                    try {
                      await DefaultCacheManager().emptyCache();
                      await CachedNetworkImage.evictFromCache(
                        '', // 빈 URL로 호출하면 전체 캐시가 제거됨
                      );
                      await _loadImageCacheInfo();
                      
                      if (mounted) {
                        messenger.showSnackBar(
                          const SnackBar(content: Text('이미지 캐시가 삭제되었습니다')),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        messenger.showSnackBar(
                          SnackBar(content: Text('이미지 캐시 삭제 실패: $e')),
                        );
                      }
                    }
                  }
                },
              ),
            ],
          ),
          SettingsSection(
            title: const Text('이미지 분석'),
            tiles: [
              // 자동 로딩 설정
              SettingsTile.switchTile(
                leading: const Icon(Icons.power_settings_new),
                title: const Text('앱 시작 시 모델 자동 로드'),
                description: const Text('활성화하면 앱 시작 시 PE-Core 모델을 자동으로 로드합니다'),
                initialValue: store.autoLoadModel,
                onToggle: (value) {
                  store.setAutoLoadModel(value);
                },
              ),

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

              // 수동 로드 버튼 (notLoaded 또는 에러 시)
              if (embeddingService.status == ModelStatus.error || 
                  embeddingService.status == ModelStatus.notLoaded)
                SettingsTile(
                  leading: const Icon(Icons.refresh),
                  title: Text(
                    embeddingService.status == ModelStatus.notLoaded
                        ? '모델 로드'
                        : '모델 다시 로드'
                  ),
                  description: Text(
                    embeddingService.status == ModelStatus.notLoaded
                        ? '탭하여 PE-Core 모델을 로드합니다'
                        : '모델 초기화를 다시 시도합니다'
                  ),
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

  Widget _buildCacheStats() {
    final stats = ApiCacheService().getStats();
    
    if (stats.containsKey('error')) {
      return Text('캐시 초기화 안됨', style: TextStyle(color: Colors.grey[600]));
    }
    
    final total = stats['total'] ?? 0;
    final valid = stats['valid'] ?? 0;
    final expired = stats['expired'] ?? 0;
    
    return Text(
      '전체: $total개 | 유효: $valid개 | 만료: $expired개',
      style: TextStyle(color: Colors.grey[600]),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
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

/// 캐시 목록 화면
class CacheListScreen extends StatefulWidget {
  const CacheListScreen({Key? key}) : super(key: key);

  @override
  State<CacheListScreen> createState() => _CacheListScreenState();
}

class _CacheListScreenState extends State<CacheListScreen> {
  List<CacheItemInfo> _cacheItems = [];
  String _filterType = '전체';

  @override
  void initState() {
    super.initState();
    _loadCacheItems();
  }

  void _loadCacheItems() {
    setState(() {
      _cacheItems = ApiCacheService().getAllCacheItems();
    });
  }

  List<CacheItemInfo> get _filteredItems {
    if (_filterType == '전체') return _cacheItems;
    return _cacheItems.where((item) => item.keyType == _filterType).toList();
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}시간 ${duration.inMinutes.remainder(60)}분';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}분';
    } else {
      return '${duration.inSeconds}초';
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final filterTypes = ['전체', '갤러리 상세', '포스트 목록', '검색 결과', '자동완성'];
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('캐시 목록'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCacheItems,
            tooltip: '새로고침',
          ),
        ],
      ),
      body: Column(
        children: [
          // 필터 칩
          Container(
            padding: const EdgeInsets.all(8.0),
            child: Wrap(
              spacing: 8.0,
              children: filterTypes.map((type) {
                final isSelected = _filterType == type;
                return FilterChip(
                  label: Text(type),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _filterType = type;
                    });
                  },
                );
              }).toList(),
            ),
          ),
          
          // 통계 요약
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('전체', _cacheItems.length.toString()),
                _buildStatItem('유효', _cacheItems.where((item) => !item.isExpired).length.toString(), Colors.green),
                _buildStatItem('만료', _cacheItems.where((item) => item.isExpired).length.toString(), Colors.red),
              ],
            ),
          ),
          
          const Divider(height: 1),
          
          // 캐시 목록
          Expanded(
            child: _filteredItems.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '캐시가 없습니다',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = _filteredItems[index];
                      return _buildCacheItemCard(item);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, [Color? color]) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildCacheItemCard(CacheItemInfo item) {
    final isExpired = item.isExpired;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: ExpansionTile(
        leading: Icon(
          isExpired ? Icons.warning : Icons.check_circle,
          color: isExpired ? Colors.red : Colors.green,
        ),
        title: Text(
          item.keyType,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              item.keyValue,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
            ),
            const SizedBox(height: 4),
            Text(
              isExpired ? '만료됨' : '남은 시간: ${_formatDuration(item.remainingTime)}',
              style: TextStyle(
                fontSize: 11,
                color: isExpired ? Colors.red : Colors.green,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, size: 20),
          onPressed: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('캐시 삭제'),
                content: Text('이 캐시 항목을 삭제하시겠습니까?\n\n${item.keyValue}'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('취소'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('삭제', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            );

            if (confirm == true) {
              await ApiCacheService().delete(item.key);
              _loadCacheItems();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('캐시가 삭제되었습니다')),
                );
              }
            }
          },
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('키', item.key),
                const SizedBox(height: 8),
                _buildDetailRow('캐시된 시간', _formatDateTime(item.cachedAt)),
                const SizedBox(height: 8),
                _buildDetailRow('TTL', _formatDuration(item.ttl)),
                const SizedBox(height: 8),
                _buildDetailRow('데이터 크기', _formatBytes(item.dataSize)),
                const SizedBox(height: 8),
                _buildDetailRow(
                  '상태',
                  isExpired ? '만료됨' : '유효',
                  valueColor: isExpired ? Colors.red : Colors.green,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(color: valueColor),
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inDays > 0) {
      return '${diff.inDays}일 전';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}시간 전';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}분 전';
    } else {
      return '방금 전';
    }
  }
}

/// 이미지 캐시 항목 정보
class ImageCacheItemInfo {
  final String fileName;
  final String filePath;
  final int fileSize;
  final DateTime modifiedTime;

  ImageCacheItemInfo({
    required this.fileName,
    required this.filePath,
    required this.fileSize,
    required this.modifiedTime,
  });
}

/// 이미지 캐시 목록 화면
class ImageCacheListScreen extends StatefulWidget {
  const ImageCacheListScreen({Key? key}) : super(key: key);

  @override
  State<ImageCacheListScreen> createState() => _ImageCacheListScreenState();
}

class _ImageCacheListScreenState extends State<ImageCacheListScreen> {
  List<ImageCacheItemInfo> _cacheItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCacheItems();
  }

  Future<void> _loadCacheItems() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final tempDir = await getTemporaryDirectory();
      final cacheDir = Directory('${tempDir.path}/libCachedImageData');
      
      final items = <ImageCacheItemInfo>[];
      
      if (await cacheDir.exists()) {
        final files = cacheDir.listSync(recursive: true);
        
        for (final file in files) {
          if (file is File) {
            final stat = await file.stat();
            items.add(ImageCacheItemInfo(
              fileName: file.path.split(Platform.pathSeparator).last,
              filePath: file.path,
              fileSize: await file.length(),
              modifiedTime: stat.modified,
            ));
          }
        }
      }
      
      // 최신순으로 정렬
      items.sort((a, b) => b.modifiedTime.compareTo(a.modifiedTime));
      
      if (mounted) {
        setState(() {
          _cacheItems = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('이미지 캐시 목록 로드 실패: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inDays > 0) {
      return '${diff.inDays}일 전';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}시간 전';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}분 전';
    } else {
      return '방금 전';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('이미지 캐시 목록'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCacheItems,
            tooltip: '새로고침',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 통계 요약
                Container(
                  padding: const EdgeInsets.all(16.0),
                  color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem('전체', _cacheItems.length.toString()),
                      _buildStatItem(
                        '총 크기',
                        _formatBytes(_cacheItems.fold<int>(
                          0,
                          (sum, item) => sum + item.fileSize,
                        )),
                        Colors.blue,
                      ),
                    ],
                  ),
                ),
                
                const Divider(height: 1),
                
                // 캐시 목록
                Expanded(
                  child: _cacheItems.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.image_not_supported,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                '캐시된 이미지가 없습니다',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _cacheItems.length,
                          itemBuilder: (context, index) {
                            final item = _cacheItems[index];
                            return _buildCacheItemCard(item);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatItem(String label, String value, [Color? color]) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildCacheItemCard(ImageCacheItemInfo item) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 56,
            height: 56,
            color: Colors.grey[200],
            child: Image.file(
              File(item.filePath),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.blue.withOpacity(0.2),
                  child: const Icon(Icons.image, color: Colors.blue),
                );
              },
            ),
          ),
        ),
        title: Text(
          item.fileName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '크기: ${_formatBytes(item.fileSize)}',
              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
            ),
            Text(
              '수정: ${_formatDateTime(item.modifiedTime)}',
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.visibility, size: 20),
              tooltip: '미리보기',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => Dialog(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppBar(
                          title: const Text('이미지 미리보기'),
                          leading: IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                        Flexible(
                          child: InteractiveViewer(
                            child: Image.file(
                              File(item.filePath),
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  padding: const EdgeInsets.all(32),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.error, size: 48, color: Colors.red[300]),
                                      const SizedBox(height: 16),
                                      const Text('이미지를 불러올 수 없습니다'),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete, size: 20),
              tooltip: '삭제',
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('이미지 캐시 삭제'),
                    content: Text('이 이미지를 삭제하시겠습니까?\n\n${item.fileName}'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('취소'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('삭제', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  try {
                    await File(item.filePath).delete();
                    await _loadCacheItems();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('이미지가 삭제되었습니다')),
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
              },
            ),
          ],
        ),
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('이미지 정보'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow('파일명', item.fileName),
                  const SizedBox(height: 8),
                  _buildDetailRow('크기', _formatBytes(item.fileSize)),
                  const SizedBox(height: 8),
                  _buildDetailRow('수정 시간', item.modifiedTime.toString().split('.')[0]),
                  const SizedBox(height: 8),
                  _buildDetailRow('경로', item.filePath),
                ],
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
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }
}
