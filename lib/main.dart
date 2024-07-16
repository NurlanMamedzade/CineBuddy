import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:CineBuddy/AuthScreen.dart';
import 'package:CineBuddy/FavoriteMoviesProvider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:CineBuddy/VerifyEmailPage.dart';
import 'pages/HomePage.dart'; // HomePage dosyasını import ediyoruz
import 'ResetPasswordPage.dart'; // Şifre sıfırlama sayfasını import ediyoruz

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FavoriteMoviesProvider()),
      ],
      child: MyApp(),
    ),
  );
}


class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: AuthHandler(),
      routes: {
        '/home': (context) => HomePage(),
        '/reset_password': (context) => ResetPasswordScreen(),
        '/verify_email': (context) => VerifyEmailPage(),
        '/auth': (context) => AuthScreen(),
      },
    );
  }
}


class AuthHandler extends StatefulWidget {
  @override
  _AuthHandlerState createState() => _AuthHandlerState();
}

class _AuthHandlerState extends State<AuthHandler> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FlutterSecureStorage _storage = FlutterSecureStorage();

  User? _user;

  @override
  void initState() {
    super.initState();
    _auth.authStateChanges().listen((User? user) {
      setState(() {
        _user = user;
      });
      if (user != null) {
        _storage.write(key: 'uid', value: user.uid);
      } else {
        _storage.delete(key: 'uid');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return AuthScreen();
    } else if (!_user!.emailVerified) {
      return VerifyEmailPage();
    } else {
      return HomePage();
    }
  }
}
