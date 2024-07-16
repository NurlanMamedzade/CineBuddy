import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:CineBuddy/pages/MovieDetailPage.dart';

class AdminPanelPage extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _approveMovie(DocumentSnapshot movie) async {
    await _firestore.collection('movies_approved').add(movie.data() as Map<String, dynamic>);
    await _firestore.collection('movies_pending').doc(movie.id).delete();
  }

  Future<bool> _isAdmin() async {
    String userId = FirebaseAuth.instance.currentUser!.uid;
    DocumentSnapshot userDoc = await _firestore.collection('admin').doc(userId).get();
    return userDoc['isAdmin'] ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _isAdmin(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return CircularProgressIndicator();
        }

        if (!snapshot.data!) {
          return Scaffold(
            appBar: AppBar(
              title: Text('Admin Paneli'),
            ),
            body: Center(
              child: Text('Admin deyilsiniz.'),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text('Admin Paneli'),
          ),
          body: StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection('movies_pending').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return CircularProgressIndicator();
              }

              return ListView(
                children: snapshot.data!.docs.map((doc) {
                  return ListTile(
                    leading: Container(
                      width: 50,
                      height: 50,
                      child: Image.network(
                        doc['image_url'],
                        fit: BoxFit.cover,
                      ),
                    ),
                    title: Text(doc['movie_name']),
                    subtitle: Text('Rejissor: ${doc['directed_by']}'),
                    trailing: IconButton(
                      icon: Icon(Icons.check),
                      onPressed: () => _approveMovie(doc),
                    ),
                  );

                }).toList(),
              );
            },
          ),
        );
      },
    );
  }
}
