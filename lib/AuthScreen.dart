import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';



class AuthScreen extends StatefulWidget {
  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {


  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _storage = FlutterSecureStorage();
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  bool _isLogin = true;
  bool isVisible = false;

  void _toggleFormType() {
    setState(() {
      _isLogin = !_isLogin;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final username = _usernameController.text.trim();


    try {
      if (_isLogin) {
        UserCredential userCredential = await _auth.signInWithEmailAndPassword(email: email, password: password);

        if (userCredential.user!.emailVerified) {
          await _storage.write(key: 'uid', value: userCredential.user!.uid);
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/home'); // Başarılı giriş sonrası yönlendirme
          }
        } else {
          await _auth.signOut();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Zəhmət olmasa e-poçt adresinizi təsdiqləyin.')));
          }
        }
      } else {
        UserCredential userCredential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
        await userCredential.user?.updateDisplayName(username); // Kullanıcı adı ekleme
        await userCredential.user?.sendEmailVerification(); // E-posta doğrulama gönderme
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Qeydiyyatın uğurlu olması üçün zəhmət olmasa e-poçtunuzu təsdiqləyin.')));
          Navigator.pushReplacementNamed(context, '/verify_email');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Nəsə yalnış getdi...")));
      }
    }

  }
  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: Color(0xFF0A163F),
      body: Stack(
        children: [
          // Siyah opak katman
          Container(
            color: Colors.black.withOpacity(0.7),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: 13),
                    Container(width:width/1.7,height: height/4, child: Image.asset("images/CineBuddytr.png",scale: 2,)),
                    Text(
                      _isLogin ? 'Hesaba daxil ol' : 'Hesab yarat',
                      style: TextStyle(color: Colors.white, fontSize: width/17, fontWeight: FontWeight.bold),
                    ),

                    SizedBox(height: 24.0),
                    if (!_isLogin)
                      TextFormField(
                        controller: _usernameController,
                        style: TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.person, color: Colors.white),
                          labelText: 'İstifadəçi Adı',
                          labelStyle: TextStyle(color: Colors.white),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white),
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.orange),
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          filled: true,
                          fillColor: Colors.black.withOpacity(0.5),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Zəhmət olmasa istifadəçi adınızı daxil edin';
                          }
                          return null;
                        },
                      ),
                    SizedBox(height: 20),
                    TextFormField(
                      controller: _emailController,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.email, color: Colors.white),
                        labelText: 'E-poçt ünvanı',
                        labelStyle: TextStyle(color: Colors.white),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.orange),
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        filled: true,
                        fillColor: Colors.black.withOpacity(0.5),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Zəhmət olmasa e-poçt ünvanını daxil edin';
                        }
                        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                          return 'Yalnış e-poçt adresi';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20),
                    TextFormField(
                      controller: _passwordController,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.lock, color: Colors.white),
                        suffixIcon: IconButton(onPressed: (){setState(() {
                          isVisible = !isVisible;
                        });}, icon: Icon(isVisible ? Icons.visibility_off : Icons.visibility,color: Colors.white)),
                        labelText: 'Şifrə',
                        labelStyle: TextStyle(color: Colors.white),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.orange),
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        filled: true,
                        fillColor: Colors.black.withOpacity(0.5),
                      ),
                      obscureText: isVisible ? false : true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Zəhmət olmasa şifrənizi daxil edin';
                        }
                        if (value.length < 8) {
                          return 'Şifrəniz ən az 8 simvol olmalıdır';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24.0),
                        gradient: LinearGradient(
                          colors: [Color(0xFFF23B79), Color(0xFFFF7C00)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.5),
                            spreadRadius: 1,
                            blurRadius: 8,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: EdgeInsets.symmetric(vertical: 14.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24.0),
                          ),
                        ),
                        child: Text(
                          _isLogin ? 'Daxil ol' : 'Qeydiyyat',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _toggleFormType,
                      child: Text(
                        _isLogin
                            ? 'Hesabınız yoxdu? Qeydiyyatdan keçin'
                            : 'Hesabınız var ? Daxil olun',
                        style: TextStyle(color: Colors.white,fontSize: width/30),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/reset_password');
                      },
                      child: Text('Şifrəmi Unutdum', style: TextStyle(color: Colors.white,fontSize: width/31)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


