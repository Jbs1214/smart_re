import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart';
import '../services/realtime_service.dart';
import '../services/notification_service.dart';
import '../widgets/search.dart';
import 'login_screen.dart';
import 'recent_photo_page.dart';
import 'dart:math' as math;

class StorageDemoPage extends StatefulWidget {
  @override
  _StorageDemoPageState createState() => _StorageDemoPageState();
}

class _StorageDemoPageState extends State<StorageDemoPage> {
  final FirebaseService firebaseService = FirebaseService();
  final NotificationService notificationService = NotificationService();
  List<OCRResult> ocrResults = [];

  @override
  void initState() {
    super.initState();
    _loadOCRResults();
    _scheduleDailyNotification(); // 추가된 부분
  }

  void _loadOCRResults() async {
    firebaseService.getOCRResults().listen((results) {
      setState(() {
        ocrResults = results;
      });
      _scheduleDailyNotification(); // 유통기한 정보를 업데이트한 후 알림을 설정
    });
  }

  void _scheduleDailyNotification() async {
    await notificationService.init();
    final expiringSoonCount = ocrResults.where((result) {
      final daysRemaining = _calculateRemainingDays(result.modifiedExpiryDate.isNotEmpty
          ? result.modifiedExpiryDate
          : extractProductDetails(result.texts)['expiryDate'] ?? "날짜 없음");
      return daysRemaining <= 7;
    }).length;
    if (expiringSoonCount > 0) {
      await notificationService.scheduleNotification(20, 30, expiringSoonCount);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Refrigerator'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () => showSearch(context: context, delegate: DataSearch(_formatDataForSearch())),
          ),
          IconButton(
            icon: Icon(Icons.exit_to_app),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              await GoogleSignIn().signOut();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<OCRResult>>(
        stream: firebaseService.getOCRResults(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('오류 발생: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data == null || snapshot.data!.isEmpty) {
            return Center(child: Text('표시할 아이템이 없습니다.'));
          }

          // 유통기한이 얼마 남지 않은 순으로 정렬
          List<OCRResult> sortedResults = List.from(snapshot.data!);
          sortedResults.sort((a, b) {
            int daysA = _calculateRemainingDays(a.modifiedExpiryDate.isNotEmpty ? a.modifiedExpiryDate : extractProductDetails(a.texts)['expiryDate'] ?? "날짜 없음");
            int daysB = _calculateRemainingDays(b.modifiedExpiryDate.isNotEmpty ? b.modifiedExpiryDate : extractProductDetails(b.texts)['expiryDate'] ?? "날짜 없음");
            return daysA.compareTo(daysB);
          });

          return ListView.builder(
            itemCount: sortedResults.length,
            itemBuilder: (context, index) {
              final result = sortedResults[index];
              final productDetails = extractProductDetails(result.texts);
              final expiryDate = result.modifiedExpiryDate.isNotEmpty
                  ? result.modifiedExpiryDate
                  : (productDetails['expiryDate'] ?? "날짜 없음");
              final daysRemaining = _calculateRemainingDays(expiryDate);
              final progress = _calculateProgress(daysRemaining);
              final productName = result.productName.isNotEmpty
                  ? result.productName
                  : (productDetails['productName'] ?? "이름 없음");
              final progressColor = _getProgressColor(daysRemaining);

              // Updated logic to check confidence for all related product names
              final lowConfidence = result.confidences.any((c) => c < 0.8);
              final confidenceMessage =
              lowConfidence ? ' (정확도가 낮을 수 있습니다)' : '';

              return Card(
                margin: EdgeInsets.all(8),
                child: ListTile(
                  leading: Image.network(result.url, width: 100, height: 100),
                  title: Text('$productName$confidenceMessage'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('유통기한: $expiryDate'),
                      LinearProgressIndicator(
                        value: progress,
                        valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                        backgroundColor: Colors.grey[300],
                      ),
                      Text(daysRemaining < 0 ? '${daysRemaining.abs()}일 지났습니다' : '${daysRemaining.abs()}일 남음'),
                    ],
                  ),
                  onTap: () => _editProductDialog(
                      context, result, productName, expiryDate),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          DatabaseReference ref = FirebaseDatabase.instance.ref('camera-control/trigger');
          String timestamp = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
          await ref.set({"trigger": true, "timestamp": timestamp});
          print('Camera trigger set to true at $timestamp');

          if (mounted) {
            print('Navigating to RecentPhotoPage');
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => RecentPhotoPage(timestamp: timestamp)),
            );
          }
        },
        child: Icon(Icons.camera_alt),
      ),
    );
  }

  Color _getProgressColor(int daysRemaining) {
    if (daysRemaining < 0) {
      return Colors.red; // 유통기한이 지난 경우
    } else if (daysRemaining <= 7) {
      return Colors.redAccent[100]!; // 유통기한이 7일 이하로 남은 경우
    } else {
      // 남은 기간에 따라 색상이 점점 붉어짐
      double colorIntensity = math.max(0.0, 1.0 - daysRemaining / 30.0);
      return Color.lerp(Colors.green, Colors.red, colorIntensity)!;
    }
  }

  Map<String, String?> extractProductDetails(List<String> texts) {
    final RegExp datePattern =
    RegExp(r'\b(0?[1-9]|1[0-2])/(0?[1-9]|[12][0-9]|3[01])\b');
    final RegExp datePattern2 =
    RegExp(r'\b(0?[1-9]|[12][0-9]|3[01])/(0?[1-9]|1[0-2])/(0?[0-9]{2}|[0-9]{4})\b');
    String productName = '';
    String? expiryDate;
    bool capturingName = true;

    for (String text in texts) {
      if (datePattern.hasMatch(text) && capturingName) {
        expiryDate = findExpiryDate(text);
        capturingName = false;
      } else if (datePattern2.hasMatch(text) && capturingName) {
        expiryDate = findExpiryDate(text, true);
        capturingName = false;
      } else if (capturingName) {
        productName += text + ' ';
      }
    }

    return {
      'productName': productName.trim().isNotEmpty ? productName.trim() : null,
      'expiryDate': expiryDate
    };
  }

  String findExpiryDate(String text, [bool reverse = false]) {
    final RegExp datePattern =
    RegExp(r'\b(0?[1-9]|1[0-2])/(0?[1-9]|[12][0-9]|3[01])\b');
    final RegExp datePattern2 =
    RegExp(r'\b(0?[1-9]|[12][0-9]|3[01])/(0?[1-9]|1[0-2])/(0?[0-9]{2}|[0-9]{4})\b');
    final matches = reverse ? datePattern2.firstMatch(text) : datePattern.firstMatch(text);
    if (matches != null) {
      if (reverse) {
        String year = matches.group(3)!.length == 2
            ? '20' + matches.group(3)!
            : matches.group(3)!;
        String month = matches.group(2)!.padLeft(2, '0');
        String day = matches.group(1)!.padLeft(2, '0');
        return '$year/$month/$day';
      } else {
        String year = DateTime.now().year.toString().substring(2); // Default to current year
        String month = matches.group(1)!.padLeft(2, '0');
        String day = matches.group(2)!.padLeft(2, '0');
        return '$year/$month/$day';
      }
    }
    return "날짜 없음";
  }

  int _calculateRemainingDays(String expiryDate) {
    try {
      DateTime endDate;
      if (expiryDate.contains('/')) {
        final parts = expiryDate.split('/');
        if (parts.length == 2) {
          final formattedExpiryDate =
              '${DateTime.now().year}/${parts[0].padLeft(2, '0')}/${parts[1].padLeft(2, '0')}';
          endDate = DateFormat('yyyy/MM/dd').parseStrict(formattedExpiryDate);
        } else if (parts.length == 3) {
          if (parts[0].length == 2) { // yy/MM/dd 형식일 경우
            endDate = DateFormat('yy/MM/dd').parseStrict(expiryDate);
          } else { // yyyy/MM/dd 형식일 경우
            endDate = DateFormat('yyyy/MM/dd').parseStrict(expiryDate);
          }
        } else {
          throw FormatException("Invalid date format");
        }
      } else {
        throw FormatException("Date does not contain expected delimiter");
      }

      final now = DateTime.now();
      final currentDate = DateTime(now.year, now.month, now.day);
      return endDate.difference(currentDate).inDays;
    } catch (e) {
      print('날짜 포맷 오류: $e');
      return 0;
    }
  }

  double _calculateProgress(int daysRemaining) {
    if (daysRemaining < 0) {
      // 유통기한이 지난 경우
      return 1.0;
    }
    int maxDays = 365; // 유통기한 계산을 위한 최대 일수 예시
    return 1.0 - (daysRemaining / maxDays).clamp(0.0, 1.0);
  }

  void _editProductDialog(BuildContext context, OCRResult result, String productName, String expiryDate) {
    final TextEditingController nameController = TextEditingController(text: productName);
    final TextEditingController dateController = TextEditingController(text: expiryDate);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('제품 수정'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: '제품 이름'),
              ),
              TextField(
                controller: dateController,
                decoration: InputDecoration(labelText: '유통기한 (MM/dd or yy/MM/dd)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('취소'),
            ),
            TextButton(
              onPressed: () async {
                final updatedName = nameController.text;
                final updatedDate = dateController.text;

                // Update the OCR result in Firebase
                await firebaseService.updateOCRResult(result.id, updatedName, updatedDate);

                // Calculate remaining days and progress
                final daysRemaining = _calculateRemainingDays(updatedDate);
                final progress = _calculateProgress(daysRemaining);

                // UI 업데이트
                setState(() {
                  result.productName = updatedName;
                  result.modifiedExpiryDate = updatedDate;
                });

                // Close the dialog
                Navigator.of(context).pop();
              },
              child: Text('저장'),
            ),
          ],
        );
      },
    );
  }

  List<List<dynamic>> _formatDataForSearch() {
    return ocrResults.map((result) {
      final productDetails = extractProductDetails(result.texts);
      return [
        result.productName.isNotEmpty ? result.productName : (productDetails['productName'] ?? "이름 없음"),
        result.modifiedExpiryDate.isNotEmpty ? result.modifiedExpiryDate : (productDetails['expiryDate'] ?? "날짜 없음"),
        result.url // 이미지 URL 추가
      ];
    }).toList();
  }
}
