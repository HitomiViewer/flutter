import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:hitomiviewer/apis/hitomi.dart';

import '../app_router.gr.dart';

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
                // child: const HitomiAutocomplete(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HitomiAutocomplete extends StatelessWidget {
  const HitomiAutocomplete({super.key});

  @override
  Widget build(BuildContext context) {
    return Autocomplete<String>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text == '') {
          return const Iterable<String>.empty();
        }
        return autocomplete(textEditingValue.text.toLowerCase()).then((value) {
          return value.map((e) => "${e.ns}:${e.tag}").toList();
        });
      },
      onSelected: (String selection) {
        debugPrint('You just selected $selection');
      },
    );
  }
}
