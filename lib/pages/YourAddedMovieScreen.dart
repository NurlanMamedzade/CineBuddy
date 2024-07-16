import 'package:CineBuddy/pages/MovieDetailPage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';



class YourAddedMovieScreen extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: Color(0xFF0A163F),
      appBar: AppBar(backgroundColor: Color(0xFF0A163F),title: Text("Əlavə etdiyiniz filmlər",style: TextStyle(fontSize: 16,color: Colors.white),),),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('movies_approved')
            .where('user_id', isEqualTo: _auth.currentUser!.uid)
            .snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Məlumat alına bilmədi: ${snapshot.error}'));
          }
          if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('Hələ film əlavə olunmayıb.',style: TextStyle(fontSize: 19,color: Colors.white),));
          }

          return ListView(
            children: snapshot.data!.docs.map((DocumentSnapshot document) {
              var movieData = document.data() as Map<String, dynamic>;
              return ListTile(
                leading: Container(
                  width: 50,
                  height: 50,
                  child: Image.network(
                    movieData['image_url'],
                    fit: BoxFit.cover,
                  ),
                ),
                title: Text(movieData['movie_name'],style: TextStyle(color: Colors.white),),
                subtitle: Text('Rejissor: ${movieData['directed_by']}',style: TextStyle(color: Colors.white70),),
                trailing: IconButton(
                  icon: Icon(Icons.delete,color: Colors.white,),
                  onPressed: () {
                    _confirmDelete(context, document.id);
                  },
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MovieDetailPage(movie: document),
                    ),
                  );
                },
              );
            }).toList(),
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, String documentId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Filmi Sil'),
        content: Text('Bu filmi silmək istədiyinizdən əminsiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Geri'),
          ),
          TextButton(
            onPressed: () => _deleteMovie(context, documentId),
            child: Text('Sil'),
          ),
        ],
      ),
    );
  }

  void _deleteMovie(BuildContext context, String documentId) async {
    try {
      await FirebaseFirestore.instance.collection('movies_approved').doc(documentId).delete();
    } catch (e) {
      print('Film silinirken hata oluştu: $e');
      // Hata durumunda kullanıcıya bildirim gösterebilirsiniz
    }
    Navigator.pop(context); // Dialog kutusunu kapat
  }
}
