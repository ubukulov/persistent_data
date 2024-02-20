import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Картинка',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ImageDownloader(),
    );
  }
}

class ImageDownloader extends StatefulWidget {
  @override
  _ImageDownloaderState createState() => _ImageDownloaderState();
}

class _ImageDownloaderState extends State<ImageDownloader> {
  final TextEditingController _urlController = TextEditingController();
  List<File> _savedImages = [];

  Future<void> _downloadImage(String url) async {
    try {
      var response = await http.get(Uri.parse(url));
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String appDirPath = appDir.path;
      final String fileName = 'image_${DateTime.now().millisecondsSinceEpoch}.png';
      final File localImage = File('$appDirPath/$fileName');
      await localImage.writeAsBytes(response.bodyBytes);
      setState(() {
        _savedImages.add(localImage);
      });
    } catch (e) {
      print('Error downloading image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Картинка скачать'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _urlController,
              decoration: InputDecoration(labelText: 'Введите URL'),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              _downloadImage(_urlController.text);
            },
            child: Text('Скачать'),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _savedImages.length,
              itemBuilder: (BuildContext context, int index) {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Image.file(_savedImages[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}