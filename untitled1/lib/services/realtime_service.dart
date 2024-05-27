import 'package:firebase_database/firebase_database.dart';

class OCRResult {
  final String url;
  final List<String> texts;
  final List<double> confidences;  // Updated to store a list of confidences

  OCRResult({required this.url, required this.texts, required this.confidences});

  factory OCRResult.fromJson(Map<dynamic, dynamic> json) {
    final url = json['image_url'] as String? ?? '기본 이미지 URL';
    final textsList = json['texts'] as List<dynamic>? ?? [];
    List<String> texts = textsList.map((text) => text.toString()).toList();
    final confidencesList = json['confidences'] as List<dynamic>? ?? [];
    List<double> confidences = confidencesList.map((confidence) => double.tryParse(confidence.toString()) ?? 0.0).toList();
    return OCRResult(
      url: url,
      texts: texts,
      confidences: confidences,
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
