import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:hitomiviewer/api/hitomi.dart';
import 'package:hitomiviewer/store.dart';
import 'package:provider/provider.dart';

import '../widgets/preview.dart';

class HitomiScreenArguments {
  final String? query;

  HitomiScreenArguments({this.query});
}

@RoutePage()
class HitomiScreen extends StatefulWidget {
  final String? query;
  const HitomiScreen({Key? key, this.query}) : super(key: key);

  @override
  State<HitomiScreen> createState() => _HitomiScreenState();
}

class _HitomiScreenState extends State<HitomiScreen> {
  late Future<List<int>> galleries;

  get hasQuery => widget.query != null && widget.query != '';
  get query => widget.query;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (query == null || query == '') {
      galleries = fetchPost(context.watch<Store>().language);
    } else {
      galleries = searchGallery(query, context.watch<Store>().language);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: hasQuery
          ? AppBar(
              title: Text(query),
            )
          : null,
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
