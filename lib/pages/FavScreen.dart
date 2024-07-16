import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:CineBuddy/FavoriteMoviesProvider.dart';
import 'package:provider/provider.dart';
import 'package:CineBuddy/pages/MovieDetailPage.dart';

class FavScreen extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF0A163F),
        title: Text(
          "Favoritlər",
          style: TextStyle(fontSize: 16, color: Colors.white),
        ),
      ),
      backgroundColor: Color(0xFF0A163F),
      body: Consumer<FavoriteMoviesProvider>(
        builder: (context, favoriteMoviesProvider, child) {
          if (favoriteMoviesProvider.favoriteMovieIds.isEmpty) {
            return Center(
              child: Text(
                'Favorit filminiz yoxdu...',
                style: TextStyle(fontSize: 22, color: Colors.white),
              ),
            );
          }

          return StreamBuilder(
            stream: _firestore.collection('movies_approved').where(
              FieldPath.documentId,
              whereIn: favoriteMoviesProvider.favoriteMovieIds,
            ).snapshots(),
            builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (!snapshot.hasData) {
                return Center(child: CircularProgressIndicator());
              }

              var movies = snapshot.data!.docs;

              return ListView.builder(
                itemCount: movies.length,
                itemBuilder: (context, index) {
                  var movie = movies[index];

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MovieDetailPage(movie: movie),
                        ),
                      );
                    },
                    child: Card(
                      color: Color(0xFF273767),
                      elevation: 3,
                      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              movie['image_url'],
                              width: width / 3,
                              height: height / 4,
                              fit: BoxFit.cover,
                            ),
                          ),
                          SizedBox(width: 30),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    movie['movie_name'],
                                    style: TextStyle(
                                        fontSize: width / 21,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    '${movie['directed_by']} - ${movie['release_date']}',
                                    style: TextStyle(
                                        fontSize: width / 24,
                                        color: Colors.white70),
                                  ),
                                  SizedBox(height: width / 10),
                                  Align(
                                    alignment: Alignment.bottomRight,
                                    child: IconButton(
                                      icon: Icon(
                                        Icons.favorite,
                                        color: Colors.red,
                                      ),
                                      onPressed: () {
                                        context
                                            .read<FavoriteMoviesProvider>()
                                            .toggleFavorite(movie.id);
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
