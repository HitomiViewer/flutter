import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:hitomiviewer/store.dart';
import 'package:provider/provider.dart';

import '../widgets/preview.dart';

@RoutePage()
class FavoriteScreen extends StatefulWidget {
  const FavoriteScreen({Key? key}) : super(key: key);

  @override
  State<FavoriteScreen> createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> {
  get galleries => context.watch<Store>().favorite;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorite'),
      ),
      body: Center(
        child: ListView.separated(
          itemCount: galleries.length,
          itemBuilder: (context, index) {
            return Preview(id: galleries[index]);
          },
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
          separatorBuilder: (context, index) => const SizedBox(height: 10),
        ),
      ),
    );
  }
}
