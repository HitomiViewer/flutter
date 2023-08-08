import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hitomiviewer/app_router.gr.dart';

import 'favorite.dart';
import 'hitomi.dart';

GlobalKey homeScreenNavigator = GlobalKey(debugLabel: 'home_btm_nav');

@RoutePage()
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  final List<Widget> _screens = const [
    SearchScreen(),
    HitomiScreen(),
    FavoriteScreen(),
  ];

  void _onTap(int index) {
    setState(() {
      _index = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _index,
          children: _screens,
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        key: homeScreenNavigator,
        items: [
          BottomNavigationBarItem(
            icon: SvgPicture.asset(
              'assets/icons/home.svg',
              color: Theme.of(context).colorScheme.onBackground,
            ),
            label: '홈',
          ),
          BottomNavigationBarItem(
            icon: SvgPicture.asset(
              'assets/icons/suggest.svg',
              color: Theme.of(context).colorScheme.onBackground,
            ),
            label: '추천',
          ),
          BottomNavigationBarItem(
            // icon: SvgPicture.asset(
            //   'assets/icons/favorite.svg',
            // ),
            icon: Icon(
              Icons.favorite_border,
              color: Theme.of(context).colorScheme.onBackground,
            ),
            label: '즐겨찾기',
          ),
        ],
        currentIndex: _index,
        onTap: _onTap,
      ),
    );
  }
}

@RoutePage()
class SearchScreen extends StatelessWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              context.router.pushNamed('/settings');
            },
          ),
          main(context),
        ],
      ),
    );
  }

  Widget main(BuildContext context) {
    return Center(
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
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
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
    );
  }
}
