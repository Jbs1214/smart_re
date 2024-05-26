import 'package:firebase_database/firebase_database.dart';

class OCRResult {
  final String url;
  final List<String> texts;  // 텍스트 배열로 변경

  OCRResult({required this.url, required this.texts});

  factory OCRResult.fromJson(Map<dynamic, dynamic> json) {
    final url = json['image_url'] as String? ?? '기본 이미지 URL';
    final textsList = json['texts'] as List<dynamic>? ?? [];  // 배열로 처리
    List<String> texts = textsList.map((text) => text.toString()).toList(); // 배열의 각 요소를 문자열로 변환
    return OCRResult(
      url: url,
      texts: texts,
    );
  }
}


class FirebaseService {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  Stream<List<OCRResult>> getOCRResults() {
    return _dbRef.child('ocr_results').onValue.map((event) {
      final results = <OCRResult>[];
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data != null) {
        data.forEach((key, value) {
          final result = OCRResult.fromJson(value as Map<dynamic, dynamic>);
          results.add(result);
        });
      }
      return results;
    });
  }
}
