import 'dart:async';
import 'package:flutter/material.dart';

class TaskTimerPage extends StatefulWidget {
  final String taskName;
  final VoidCallback onComplete;
  final VoidCallback onLater;

  const TaskTimerPage({
    Key? key,
    required this.taskName,
    required this.onComplete,
    required this.onLater,
  }) : super(key: key);

  @override
  _TaskTimerPageState createState() => _TaskTimerPageState();
}

class _TaskTimerPageState extends State<TaskTimerPage> {
  late Timer _timer;
  Duration _duration = Duration(minutes: 30); // Set 30-minute timer

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer.cancel(); // Cancel the timer if the page is closed
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_duration.inSeconds == 0) {
        _timer.cancel();
        _playMelody(); // Play melody when timer reaches zero
      } else {
        setState(() {
          _duration = _duration - Duration(seconds: 1);
        });
      }
    });
  }

  void _playMelody() {
    // Here you can play a melody when the timer finishes
    // For example, you could use the assets_audio_player package to play a sound
    // AssetsAudioPlayer.newPlayer().open(Audio("assets/melody.mp3"));
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Time\'s up!'),
        content: Text('The 30-minute timer has ended.'),
        actions: [
          TextButton(
            child: Text('OK'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              widget.taskName,
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Text(
              _formatDuration(_duration),
              style: TextStyle(fontSize: 50, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    _timer.cancel(); // Cancel the timer
                    widget.onComplete(); // Trigger the complete action
                  },
                  child: Text('Complete'),
                ),
                SizedBox(width: 20),
                ElevatedButton(
                  onPressed: () {
                    _timer.cancel(); // Cancel the timer
                    widget.onLater(); // Trigger the "later" action
                  },
                  child: Text('Later'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
