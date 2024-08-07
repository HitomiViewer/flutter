import 'dart:developer';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import 'package:hitomiviewer/services/hitomi.dart';
import 'package:hitomiviewer/store.dart';
import 'package:hitomiviewer/widgets/timer.dart';
import 'package:intl/intl.dart';
import 'package:prompt_dialog/prompt_dialog.dart';
import 'package:provider/provider.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import 'package:tuple/tuple.dart';

import '../../widgets/preview.dart';

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
  late Future<DateTime?> date;

  final AutoScrollController _controller = AutoScrollController();

  get hasQuery => widget.query != null && widget.query != '';
  get query => widget.query;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    Future<Tuple2<List<int>, DateTime?>> data;
    if (query == null || query == '') {
      data = fetchPost(context.watch<Store>().language);
    } else {
      data = searchGallery(query, context.watch<Store>().language);
    }
    galleries = data.then((value) => value.item1);
    date = data.then((value) => value.item2);
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
        child: Stack(
          children: [
            FutureBuilder(
              key: Key(context.watch<Store>().language),
              future: galleries,
              builder: (context, AsyncSnapshot<List<int>> snapshot) {
                if (snapshot.hasData) {
                  return (ListView.separated(
                    controller: _controller,
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      return AutoScrollTag(
                        key: ValueKey(snapshot.data![index]),
                        controller: _controller,
                        index: snapshot.data![index],
                        child: Preview(id: snapshot.data![index]),
                      );
                    },
                    padding: const EdgeInsets.symmetric(
                        vertical: 32, horizontal: 20),
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 10),
                  ));
                } else if (snapshot.hasError) {
                  return Text('${snapshot.error}');
                }
                return const CircularProgressIndicator();
              },
            ),
            FutureBuilder(
              future: date,
              builder: (context, AsyncSnapshot<DateTime?> snapshot) {
                print(snapshot.data);
                if (snapshot.hasData) {
                  return Positioned(
                    top: 0,
                    left: 0,
                    width: MediaQuery.of(context).size.width,
                    child: Container(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: TimerWidget(updateTime: snapshot.data!),
                    ),
                  );
                } else if (snapshot.hasError) {
                  return Text('${snapshot.error}');
                }
                return Container();
              },
            )
          ],
        ),
      ),
      floatingActionButtonLocation: ExpandableFab.location,
      floatingActionButton: ExpandableFab(
        distance: 60,
        children: [
          FloatingActionButton.small(
            heroTag: null,
            child: const Icon(Icons.search),
            onPressed: () async {
              final id = await prompt(context);
              _controller.scrollToIndex(int.parse(id ?? '0'),
                  preferPosition: AutoScrollPosition.begin);
            },
          ),
          FloatingActionButton.small(
            heroTag: null,
            child: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                Future<Tuple2<List<int>, DateTime?>> data;
                if (query == null || query == '') {
                  data = fetchPost(context.read<Store>().language);
                } else {
                  data = searchGallery(query, context.read<Store>().language);
                }
                galleries = data.then((value) => value.item1);
                date = data.then((value) => value.item2);
                date.then((value) => value?.toLocal()).then(print);
              });
            },
          ),
        ],
      ),
    );
  }
}
