import 'package:flutter/material.dart';
import '../goal.dart'; // Import your Task model

class EditTaskPage extends StatefulWidget {
  final Task task;
  final ValueChanged<String> onSave;
  final ValueChanged<String> onNameChange; // Callback for task name change

  const EditTaskPage({
    Key? key,
    required this.task,
    required this.onSave,
    required this.onNameChange,
  }) : super(key: key);

  @override
  _EditTaskPageState createState() => _EditTaskPageState();
}

class _EditTaskPageState extends State<EditTaskPage> {
  late TextEditingController _descriptionController;
  late TextEditingController _titleController;
  bool _isEditingTitle = false; // Track if the task name is being edited

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(text: widget.task.description ?? '');
    _titleController = TextEditingController(text: widget.task.title); // Controller for task name
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isEditingTitle
            ? Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: 'Task Name',
                  border: InputBorder.none,
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.check),
              onPressed: () {
                // Save the new name
                widget.onNameChange(_titleController.text);
                setState(() {
                  _isEditingTitle = false; // Exit editing mode
                });
              },
            ),
            IconButton(
              icon: Icon(Icons.cancel),
              onPressed: () {
                // Cancel editing
                setState(() {
                  _isEditingTitle = false; // Exit editing mode without saving
                });
              },
            ),
          ],
        )
            : GestureDetector(
          onTap: () {
            setState(() {
              _isEditingTitle = true; // Switch to editing mode
            });
          },
          child: Text(widget.task.title), // Display task name when not editing
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            widget.onSave(_descriptionController.text); // Save description before going back
            Navigator.of(context).pop(); // Go back
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: TextFormField(
                controller: _descriptionController,
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
