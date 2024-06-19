import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';

class OCRResult {
  final String id;
  final List<String> texts;
  final List<double> confidences;
  final String url;
  String productName;
  String expiryDate;
  String modifiedExpiryDate; // 새로운 필드

  OCRResult({
    required this.id,
    required this.texts,
    required this.confidences,
    required this.url,
    required this.productName,
    required this.expiryDate,
    this.modifiedExpiryDate = '', // 초기값 설정
  });

  factory OCRResult.fromMap(String id, Map<dynamic, dynamic> map) {
    return OCRResult(
      id: id,
      texts: List<String>.from(map['texts'] ?? []),
      confidences: List<double>.from(map['confidences'] ?? []),
      url: map['image_url'] ?? '',
      productName: map['productName'] ?? '',
      expiryDate: map['expiryDate'] ?? '',
      modifiedExpiryDate: map['modifiedExpiryDate'] ?? '',
    );
  }
}

class FirebaseService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Stream<List<OCRResult>> getOCRResults() {
    return _database.child('ocr_results').onValue.map((event) {
      final List<OCRResult> results = [];
      if (event.snapshot.value != null) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        data.forEach((key, value) {
          results.add(OCRResult.fromMap(key, value));
        });
      }
      return results;
    });
  }

  Future<List<OCRResult>> getOCRResultsOnce() async {
    final snapshot = await _database.child('ocr_results').get();
    final List<OCRResult> results = [];
    if (snapshot.value != null) {
      final data = snapshot.value as Map<dynamic, dynamic>;
      data.forEach((key, value) {
        results.add(OCRResult.fromMap(key, value));
      });
    }
    return results;
  }

  Stream<OCRResult> getLatestOCRResult() {
    return _database.child('ocr_results')
        .orderByChild('timestamp')
        .limitToLast(1)
        .onValue
        .map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>;
      final key = data.keys.first;
      final value = data[key];
      return OCRResult.fromMap(key, value);
    });
  }

  Future<String> getLatestImageURL() async {
    final ListResult result = await _storage.ref('captures/').listAll();
    if (result.items.isNotEmpty) {
      final Reference latestImageRef = result.items.last;
      final String url = await latestImageRef.getDownloadURL();
      return url;
    }
    return '';
  }

  Future<String> getLatestImageURLAfter(String timestamp) async {
    final ListResult result = await _storage.ref('captures/').listAll();
    if (result.items.isNotEmpty) {
      for (var item in result.items.reversed) {
        final FullMetadata metadata = await item.getMetadata();
        final DateTime updatedTime = metadata.updated!;
        final DateTime triggerTime = DateFormat('yyyy-MM-dd HH:mm:ss').parse(timestamp);

        if (updatedTime.isAfter(triggerTime)) {
          final String url = await item.getDownloadURL();
          return url;
        }
      }
    }
    return '';
  }

  Future<void> updateOCRResult(String id, String productName, String modifiedExpiryDate) async {
    await _database.child('ocr_results/$id').update({
      'productName': productName,
      'modifiedExpiryDate': modifiedExpiryDate,
    });
  }
}