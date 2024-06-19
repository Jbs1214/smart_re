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
