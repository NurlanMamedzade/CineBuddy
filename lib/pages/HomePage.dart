import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:CineBuddy/pages/AddMovie.dart';
import 'package:CineBuddy/pages/FavScreen.dart';
import 'package:CineBuddy/pages/HomeScreen.dart';
import 'package:CineBuddy/pages/MovieDetailPage.dart';
import 'package:CineBuddy/pages/ProfileScreen.dart';
import 'package:flutter/services.dart';
import 'package:CineBuddy/pages/YourAddedMovieScreen.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  String searchQuery = "";
  List<String> selectedDirectors = [];
  List<String> _selectedGenres = [];


  static List<Widget> _widgetOptions = <Widget>[
    HomeScreen(searchQuery: ""),
    FavScreen(),
    YourAddedMovieScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }


  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: Color(0xFF0A163F),

      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar:  BottomAppBar(
        color: Color(0xFF030A18),
        shape: CircularNotchedRectangle(),
        notchMargin: 9.0,
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            IconButton(
              icon: Icon(Icons.home,size: 30,color: Colors.white,),
              onPressed: () => _onItemTapped(0),
            ),
            IconButton(
              icon: Icon(Icons.favorite,size: 30,color: Colors.white,),
              onPressed: () => _onItemTapped(1),
            ),
            SizedBox(width: 40.0), // Ortadaki boşluğu sağlamak için SizedBox ekliyoruz
            IconButton(
              icon: Icon(Icons.library_add_sharp,size: 30,color: Colors.white,),
              onPressed: () => _onItemTapped(2),
            ),
            IconButton(
              icon: Icon(Icons.person,size: 30,color: Colors.white,),
              onPressed: () => _onItemTapped(3),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Padding(
        padding: const  EdgeInsets.only(bottom: 12.0),
        child: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MovieInputPage(),
              ),
            );
          },
          tooltip: 'Əlavə et',
          child: Icon(Icons.add,color: Colors.white60,),
          elevation: 2.0,
          backgroundColor: Color(0xFF3B476C),
        ),
      ),
      resizeToAvoidBottomInset: false,
    );
  }
}

















