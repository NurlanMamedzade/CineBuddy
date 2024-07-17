
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';

class MovieInputPage extends StatefulWidget {
  @override
  _MovieInputPageState createState() => _MovieInputPageState();
}

class _MovieInputPageState extends State<MovieInputPage> {
  final TextEditingController _movieNameController = TextEditingController();
  final TextEditingController _runningTimeController = TextEditingController();
  final TextEditingController _releaseDateController = TextEditingController();
  final TextEditingController _directedByController = TextEditingController();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  List<String> _selectedGenres = [];

  final List<String> _genres = [
    "Dram",
    "Komediya",
    "Elmi fantastika",
    "Qorxu",
    "Macəra",
    "Romantik",
    "Cinayət",
    "Triller",
    "Psixoloji",
    "Animasiya",
    "Tarixi",
    "Bioqrafik",
    "Musiqili",
    "Sənədli film",
    "Qərb (Western)",
    "Döyüş",
    "Sport"
  ];

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<String> _uploadImage(File image) async {
    String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    Reference storageRef = FirebaseStorage.instanceFor(bucket: "gs://cinebuddy-f14d7.appspot.com").ref().child('movie_images').child(fileName);
    UploadTask uploadTask = storageRef.putFile(image);
    TaskSnapshot taskSnapshot = await uploadTask;
    return await taskSnapshot.ref.getDownloadURL();
  }

  void _submitMovie(BuildContext context) async {
    String movieName = _movieNameController.text.trim();
    String runningTime = _runningTimeController.text.trim();
    String releaseDate = _releaseDateController.text.trim();
    String directedBy = _directedByController.text.trim();
    String userId = FirebaseAuth.instance.currentUser!.uid;

    if (movieName.isNotEmpty &&
        _selectedGenres.isNotEmpty &&
        runningTime.isNotEmpty &&
        releaseDate.isNotEmpty &&
        directedBy.isNotEmpty &&
        _selectedImage != null) {
      try {
        String imageUrl = await _uploadImage(_selectedImage!);

        // Yorumlar için harita oluştur
        List<Map<String, dynamic>> commentsMap = [
          {
            'comment': "Bu film mükəmməldir!",
            'time': Timestamp.fromDate(DateTime(2023, 7, 10)),
            'user_id': "Admin",
            'username': "Admin"
          },
        ];

        // Firestore'a veriyi ekle
        await _firestore.collection('movies_pending').add({
          'movie_name': movieName,
          'genre': _selectedGenres,
          'running_time': runningTime,
          'release_date': releaseDate,
          'directed_by': directedBy,
          'image_url': imageUrl,
          'comments': commentsMap,
          'user_id': userId,
          'status': 'pending'
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Film təsdiq olunduqdan sonra əlavə olunacaqdır.')));

        Navigator.pop(context); // Geri dön
      } catch (e) {
        print('Veri eklenirken hata oluştu: $e');
        // Hata durumunda kullanıcıya bildirim gösterebilirsiniz
      }
    } else {
      // Gerekli alanları doldurması gerektiğini belirten bir bildirim gösterebilirsiniz
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Film Yüklə'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Card(
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _selectedImage == null
                    ? Text(
                  'Poster seçilmədi.',
                  textAlign: TextAlign.center,
                )
                    : Image.file(_selectedImage!),
                SizedBox(height: 12.0),
                ElevatedButton(
                  onPressed: _pickImage,
                  child: Text('Poster Yüklə'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                  ),
                ),
                SizedBox(height: 12.0),
                TextFormField(
                  controller: _movieNameController,
                  decoration: InputDecoration(
                    labelText: 'Filmin Adı',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 12.0),
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Text("Janr",style: TextStyle(fontSize: 17),),
                ),
                Wrap(
                  spacing: 4.0,
                  children: _genres.map((genre) {
                    return FilterChip(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),

                      ),
                      label: Text(genre,style: TextStyle(fontSize: 11),),
                      selected: _selectedGenres.contains(genre),
                      onSelected: (isSelected) {
                        setState(() {
                          if (isSelected) {
                            _selectedGenres.add(genre);
                          } else {
                            _selectedGenres.remove(genre);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                SizedBox(height: 12.0),
                TextFormField(
                  controller: _runningTimeController,
                  decoration: InputDecoration(
                    labelText: 'Müddəti',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 12.0),
                TextFormField(
                  controller: _releaseDateController,
                  decoration: InputDecoration(
                    labelText: 'Buraxılış ili',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 12.0),
                TextFormField(
                  controller: _directedByController,
                  decoration: InputDecoration(
                    labelText: 'Rejissor',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 12.0),
                ElevatedButton(
                  onPressed: () => _submitMovie(context),
                  child: Text('Yadda saxla',style: TextStyle(color: Colors.white),),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


