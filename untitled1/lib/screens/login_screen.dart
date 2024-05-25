import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:untitled1/screens/sign_up.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  void _signInWithEmail() async {
    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();

    print('이메일: $email');
    print('비밀번호: $password');

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('이메일과 비밀번호를 입력해주세요.')));
      return;
    }

    try {
      final UserCredential userCredential =
          await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('로그인 성공: ${userCredential.user?.email}')));
      // 로그인 성공 후 추가적인 네비게이션 로직이 필요할 경우 여기에 작성
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('로그인 실패: $e')));
    }
  }

  void _navigateToSignUp(BuildContext context) {
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => SignUpScreen()));
  }

  void _signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser != null) {
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        // Firebase에 사용자 인증 정보를 전달하여 사용자 로그인 처리
        final UserCredential userCredential =
            await FirebaseAuth.instance.signInWithCredential(credential);
        // 로그인 성공 후 처리
        print("Google 로그인 성공: ${userCredential.user}");
      }
    } catch (error) {
      print("Google 로그인 실패: $error");
      // 로그인 실패 처리
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Refrigerator'),
        backgroundColor: Color(0xFFD4B3F5),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            InkWell(
              child: Image.asset('assets/refrigerator.png', height: 160,),
            ),
            SizedBox(height: 60),
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: '이메일',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 10),
            TextFormField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: '비밀번호',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              child: Text(
                '로그인',
                style:
                    TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFD591FC),
              ),
              onPressed: _signInWithEmail,
            ),
            SizedBox(height: 20),
            Divider(thickness: 1, height: 1),
            SizedBox(height: 20),
            InkWell(
              onTap: _signInWithGoogle, // 로그인 메서드를 onTap 콜백에 연결합니다.
              child: Image.asset('assets/google_login.png',
                  height: 48.0), // 이미지 크기를 원하는 대로 조절하세요.
            ),
            SizedBox(height: 20),
            ElevatedButton(
              child: Text(
                '회원가입',
                style: TextStyle(
                    color: Colors.blue,
                    fontSize: 14,
                    fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
              ),
              onPressed: () => _navigateToSignUp(context), // 회원가입 메서드를 연결합니다.
            ),
          ],
        ),
      ),
    );
  }
}
