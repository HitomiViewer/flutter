import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:hitomiviewer/services/hitomi.dart';

import '../../app_router.gr.dart';

@RoutePage()
class SearchScreen extends StatelessWidget {
  SearchScreen({Key? key}) : super(key: key);

  final TextEditingController _controller = TextEditingController();

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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('검색어를 입력해주세요'),
                content: TextField(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
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
                                itemBuilder: (BuildContext context, int index) {
                                  return ListTile(
                                    title: Text(value[index].toString()),
                                    onTap: () {
                                      _controller.text += " ${value[index]}";
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
                  controller: _controller,
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
          return value.map((e) => e.toString()).toList();
        });
      },
      onSelected: (String selection) {
        debugPrint('You just selected $selection');
      },
    );
  }
}
