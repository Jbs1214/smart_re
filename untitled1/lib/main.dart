import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart';
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
    ],
    redirect: (BuildContext context, GoRouterState state) {
      if (_authIndexNotifier.value == 0 && state.uri.path != '/login') {
        return '/login';
      }
      if (_authIndexNotifier.value == 1 && state.uri.path != '/home') {
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
              final expiryDate = findExpiryDate(result.texts);
              final daysRemaining = _calculateRemainingDays(expiryDate);
              final progress = _calculateProgress(daysRemaining);
              final firstTextConfidence = result.confidences.isNotEmpty ? result.confidences[0] : 0.0;
              // Update confidence message display logic
              final productName = result.texts.isNotEmpty ? result.texts[0] : '텍스트 없음';
              final confidenceMessage = firstTextConfidence < 0.8 ? '(부정확한 이름일 수 있습니다)' : '';

              return Card(
                margin: EdgeInsets.all(8),
                child: ListTile(
                  leading: Image.network(result.url, width: 100, height: 100),
                  title: Text('$productName $confidenceMessage'), // Concatenate the message with the product name
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
    );
  }

  String findExpiryDate(List<String> texts) {
    final RegExp datePattern = RegExp(r'\b(\d{2})?/?(0[1-9]|1[0-2])/(0[1-9]|[12][0-9]|3[01])\b');
    final currentYear = DateTime.now().year; // 현재 년도

    for (String text in texts) {
      final matches = datePattern.firstMatch(text);
      if (matches != null) {
        String year = matches.group(1) ?? currentYear.toString().substring(2); // 년도가 없다면 현재 년도의 마지막 두 자리
        String month = matches.group(2)!;
        String day = matches.group(3)!;
        return '$year/$month/$day';  // 완전한 "YY/MM/DD" 형식으로 반환
      }
    }
    return "날짜 없음";  // 매칭되는 날짜가 없을 경우
  }

  int _calculateRemainingDays(String expiryDate) {
    final dateFormat = DateFormat('yy/MM/dd'); // 올바른 년도 표현을 위해 'yy' 사용
    try {
      DateTime endDate = dateFormat.parseStrict(expiryDate); // parseStrict를 사용하여 정확한 날짜만 허용
      final now = DateTime.now();
      final currentDate = DateTime(now.year, now.month, now.day); // 시간을 제외한 현재 날짜
      return endDate.difference(currentDate).inDays;
    } catch (e) {
      // 포맷 예외 발생 시 로그 출력 및 기본값 반환
      print('날짜 포맷 오류: $e');
      return 0; // 유효하지 않은 날짜 포맷인 경우 0일 남음을 반환
    }
  }



  double _calculateProgress(int daysDifference) {
    return (daysDifference > 0 ? daysDifference / 365 : 0.0).clamp(0.0, 1.0);
  }
}
