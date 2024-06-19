import 'package:flutter/material.dart';
import '../services/realtime_service.dart';

class RecentPhotoPage extends StatelessWidget {
  final String timestamp;
  final FirebaseService firebaseService = FirebaseService();

  RecentPhotoPage({required this.timestamp});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('최근 촬영된 사진'),
      ),
      body: FutureBuilder<String>(
        future: firebaseService.getLatestImageURLAfter(timestamp),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("이미지를 로드하는 데 실패했습니다. ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text("표시할 이미지가 없습니다."));
          }

          final imageUrl = snapshot.data!;
          return Center(
            child: FractionallySizedBox(
              widthFactor: 0.67, // 화면 너비의 2/3
              heightFactor: 0.67, // 화면 높이의 2/3
              child: Image.network(imageUrl, fit: BoxFit.contain),
            ),
          );
        },
      ),
    );
  }
}
