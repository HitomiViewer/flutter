import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:hitomiviewer/services/hitomi.dart';
import 'package:hitomiviewer/services/image_embedding.dart';
import 'package:hitomiviewer/store.dart';
import 'package:hitomiviewer/widgets/preview.dart';
import 'package:provider/provider.dart';

import '../../app_router.gr.dart';

@RoutePage()
class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('검색'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              context.router.pushNamed('/settings');
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.tag), text: '태그 검색'),
            Tab(icon: Icon(Icons.image_search), text: 'AI 검색'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          TagSearchTab(),
          const AISearchTab(),
        ],
      ),
    );
  }
}

// 기존 태그 검색
class TagSearchTab extends StatelessWidget {
  TagSearchTab({Key? key}) : super(key: key);

  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text(
                'Hitomi Viewer',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Text(
                '검색어를 입력해주세요',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(vertical: 20),
                height: 40,
                child: IntrinsicWidth(
                  child: Container(
                    constraints: const BoxConstraints(
                      minWidth: 240,
                    ),
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: '예: type:doujinshi language:korean',
                      ),
                      onSubmitted: (String query) {
                        context.router.push(HitomiRoute(query: query));
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('자동완성 검색'),
                    content: TextField(
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: '태그 입력...',
                      ),
                      onSubmitted: (String query) {
                        autocomplete(query).then((value) {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text('검색 결과'),
                                content: SizedBox(
                                  width: double.maxFinite,
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: value.length,
                                    itemBuilder:
                                        (BuildContext context, int index) {
                                      return ListTile(
                                        title: Text(value[index].toString()),
                                        onTap: () {
                                          _controller.text +=
                                              " ${value[index]}";
                                          Navigator.pop(context);
                                          Navigator.pop(context);
                                        },
                                      );
                                    },
                                  ),
                                ),
                              );
                            },
                          );
                        });
                      },
                    ),
                  );
                },
              );
            },
            child: const Icon(Icons.search),
          ),
        ),
      ],
    );
  }
}

// 새로운 AI 검색
class AISearchTab extends StatefulWidget {
  const AISearchTab({Key? key}) : super(key: key);

  @override
  State<AISearchTab> createState() => _AISearchTabState();
}

class _AISearchTabState extends State<AISearchTab> {
  final TextEditingController _controller = TextEditingController();
  List<SimilarImageResult>? _searchResults;
  bool _isSearching = false;
  String? _errorMessage;

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _isSearching = true;
      _errorMessage = null;
      _searchResults = null;
    });

    try {
      final store = Provider.of<Store>(context, listen: false);
      final embeddingService = ImageEmbeddingService();

      // 임베딩이 생성된 갤러리만 검색
      if (store.galleryEmbeddings.isEmpty) {
        setState(() {
          _errorMessage = '분석된 갤러리가 없습니다.\n설정 > 배치 분석에서 갤러리를 먼저 분석해주세요.';
          _isSearching = false;
        });
        return;
      }

      // 텍스트 기반 검색
      final results = await embeddingService.searchByText(
        query,
        store.galleryEmbeddings,
      );

      // 상위 100개만 표시
      final topResults = results.take(100).toList();

      setState(() {
        _searchResults = topResults;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'AI 검색 실패: $e';
        _isSearching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<Store>(context);

    return Column(
      children: [
        // 검색 바
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: 'AI로 이미지 검색 (예: 빨간 머리 소녀, 판타지 배경)',
                  border: const OutlineInputBorder(),
                  suffixIcon: _isSearching
                      ? const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : IconButton(
                          icon: const Icon(Icons.search),
                          onPressed: () => _performSearch(_controller.text),
                        ),
                ),
                onSubmitted: _performSearch,
              ),
              const SizedBox(height: 8),
              Text(
                '분석된 갤러리: ${store.galleryEmbeddings.length}개',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 4),
              Text(
                '💡 PE-Core AI가 이미지의 의미를 이해하여 검색합니다',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ],
          ),
        ),

        // 검색 결과
        Expanded(
          child: _buildSearchResults(store),
        ),
      ],
    );
  }

  Widget _buildSearchResults(Store store) {
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      );
    }

    if (_searchResults == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_search, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              '검색어를 입력하여 AI 이미지 검색을 시작하세요',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            const Text(
              '예시:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                '빨간 머리 소녀',
                '판타지 배경',
                '학교 교복',
                '해변 풍경',
              ]
                  .map((example) => ActionChip(
                        label: Text(example),
                        onPressed: () {
                          _controller.text = example;
                          _performSearch(example);
                        },
                      ))
                  .toList(),
            ),
          ],
        ),
      );
    }

    if (_searchResults!.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              '검색 결과가 없습니다',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults!.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final result = _searchResults![index];
        final galleryId = result.id;
        final similarity = result.similarity;

        return Stack(
          children: [
            Preview(
              key: Key(galleryId.toString()),
              id: galleryId,
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: similarity > 0.7
                      ? Colors.green
                      : similarity > 0.5
                          ? Colors.orange
                          : Colors.grey,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.auto_awesome,
                        size: 16, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      '${(similarity * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
