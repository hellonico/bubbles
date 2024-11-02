import 'package:bubbles/app.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_markdown/flutter_markdown.dart'; // For markdown preview
import 'package:url_launcher/url_launcher.dart';
import '../goal.dart';

class EditTaskPage extends StatefulWidget {
  final Task task;
  final Goal goal; // Use Goal parameter directly to access goal information
  final ValueChanged<String> onSave;
  final ValueChanged<String> onNameChange;
  final Function(Task, Goal) onGoalChange;

  const EditTaskPage({
    Key? key,
    required this.task,
    required this.goal,
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
  bool _isPreviewMode = false; // Track preview mode
  bool _isStarred = false;
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(text: widget.task.description ?? '');
    _titleController = TextEditingController(text: widget.task.title);
    _isStarred = widget.task.isStarred ?? false; // Initialize star state
    _isCompleted = widget.task.isCompleted ?? false; // Initialize completed state
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
                  trailing: goal == widget.goal ? Icon(Icons.check) : null,
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
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: widget.goal.color, // Display the goal's color
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(4), // Small rounded corners
            ),
          ),
        ),
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
            : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.task.title), // Task title as main title
            Text(
              widget.goal.name ?? 'Unnamed Goal', // Goal name as subtitle
              style: TextStyle(fontSize: 14, color: Colors.black), // Subtitle style
            ),
          ],
        ),
        leadingWidth: 56,
        actions: [
          IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              widget.onSave(_descriptionController.text);
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isPreviewMode
            ? Markdown(data: _descriptionController.text, onTapLink: (text, href, title) {
          if (href != null) {
            _launchURL(href); // Handle the link tap
          }
        },) // Markdown preview
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
          SizedBox(height: 16),
          FloatingActionButton(
            onPressed: () {
              setState(() {
                _isStarred = !_isStarred; // Toggle star status
                widget.task.isStarred = _isStarred; // Update task
              });
            },
            child: Icon(
              _isStarred ? Icons.star : Icons.star_border,
              color: _isStarred ? Colors.yellow : Colors.black,
            ),
            tooltip: _isStarred ? 'Unstar Task' : 'Star Task',
          ),
          SizedBox(height: 16),
          FloatingActionButton(
            onPressed: () {
              setState(() {
                _isCompleted = !_isCompleted; // Toggle completion status
                widget.task.isCompleted = _isCompleted; // Update task
              });
            },
            child: Icon(
              _isCompleted ? Icons.check_box : Icons.check_box_outline_blank,
              color: _isCompleted ? Colors.green : Colors.black,
            ),
            tooltip: _isCompleted ? 'Mark as Incomplete' : 'Mark as Complete',
          ),
        ],
      ),
    );
  }


  // Function to launch URLs
  void _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      throw 'Could not launch $url';
    }
  }
}
