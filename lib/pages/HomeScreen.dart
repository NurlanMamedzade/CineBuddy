import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:CineBuddy/FavoriteMoviesProvider.dart';
import 'package:CineBuddy/pages/AdminPanelPage.dart';
import 'package:CineBuddy/pages/MovieDetailPage.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

class HomeScreen extends StatefulWidget {
  final String searchQuery;

  HomeScreen({required this.searchQuery});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<String> _selectedGenres = [];

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return FilterDialog(
          onApplyFilter: (selectedGenres) {
            setState(() {
              _selectedGenres = selectedGenres;
            });
          },
        );
      },
    );
  }

  bool isAdminUser = false;

  @override
  void initState() {
    super.initState();
    _checkAdmin();
  }

  Future<bool> isAdmin() async {
    String userId = FirebaseAuth.instance.currentUser!.uid;
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('admin').doc(userId).get();
    return userDoc['isAdmin'] ?? false;
  }
  Future<void> _checkAdmin() async {
    bool adminStatus = await isAdmin();
    setState(() {
      isAdminUser = adminStatus;
    });
  }
  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor:  Color(0xFF0A163F),
      appBar: AppBar(

        backgroundColor: Color(0xFF0A163F),
        actions: [
          IconButton(
            icon: Icon(Icons.search,size: 27,color: Colors.white,),
            onPressed: () {
              showSearch(
                context: context,
                delegate: MovieSearchDelegate(),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.filter_list,size: 27,color: Colors.white,),
            onPressed: () {
              _showFilterDialog();
            },
          ),
          if (isAdminUser)
            IconButton(
              icon: Icon(Icons.admin_panel_settings,size: 27,color: Colors.white,),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AdminPanelPage()),
                );
              },
            ),

        ],
      ),
      body:       StreamBuilder(
        stream: _firestore.collection('movies_approved').snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          var movies = snapshot.data!.docs.where((doc) {
            var movieName = doc['movie_name'].toString().toLowerCase();
            var genres = List<String>.from(doc['genre'] ?? []).map((genre) => genre.toLowerCase()).toList();
            var query = widget.searchQuery.toLowerCase();

            bool nameMatch = movieName.contains(query);
            bool genreMatch = _selectedGenres.isEmpty || _selectedGenres.any((selectedGenre) => genres.contains(selectedGenre.toLowerCase()));

            return nameMatch && genreMatch;
          }).toList();

          return GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // number of items in each row
              mainAxisSpacing: 4.0, // spacing between rows
              crossAxisSpacing: 4.0, // spacing between columns
              childAspectRatio: 0.54,
            ),
            // padding around the grid
            itemCount: movies.length, // total number of items
            itemBuilder: (context, index) {
              var movie = movies[index];
              var movieId = movie.id;

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
                  elevation: 2,
                  margin: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          movie['image_url'],
                          width: double.infinity,
                          height: height / 4,
                          fit: BoxFit.cover,
                        ),
                      ),
                      SizedBox(height: 9),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              movie['movie_name'],
                              style: TextStyle(
                                fontSize: width / 27,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 7),
                            Text(
                              '${movie['release_date']}',
                              style: TextStyle(fontSize: width / 33, color: Colors.white60),
                            ),
                            SizedBox(height: 5),
                            Align(
                              alignment: Alignment.bottomRight,
                              child: IconButton(
                                icon: Icon(
                                  context.watch<FavoriteMoviesProvider>().favoriteMovieIds.contains(movieId)
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: context.watch<FavoriteMoviesProvider>().favoriteMovieIds.contains(movieId)
                                      ? Colors.red
                                      : Colors.grey,
                                ),
                                onPressed: () {
                                  context.read<FavoriteMoviesProvider>().toggleFavorite(movieId);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class FilterDialog extends StatefulWidget {
  final Function(List<String>) onApplyFilter;

  FilterDialog({required this.onApplyFilter});

  @override
  _FilterDialogState createState() => _FilterDialogState();
}

class _FilterDialogState extends State<FilterDialog> {
  List<String> _allGenres = [];
  List<String> _selectedGenres = [];

  @override
  void initState() {
    super.initState();
    _fetchFilters();
  }

  Future<void> _fetchFilters() async {
    try {
      final QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('movies_approved').get();

      if (snapshot.docs.isNotEmpty) {
        Set<String> genres = {};

        snapshot.docs.forEach((doc) {
          List<dynamic> docGenres = doc['genre'] ?? [];
          docGenres.forEach((genre) {
            genres.add(genre.toString());
          });
        });

        setState(() {
          _allGenres = genres.toList();
        });
      }
    } catch (e) {
      print('Error fetching filters: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Filter'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Janr'),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: _allGenres.map((genre) {
                return FilterChip(
                  label: Text(genre),
                  selected: _selectedGenres.contains(genre),
                  onSelected: (bool selected) {
                    setState(() {
                      if (selected) {
                        _selectedGenres.add(genre);
                      } else {
                        _selectedGenres.remove(genre);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            widget.onApplyFilter(_selectedGenres);
            Navigator.pop(context);
          },
          child: Text('Filterlə'),
        ),
        TextButton(
          onPressed: () {
            setState(() {
              _selectedGenres.clear();
            });
            widget.onApplyFilter(_selectedGenres);
            Navigator.pop(context);
          },
          child: Text('Təmizlə'),
        ),
      ],
    );
  }
}














class MovieSearchDelegate extends SearchDelegate {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return StreamBuilder(
      stream: _firestore.collection('movies_approved').snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        var results = snapshot.data!.docs.where((doc) {
          return doc['movie_name'].toString().toLowerCase().contains(query.toLowerCase());
        }).toList();

        return ListView.builder(
          itemCount: results.length,
          itemBuilder: (context, index) {
            var movie = results[index];

            return ListTile(
              title: Text(movie['movie_name']),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MovieDetailPage(movie: movie),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return StreamBuilder(
      stream: _firestore.collection('movies_approved').snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        var suggestions = snapshot.data!.docs.where((doc) {
          return doc['movie_name'].toString().toLowerCase().contains(query.toLowerCase());
        }).toList();

        return ListView.builder(
          itemCount: suggestions.length,
          itemBuilder: (context, index) {
            var movie = suggestions[index];

            return ListTile(
              title: Text(movie['movie_name']),
              onTap: () {
                query = movie['movie_name'];
                showResults(context);
              },
            );
          },
        );
      },
    );
  }
}
