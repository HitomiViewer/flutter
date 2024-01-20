import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../favorite/favorite.dart';
import '../hitomi/hitomi.dart';
import '../search/search.dart';

GlobalKey homeScreenNavigator = GlobalKey(debugLabel: 'home_btm_nav');

@RoutePage()
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  final List<Widget> _screens = [
    SearchScreen(),
    const HitomiScreen(),
    const FavoriteScreen(),
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
              // color: Theme.of(context).colorScheme.onBackground,
            ),
            label: '홈',
          ),
          BottomNavigationBarItem(
            icon: SvgPicture.asset(
              'assets/icons/suggest.svg',
              // color: Theme.of(context).colorScheme.onBackground,
            ),
            label: '추천',
          ),
          const BottomNavigationBarItem(
            // icon: SvgPicture.asset(
            //   'assets/icons/favorite.svg',
            // ),
            icon: Icon(
              Icons.favorite_border,
              // color: Theme.of(context).colorScheme.onBackground,
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
