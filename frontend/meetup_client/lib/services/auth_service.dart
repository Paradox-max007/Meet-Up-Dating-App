import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'dart:convert';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final ApiService _apiService = ApiService();

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token != null) {
      _apiService.setToken(token);
    }
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', token);
    _apiService.setToken(token);
  }

  Future<void> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final String? idToken = await userCredential.user?.getIdToken();

      if (idToken != null) {
        final response = await _apiService.post('/auth/google', {'idToken': idToken});
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          await _saveToken(data['access_token']);
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> registerWithEmail(String email, String password) async {
    try {
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final String? idToken = await userCredential.user?.getIdToken();

      if (idToken != null) {
        final response = await _apiService.post('/auth/email', {'idToken': idToken});
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          await _saveToken(data['access_token']);
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signInWithEmail(String email, String password) async {
    try {
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final String? idToken = await userCredential.user?.getIdToken();

      if (idToken != null) {
        final response = await _apiService.post('/auth/email', {'idToken': idToken});
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          await _saveToken(data['access_token']);
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    _apiService.setToken('');
  }
}
