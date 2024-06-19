import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart';
import '../services/realtime_service.dart';
import '../widgets/search.dart';
import 'login_screen.dart';
import 'recent_photo_page.dart'; // RecentPhotoPage 포함

class StorageDemoPage extends StatefulWidget {
  @override
  _StorageDemoPageState createState() => _StorageDemoPageState();
}

class _StorageDemoPageState extends State<StorageDemoPage> {
  final FirebaseService firebaseService = FirebaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Refrigerator'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () => showSearch(context: context, delegate: DataSearch([])),
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
            return CircularProgressIndicator();
          }
          if (snapshot.hasError) {
            return Text('오류 발생: ${snapshot.error}');
          }
          if (!snapshot.hasData || snapshot.data == null || snapshot.data!.isEmpty) {
            return Text('표시할 아이템이 없습니다.');
          }
          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final result = snapshot.data![index];
              final productDetails = extractProductDetails(result.texts);
              final expiryDate = result.modifiedExpiryDate.isNotEmpty
                  ? result.modifiedExpiryDate
                  : (productDetails['expiryDate'] ?? "날짜 없음");
              final daysRemaining = expiryDate != "날짜 없음"
                  ? _calculateRemainingDays(expiryDate)
                  : 0;
              final progress = expiryDate != "날짜 없음"
                  ? _calculateProgress(daysRemaining)
                  : 0.0;
              final productName = result.productName.isNotEmpty
                  ? result.productName
                  : (productDetails['productName'] ?? "이름 없음");

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
                      LinearProgressIndicator(value: progress),
                      Text('${daysRemaining.abs()}일 남음'),
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
          print('Camera trigger set to true at $timestamp'); // 디버그 출력 추가

          // Navigate to RecentPhotoPage
          if (mounted) {
            print('Navigating to RecentPhotoPage'); // 라우팅 로그 추가
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => RecentPhotoPage(timestamp: timestamp)),
            );
          }
        },
        child: Icon(Icons.camera_alt),
      ),
    );
  }

  Map<String, String?> extractProductDetails(List<String> texts) {
    final RegExp datePattern =
    RegExp(r'\b(0?[1-9]|1[0-2])/(0?[1-9]|[12][0-9]|3[01])\b');
    final RegExp datePattern2 =
    RegExp(r'\b(0?[1-9]|[12][0-9]|3[01])/(0?[1-9]|1[0-2])/(0?[0-9]|[0-9]{2})\b');
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
    RegExp(r'\b(0?[1-9]|[12][0-9]|3[01])/(0?[1-9]|1[0-2])/(0?[0-9]|[0-9]{2})\b');
    final matches = reverse ? datePattern2.firstMatch(text) : datePattern.firstMatch(text);
    if (matches != null) {
      String year = DateTime.now().year.toString().substring(2); // Default to current year
      String month = reverse ? matches.group(2)!.padLeft(2, '0') : matches.group(1)!.padLeft(2, '0');
      String day = reverse ? matches.group(1)!.padLeft(2, '0') : matches.group(2)!.padLeft(2, '0');
      return '$year/$month/$day';
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
        } else {
          endDate = DateFormat('yy/MM/dd').parseStrict(expiryDate);
        }
      } else {
        endDate = DateFormat('yy/MM/dd').parseStrict(expiryDate);
      }

      final now = DateTime.now();
      final currentDate = DateTime(now.year, now.month, now.day);
      return endDate.difference(currentDate).inDays;
    } catch (e) {
      print('날짜 포맷 오류: $e');
      return 0;
    }
  }

  double _calculateProgress(int daysDifference) {
    return (daysDifference > 0 ? daysDifference / 365 : 0.0).clamp(0.0, 1.0);
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
}