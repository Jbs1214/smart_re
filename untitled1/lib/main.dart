import 'package:csv/csv.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart';
import 'package:untitled1/widgets/progress_bar.dart';
import 'package:untitled1/widgets/search.dart';
import 'firebase_options.dart';
import 'package:http/http.dart' as http;
import 'package:go_router/go_router.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({Key? key}) : super(key: key);

  // 로그인 상태를 인덱스로 관리하는 ValueNotifier 생성
  final ValueNotifier<int> _authIndexNotifier = ValueNotifier(0);

  @override
  Widget build(BuildContext context) {
    // FirebaseAuth 상태 변화를 감지하는 StreamBuilder
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 로그인 상태에 따라 인덱스를 갱신
        _authIndexNotifier.value = snapshot.hasData ? 1 : 0;

        // ValueListenableBuilder를 사용하여 _authIndexNotifier 변화 감지
        return ValueListenableBuilder<int>(
          valueListenable: _authIndexNotifier,
          builder: (context, authIndex, child) {
            // GoRouter를 리턴하는 MaterialApp
            return MaterialApp.router(
              routeInformationProvider: _router.routeInformationProvider,
              routeInformationParser: _router.routeInformationParser,
              routerDelegate: _router.routerDelegate,
              title: 'Firebase Storage Example',
            );
          },
        );
      },
    );
  }

  GoRouter get _router => GoRouter(
    refreshListenable: _authIndexNotifier, // 인덱스 변화를 리스닝
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
      // 인덱스에 따라 리디렉션 로직을 처리
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
  List<List<dynamic>> _data = [];

  @override
  void initState() {
    super.initState();
    _loadExcelFile();
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    await GoogleSignIn().signOut();
  }

  Future<void> _loadExcelFile() async {
    try {
      final ref = FirebaseStorage.instance.ref().child('qr_codes.csv');
      final url = await ref.getDownloadURL();
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final body = response.body;
        List<List<dynamic>> csvTable = CsvToListConverter().convert(body);
        setState(() {
          _data = csvTable.sublist(1).map((row) => row.sublist(1)).toList();
        });
      } else {
        setState(() {
          _data = [
            ['Error loading file: ${response.statusCode}']
          ];
        });
      }
    } catch (e) {
      setState(() {
        _data = [
          ['Error loading file: $e']
        ];
      });
    }
  }

  String _calculateExpiryPeriod(String expiryDate) {
    final dateFormat = DateFormat('yyyy.MM.dd');
    DateTime endDate;
    try {
      endDate = dateFormat.parse(expiryDate);
    } on FormatException {
      return '(yyyy.MM.dd) 형태로 입력해주세요.';
    }

    final now = DateTime.now();
    final remainingDays = endDate
        .difference(now)
        .inDays;

    if (remainingDays < 0) {
      return '유통기한이 지났습니다.(${-remainingDays}일 지남)';
    } else if (remainingDays == 0) {
      return 'D-Day';
    } else {
      return 'D-${-remainingDays}일';
    }
  }

  int _calculateRemainingDays(String expiryDate) {
    final dateFormat = DateFormat('yyyy.MM.dd');
    try {
      final endDate = dateFormat.parse(expiryDate);
      final now = DateTime.now();
      return endDate
          .difference(now)
          .inDays;
    } on FormatException {
      // 날짜 형식이 잘못되었을 경우 -1을 반환하거나 적절한 예외 처리를 합니다.
      return -1;
    }
  }

  double _calculateProgress(int daysDifference) {
    if (daysDifference < 0) {
      return 1.0; // 유통기한이 지난 경우, 프로그레스 바를 최대로 표시
    }
    // 유통기한까지 남은 일수에 따라 프로그레스 바 값 계산 로직을 추가합니다.
    // 예: 유통기한까지 100일 남았다면, 1 - (100 / 설정한 기간)으로 계산할 수 있습니다.
    return 1 - daysDifference / 365; // 예시로 365일을 기준으로 계산
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Refrigerator',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              // 검색 기능을 실행합니다.
              showSearch(context: context, delegate: DataSearch(_data));
            },
          ),
          IconButton(
            icon: Icon(Icons.exit_to_app),
            onPressed: () async {
              await _signOut();
              // 로그아웃 후 로그인 화면으로 돌아갑니다.
              Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => LoginScreen()));
            },
          ),
        ],
      ),
      body: _data.isNotEmpty
          ? ListView.builder(
        itemCount: _data.length,
        itemBuilder: (context, index) {
          final itemData = _data[index][0].split('/');
          if (itemData.length < 2) {
            return ListTile(
              title: Text('Incomplete data'),
              subtitle: Text('No sufficient info available'),
            );
          }
          final String foodName = itemData[0].trim();
          final String expiryDate = itemData[1].trim();
          final String remainingDays = _calculateExpiryPeriod(expiryDate);
          final int days = int.tryParse(
              remainingDays.split('일')[0].replaceAll('D-', '')) ??
              0;
          final double sliderValue =
          days > 0 ? (100.0 - days) / 100.0 : 0.0;

          return Column(
            children: <Widget>[
              ListTile(
                title: Text(foodName,
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              ExpiryProgressBar(expiryDate: expiryDate),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  '$remainingDays',
                  style: TextStyle(
                      color: Color(0x9B050505),
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
        },
      )
          : Center(child: CircularProgressIndicator()),
    );
  }
}
