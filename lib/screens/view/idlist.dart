import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import 'package:prompt_dialog/prompt_dialog.dart';
import 'package:scroll_to_index/scroll_to_index.dart';

import '../../widgets/preview.dart';

class IdScreenArguments {
  final List<int> ids;

  IdScreenArguments({required this.ids});
}

@RoutePage()
class IdScreen extends StatefulWidget {
  final List<int> ids;
  const IdScreen({Key? key, required this.ids}) : super(key: key);

  @override
  State<IdScreen> createState() => _IdScreenState();
}

class _IdScreenState extends State<IdScreen> {
  AutoScrollController _controller = AutoScrollController();

  get ids => widget.ids;

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
      appBar: AppBar(),
      body: Center(
          child: ListView.separated(
        controller: _controller,
        itemCount: ids.length,
        itemBuilder: (context, index) {
          return AutoScrollTag(
            key: ValueKey(ids[index]),
            controller: _controller,
            index: ids[index],
            child: Preview(id: ids[index]),
          );
        },
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
        separatorBuilder: (context, index) => const SizedBox(height: 10),
      )),
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
        ],
      ),
    );
  }
}
