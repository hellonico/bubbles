import 'package:bubbles/app.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_markdown/flutter_markdown.dart'; // For markdown preview
import '../goal.dart';

class EditTaskPage extends StatefulWidget {
  final Task task;
  final ValueChanged<String> onSave;
  final ValueChanged<String> onNameChange;
  final Function(Task, Goal) onGoalChange;

  const EditTaskPage({
    Key? key,
    required this.task,
    required Goal goal,
    required this.onSave,
    required this.onNameChange,
    required this.onGoalChange,
  }) : super(key: key);

  @override
  _EditTaskPageState createState() => _EditTaskPageState();
}

class _EditTaskPageState extends State<EditTaskPage> {
  late TextEditingController _descriptionController;
  late TextEditingController _titleController;
  bool _isEditingTitle = false;
  bool _isPreviewMode = false; // New variable to track preview mode

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(text: widget.task.description ?? '');
    _titleController = TextEditingController(text: widget.task.title);
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _showGoalSelectionDialog() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<Goal> goals = await AppSettings().loadGoals();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select New Goal for Task'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: goals.length,
              itemBuilder: (context, index) {
                final goal = goals[index];
                return ListTile(
                  title: Text(goal.name ?? 'Unnamed Goal'),
                  trailing: goal == goal ? Icon(Icons.check) : null,
                  onTap: () {
                    widget.onGoalChange(widget.task, goal);
                    Navigator.of(context).pop();
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
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
                widget.onNameChange(_titleController.text);
                setState(() {
                  _isEditingTitle = false;
                });
              },
            ),
            IconButton(
              icon: Icon(Icons.cancel),
              onPressed: () {
                setState(() {
                  _isEditingTitle = false;
                });
              },
            ),
          ],
        )
            : GestureDetector(
          onTap: () {
            setState(() {
              _isEditingTitle = true;
            });
          },
          child: Text(widget.task.title),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            widget.onSave(_descriptionController.text);
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isPreviewMode
            ? Markdown(data: _descriptionController.text) // Markdown preview
            : TextFormField(
          controller: _descriptionController,
          maxLines: null,
          expands: true,
          decoration: InputDecoration(
            labelText: 'Task Description',
            border: OutlineInputBorder(),
          ),
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: _showGoalSelectionDialog,
            child: Icon(Icons.swap_horiz),
            tooltip: 'Move Task to Another Goal',
          ),
          SizedBox(height: 16), // Space between FABs
          FloatingActionButton(
            onPressed: () {
              setState(() {
                _isPreviewMode = !_isPreviewMode; // Toggle preview mode
              });
            },
            child: Icon(_isPreviewMode ? Icons.edit : Icons.remove_red_eye),
            tooltip: _isPreviewMode ? 'Edit Task Content' : 'Preview Markdown',
          ),
        ],
      ),
    );
  }
}
