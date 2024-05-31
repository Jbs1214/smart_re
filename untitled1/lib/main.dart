import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart';
import 'package:untitled1/screens/in_refriger_page.dart';
import 'package:untitled1/screens/login_screen.dart';
import 'package:untitled1/widgets/search.dart';
import 'firebase_options.dart';
import 'services/realtime_service.dart';
import 'package:intl/intl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final ValueNotifier<int> _authIndexNotifier = ValueNotifier(0);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        _authIndexNotifier.value = snapshot.hasData ? 1 : 0;
        return ValueListenableBuilder<int>(
          valueListenable: _authIndexNotifier,
          builder: (context, authIndex, child) {
            return MaterialApp.router(
              routeInformationProvider: _router.routeInformationProvider,
              routeInformationParser: _router.routeInformationParser,
              routerDelegate: _router.routerDelegate,
              title: 'My Refrigerator',
            );
          },
        );
      },
    );
  }

  GoRouter get _router => GoRouter(
    refreshListenable: _authIndexNotifier,
    routes: <GoRoute>[
      GoRoute(
        path: '/login',
        builder: (BuildContext context, GoRouterState state) => LoginScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (BuildContext context, GoRouterState state) => StorageDemoPage(),
      ),
      GoRoute(
        path: '/fridge-gallery',
        builder: (BuildContext context, GoRouterState state) => FridgeGalleryPage(),
      ),
    ],
    redirect: (BuildContext context, GoRouterState state) {
      if (_authIndexNotifier.value == 0 && state.uri.path != '/login') {
        return '/login';
      }
      if (_authIndexNotifier.value == 1 && state.uri.path != '/home' && state.uri.path != '/fridge-gallery') {
        return '/home';
      }
      return null;
    },
  );
}


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
                  MaterialPageRoute(builder: (context) => LoginScreen())
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
          if (snapshot.data == null || snapshot.data!.isEmpty) {
            return Text('표시할 아이템이 없습니다.');
          }
          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final result = snapshot.data![index];
              final productDetails = extractProductDetails(result.texts);
              final expiryDate = productDetails['expiryDate'];
              final daysRemaining = _calculateRemainingDays(expiryDate!);
              final progress = _calculateProgress(daysRemaining);
              final productName = productDetails['productName'];

              // Updated logic to check confidence for all related product names
              final lowConfidence = result.confidences.any((c) => c < 0.8);
              final confidenceMessage = lowConfidence ? ' (정확도가 낮을 수 있습니다)' : '';

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
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Firebase Realtime Database에서 카메라 트리거 값 설정
          DatabaseReference ref = FirebaseDatabase.instance.ref('camera-control/trigger');
          await ref.set(true);
        },
        child: Icon(Icons.camera_alt),
      ),
    );
  }


  Map<String, String> extractProductDetails(List<String> texts) {
    final RegExp datePattern = RegExp(r'\b(\d{2})?/?(0[1-9]|1[0-2])/(0[1-9]|[12][0-9]|3[01])\b');
    String productName = '';
    String expiryDate = "날짜 없음";
    bool capturingName = true;

    for (String text in texts) {
      if (datePattern.hasMatch(text) && capturingName) {
        productName += text.split(datePattern).first.trim();
        capturingName = false;
        expiryDate = findExpiryDate(text);
      } else if (capturingName) {
        productName += text + ' ';
      }
    }

    return {
      'productName': productName.trim(),
      'expiryDate': expiryDate
    };
  }

  String findExpiryDate(String text) {
    final RegExp datePattern = RegExp(r'\b(\d{2})?/?(0[1-9]|1[0-2])/(0[1-9]|[12][0-9]|3[01])\b');
    final matches = datePattern.firstMatch(text);
    if (matches != null) {
      String year = matches.group(1) ?? DateTime.now().year.toString().substring(2);
      String month = matches.group(2)!;
      String day = matches.group(3)!;
      return '$year/$month/$day';
    }
    return "날짜 없음";
  }

  int _calculateRemainingDays(String expiryDate) {
    final dateFormat = DateFormat('yy/MM/dd');
    try {
      DateTime endDate = dateFormat.parseStrict(expiryDate);
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
}
