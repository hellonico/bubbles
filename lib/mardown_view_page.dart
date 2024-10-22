import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'goal.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class MarkdownViewPage extends StatelessWidget {
  final Goal goal;

  MarkdownViewPage({required this.goal});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("${goal.name}")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Markdown(
          data: _generateMarkdownData(),
          onTapLink: (text, href, title) {
            if (href != null) {
              _launchURL(href); // Handle the link tap
            }
          },
        ),
      ),
    );
  }

  String _generateMarkdownData() {
    StringBuffer markdownBuffer = StringBuffer();
    for (var task in goal.tasks) {
      markdownBuffer.writeln('# ${task.title}'); // Task title as header
      if (task.description != null) {
        markdownBuffer.writeln('${task.description}'); // Task description
      }
      markdownBuffer.writeln(); // Blank line for separation
      if (task.isCompleted) {
        markdownBuffer.writeln('--- Completed on:${task.completedAt?.toLocal().toString()}'); // Completion date
      }
      markdownBuffer.writeln();
      // markdownBuffer.writeln("---");
      markdownBuffer.writeln(); // Blank line for separation
    }
    return markdownBuffer.toString();
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
