import 'package:flutter/material.dart';
import 'package:hitomiviewer/api/hitomi.dart';
import 'package:hitomiviewer/store.dart';
import 'package:provider/provider.dart';

import '../widgets/preview.dart';

class HitomiScreenArguments {
  final String? query;

  HitomiScreenArguments({this.query});
}

class HitomiScreen extends StatefulWidget {
  const HitomiScreen({Key? key}) : super(key: key);

  @override
  State<HitomiScreen> createState() => _HitomiScreenState();
}

class _HitomiScreenState extends State<HitomiScreen> {
  late Future<List<int>> galleries;
  late HitomiScreenArguments? args;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    args = ModalRoute.of(context)!.settings.arguments as HitomiScreenArguments?;
    if (args?.query == null || args?.query == '') {
      galleries = fetchPost(context.watch<Store>().language);
    } else {
      galleries = searchGallery(args?.query, context.watch<Store>().language);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            args?.query == null || args?.query == '' ? '추천' : '${args?.query}'),
        key: Key(context.watch<Store>().language),
      ),
      body: Center(
        child: FutureBuilder(
          key: Key(context.watch<Store>().language),
          future: galleries,
          builder: (context, AsyncSnapshot<List<int>> snapshot) {
            if (snapshot.hasData) {
              return (ListView.separated(
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  return Preview(id: snapshot.data![index]);
                },
                padding:
                    const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 10),
              ));
            } else if (snapshot.hasError) {
              return Text('${snapshot.error}');
            }
            return const CircularProgressIndicator();
          },
        ),
      ),
    );
  }
}
