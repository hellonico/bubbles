import 'package:flutter/material.dart';
import 'goal.dart'; // Import your Task model

class EditTaskPage extends StatefulWidget {
  final Task task;
  final ValueChanged<String> onSave;

  const EditTaskPage({
    Key? key,
    required this.task,
    required this.onSave,
  }) : super(key: key);

  @override
  _EditTaskPageState createState() => _EditTaskPageState();
}

class _EditTaskPageState extends State<EditTaskPage> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.task.description ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.task.title), // Set title to task name
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            widget.onSave(_controller.text); // Save before going back
            Navigator.of(context).pop(); // Go back
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded( // Make the text field take full height
              child: TextFormField(
                controller: _controller,
                maxLines: null,
                expands: true, // Allow the text field to expand
                decoration: InputDecoration(
                  labelText: 'Task Description',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
