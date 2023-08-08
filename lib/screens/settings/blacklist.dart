// ListView

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:hitomiviewer/store.dart';
import 'package:provider/provider.dart';

@RoutePage()
class BlacklistScreen extends StatefulWidget {
  const BlacklistScreen({Key? key}) : super(key: key);

  @override
  State<BlacklistScreen> createState() => _BlacklistScreenState();
}

class _BlacklistScreenState extends State<BlacklistScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<String> blacklist = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Blacklist'),
      ),
      body: ListView.builder(
        itemCount: context.watch<Store>().blacklist.length,
        itemBuilder: (ctx, index) => ChangeNotifierProvider<Store>.value(
          value: Provider.of(context, listen: false),
          child: ListTile(
            title: Text(ctx.watch<Store>().blacklist[index]),
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                ctx.read<Store>().removeAtBlacklist(index);
                setState(() {});
              },
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (ctx) => ChangeNotifierProvider.value(
              value: Provider.of<Store>(context, listen: false),
              child: AlertDialog(
                title: const Text('Add to blacklist'),
                content: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Input tag here',
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        ctx.read<Store>().addBlacklist(_controller.text);
                        _controller.clear();
                      });
                      Navigator.of(ctx).pop();
                    },
                    child: const Text('Add'),
                  ),
                ],
              ),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
