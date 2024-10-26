import 'package:flutter/material.dart';
import '../mongodb_service.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TextEditingController _urlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUrl();
  }

  Future<void> _loadUrl() async {
    // Load the current URL from the MongoDB service if it’s already set
    String currentUrl = await MongoDBService.getMongoDbUrl();
    _urlController.text = currentUrl;
  }

  Future<void> _saveUrl() async {
    // Save the URL to MongoDBService
    await MongoDBService.setMongoDbUrl(_urlController.text);
    Navigator.pop(context); // Return to main page
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _urlController,
              decoration: InputDecoration(labelText: 'MongoDB URL'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveUrl,
              child: Text('Save URL'),
            ),
          ],
        ),
      ),
    );
  }
}
