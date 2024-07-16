import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late User _currentUser;
  File? _profileImage;
  String? _profileImageUrl;
  String? _username; // Kullanıcı adını saklamak için bir değişken ekleyin
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _currentUser = _auth.currentUser!;
    _profileImageUrl = _currentUser.photoURL;
    _username = _currentUser.displayName; // Kullanıcı adını Firebase'den alın
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _profileImage = File(pickedFile.path);
        });
        await _uploadProfileImage();
      }
    } catch (e) {
      print(e);
    }
  }
  void _showExitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Hesabdan çıx'),
          content: Text('Çıxmaq istədiyinizdən əminsiniz?'),
          actions: <Widget>[
            TextButton(
              child: Text('Xeyr'),
              onPressed: () {
                Navigator.of(context).pop(); // Dialog'u kapat
              },
            ),
            TextButton(
              child: Text('Bəli'),
              onPressed: () async {
                await _auth.signOut();
                Navigator.pushReplacementNamed(context, '/');
              },
            ),
          ],
        );
      },
    );
  }
  Future<void> _uploadProfileImage() async {
    try {
      if (_profileImage != null) {
        setState(() {
          _isUploading = true;
        });
        var userId = _currentUser.uid;
        var ref = firebase_storage.FirebaseStorage.instanceFor(bucket: "gs://recept-test-e04ff.appspot.com").ref()
            .child('users')
            .child(userId)
            .child('profile.jpg');
        var uploadTask = ref.putFile(_profileImage!);
        var snapshot = await uploadTask.whenComplete(() {});

        var downloadUrl = await snapshot.ref.getDownloadURL();

        // Profil fotoğrafı ve kullanıcı adı güncellemesi
        await _currentUser.updateProfile(
          displayName: _username,
          photoURL: downloadUrl,
        );

        // Profil güncellemesinden sonra Firebase Authentication'dan verileri güncelleyin
        await _currentUser.reload();
        _currentUser = _auth.currentUser!;

        setState(() {
          _profileImageUrl = downloadUrl;
          _isUploading = false;
        });
      }
    } catch (e) {
      print('Profil fotoğrafı yüklenirken bir hata oluştu: $e');
      setState(() {
        _isUploading = false;
      });
    }
  }

  void _changePassword() {
    Navigator.pushNamed(context, '/reset_password');
  }

  void _contactProjectOwner() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Əlaqə'),
          content: Text('Təklif və iradlar üçün:\nnurlanmemmedzade753@gmail.com'),
          actions: <Widget>[
            TextButton(
              child: Text('Bağla'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: Color(0xFF0A163F),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              height: 250,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color:  Color(0xFF07112F),
                  borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30))),
              child: Padding(
                padding: const EdgeInsets.only(top: 37.0),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        GestureDetector(
                          onTap: _pickImage,
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 50,
                                child: _profileImage != null
                                    ? ClipRRect(
                                  borderRadius: BorderRadius.circular(50),
                                  child: Image.file(
                                    _profileImage!,
                                    width: 120,
                                    height: 120,
                                    fit: BoxFit.cover,
                                  ),
                                )
                                    : (_profileImageUrl != null
                                    ? ClipRRect(
                                  borderRadius: BorderRadius.circular(50),
                                  child: Image.network(
                                    _profileImageUrl!,
                                    width: 120,
                                    height: 120,
                                    fit: BoxFit.cover,
                                  ),
                                )
                                    : Icon(Icons.person, size: 70)),
                              ),

                              if (_isUploading)
                                Container(
                                  width: 120,
                                  height: 120,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(50),
                                  ),
                                  child: CircularProgressIndicator(),
                                ),
                            ],
                          ),
                        ),
                        if (_isUploading)
                          Container(
                            width: 120,
                            height: 120,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: CircularProgressIndicator(),
                          ),
                      ],
                    ),
                    SizedBox(height: 10),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => ProfileDetailScreen()),
                        );
                      },
                      child: Column(
                        children: [
                          Text(
                            _currentUser.displayName ?? 'Anonim', // Kullanıcı adını burada gösterin
                            style: TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.all(13.0),
              child: Container(decoration: BoxDecoration(color: Color(0xFF07112F).withOpacity(0.8),borderRadius: BorderRadius.all(Radius.circular(20))),

                child: ListTile(
                  leading: Icon(Icons.lock,color:Colors.white,size: 30,),
                  title: Text('Şifrəni dəyiş', style: TextStyle(color:Colors.white,fontSize: width/24, fontWeight: FontWeight.bold)),
                  onTap: _changePassword,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(13.0),
              child: Container(decoration: BoxDecoration(color: Color(0xFF07112F).withOpacity(0.8),borderRadius: BorderRadius.all(Radius.circular(20))),

                child: ListTile(
                  leading: Icon(Icons.phone,color:Colors.white,size: 30,),
                  title: Text('Əlaqə', style: TextStyle(color:Colors.white,fontSize: width/24, fontWeight: FontWeight.bold)),
                  onTap: _contactProjectOwner,
                ),
              ),
            ),
            SizedBox(height: 20),
            Divider(),
            SizedBox(height: 15),
            Padding(
              padding: const EdgeInsets.only(left:12.0),
              child: ListTile(
                  leading: Icon(Icons.logout, color: Colors.red),
                  title: Text(
                    'Hesabdan çıx',
                    style: TextStyle(color: Colors.red, fontSize: width/22, fontWeight: FontWeight.bold),
                  ),
                  onTap: () {_showExitDialog(context);}
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class ProfileDetailScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final FirebaseAuth _auth = FirebaseAuth.instance;
    final User _currentUser = _auth.currentUser!;

    return Scaffold(
      appBar: AppBar(
        title: Text('Profil Detalları'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 60,
              backgroundImage: _currentUser.photoURL != null ? NetworkImage(_currentUser.photoURL!) : null,
              child: _currentUser.photoURL == null ? Icon(Icons.person, size: 60) : null,
            ),
            SizedBox(height: 20),
            Text(
              _currentUser.displayName ?? 'Anonim',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'E-poçt: ${_currentUser.email}',
              style: TextStyle(fontSize: 13),
            ),
            SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
