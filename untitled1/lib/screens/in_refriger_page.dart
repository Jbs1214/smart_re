import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class FridgeGalleryPage extends StatelessWidget {
  final FirebaseStorage storage = FirebaseStorage.instance;

  Future<List<Map<String, dynamic>>> _loadImages() async {
    final ListResult result = await storage.ref().listAll();
    List<Map<String, dynamic>> files = [];
    for (var file in result.items) {
      final url = await file.getDownloadURL();
      final name = file.name;
      files.add({"url": url, "name": name});
    }
    return files;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('냉장고 보기'),
      ),
      body: FutureBuilder(
        future: _loadImages(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Text("이미지를 로드하는 데 실패했습니다.");
          }
          final images = snapshot.data as List<Map<String, dynamic>>;
          return ListView.builder(
            itemCount: images.length,
            itemBuilder: (context, index) {
              return ListTile(
                leading: Image.network(images[index]['url'], width: 100, height: 100),
                title: Text(images[index]['name']),
              );
            },
          );
        },
      ),
    );
  }
}
