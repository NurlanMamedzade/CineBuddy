import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;


class MovieDetailPage extends StatelessWidget {
  final DocumentSnapshot movie;

  MovieDetailPage({required this.movie});




  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: Color(0xFF0A163F),
      appBar: AppBar(

        backgroundColor: Color(0xFF0A163F),

        actions: [
          IconButton(
            icon: Icon(Icons.add_comment, color: Colors.white),
            onPressed: () {
              _showAddCommentDialog(context);
            },
          ),
        ],
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white), // Özel geri oku burada tanımlayabilirsiniz.
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('movies_approved')
            .doc(movie.id)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          var updatedMovie = snapshot.data!;
          List<dynamic> commentsList = updatedMovie['comments'] ?? [];

          commentsList.sort((a, b) {
            var timeA = a['time'];
            var timeB = b['time'];
            if (timeA is Timestamp && timeB is Timestamp) {
              return timeB.compareTo(timeA);
            }
            return 0;
          });

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15.0),
                      child: Image.network(
                        updatedMovie['image_url'],
                        width: width/1.3,
                        height: height/2.5,

                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    updatedMovie['movie_name'],
                    style: TextStyle(fontSize: width/18, fontWeight: FontWeight.bold,color: Colors.white),
                  ),
                  SizedBox(height: 10),
                  Divider(thickness: 2,),
                  SizedBox(height: 10),
                  Text(
                    'İl: ${updatedMovie['release_date']}',
                    style: TextStyle(fontSize: width/23,color: Colors.white60),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Müddət: ${updatedMovie['running_time']} dakika',
                    style: TextStyle(fontSize: width/23,color: Colors.white60),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Janr: ${updatedMovie['genre'].join(" ")}',
                    style: TextStyle(fontSize: width/23,color: Colors.white60),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Rejissor: ${updatedMovie['directed_by']}',
                    style: TextStyle(fontSize: width/23,color: Colors.white60),
                  ),
                  SizedBox(height: 20),
                  Divider(thickness: 0.5,),
                  SizedBox(height: 20),

                  Text(
                    'Rəylər:',
                    style: TextStyle(fontSize: width/20,color: Colors.white),
                  ),
                  SizedBox(height: 10),
                  commentsList.isEmpty
                      ? Text('Hələki rəy yoxdur.')
                      : ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: commentsList.length,
                    itemBuilder: (context, index) {
                      var comment = commentsList[index];
                      return _buildCommentItem(comment);
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCommentItem(Map<String, dynamic> comment) {
    return ListTile(
      leading: FutureBuilder<String>(
        future: _getProfilePhotoUrl(comment['user_id']),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircleAvatar(
              child: Icon(Icons.person),
            );
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            return CircleAvatar(
              child: Icon(Icons.person),
            );
          }
          return CircleAvatar(
            backgroundImage: NetworkImage(snapshot.data!),
          );
        },
      ),
      title: Padding(
        padding: const EdgeInsets.all(6.0),
        child: Text(comment['username'] ?? 'Anonim',style: TextStyle(fontSize:13, color: Colors.white70,fontWeight: FontWeight.bold),),
      ),
      subtitle: Container(decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20)
      ),child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(comment['comment'], style: TextStyle(fontSize: 14,color: Colors.white70)),
      )),
      trailing: Text(
        _formatTimestamp(comment['time']),
        style: TextStyle(fontSize: 12,color: Colors.white60),
      ),
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    var date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<String> _getProfilePhotoUrl(String userId) async {
    try {
      var ref = firebase_storage.FirebaseStorage.instanceFor(bucket: "gs://recept-test-e04ff.appspot.com")
          .ref()
          .child('users')
          .child(userId)
          .child('profile.jpg');
      var downloadUrl = await ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error fetching profile photo URL: $e');
      return ''; // return a default image URL or handle the error as needed
    }
  }

  void _showAddCommentDialog(BuildContext context) {
    TextEditingController _commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Rəy yaz'),
          content: TextField(
            controller: _commentController,
            decoration: InputDecoration(hintText: 'Yazın...'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Geri'),
            ),
            TextButton(
              onPressed: () async {
                var user = FirebaseAuth.instance.currentUser;
                if (user != null && _commentController.text.isNotEmpty) {
                  var username = user.displayName ?? 'Anonim'; // Kullanıcı adını al, eğer yoksa 'Anonim' olarak kullan
                  var comment = {
                    'user_id': user.uid,
                    'username': username,
                    'comment': _commentController.text,
                    'time': Timestamp.now(),
                  };

                  var movieDocRef = FirebaseFirestore.instance
                      .collection('movies_approved')
                      .doc(movie.id);

                  await movieDocRef.update({
                    'comments': FieldValue.arrayUnion([comment]),
                  });

                  Navigator.of(context).pop();
                }
              },
              child: Text('Əlavə et'),
            ),
          ],
        );
      },
    );
  }
}



