import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FavoriteMoviesProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<String> _favoriteMovieIds = [];

  List<String> get favoriteMovieIds => _favoriteMovieIds;

  FavoriteMoviesProvider() {
    // Oturum durumu değişikliklerini dinlemek için FirebaseAuth dinleyicisi ekle
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        // Kullanıcı oturumu açtığında veya oturum değiştirdiğinde favori filmleri yükle
        loadFavorites(user.uid);
      } else {
        // Kullanıcı oturumu kapattığında favori filmleri temizle
        _favoriteMovieIds.clear();
        notifyListeners();
      }
    });
  }

  Future<void> loadFavorites(String userId) async {
    var favoritesSnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .get();

    _favoriteMovieIds = favoritesSnapshot.docs.map((doc) => doc.id).toList();

    notifyListeners();
  }

  Future<void> toggleFavorite(String movieId) async {
    var user = _auth.currentUser;
    if (user != null) {
      var favoriteRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .doc(movieId);

      if (_favoriteMovieIds.contains(movieId)) {
        await favoriteRef.delete();
        _favoriteMovieIds.remove(movieId);
      } else {
        await favoriteRef.set({});
        _favoriteMovieIds.add(movieId);
      }

      notifyListeners();
    }
  }
}
