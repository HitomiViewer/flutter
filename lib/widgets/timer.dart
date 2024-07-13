import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TimerWidget extends StatefulWidget {
  final DateTime updateTime;

  TimerWidget({required this.updateTime});

  @override
  _TimerWidgetState createState() => _TimerWidgetState();
}

class _TimerWidgetState extends State<TimerWidget> {
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _startTimer() {
    const oneSec = Duration(seconds: 1);
    _timer = Timer.periodic(oneSec, (timer) {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    DateFormat formatter = DateFormat('yyyy. MM. dd. HH:mm:ss');
    return Text(
      'Last updated: ${formatter.format(widget.updateTime.toLocal())}, ${DateTime.now().difference(widget.updateTime).inMinutes} minutes ago',
      style: TextStyle(fontSize: 16),
    );
  }
}
