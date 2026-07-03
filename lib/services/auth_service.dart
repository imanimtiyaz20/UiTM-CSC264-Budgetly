import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<AppUser?> signInWithEmail(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = cred.user;
      if (user == null) return null;
      return await getUser(user.uid);
    } on FirebaseAuthException catch (e) {
      throw _mapAuthError(e);
    }
  }

  Future<AppUser?> registerWithEmail(
      String email, String password, String displayName,
      {String currency = 'MYR'}) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = cred.user;
      if (user == null) return null;
      await user.updateDisplayName(displayName);
      await user.reload();
      return await _createUser(AppUser(
        uid: user.uid,
        email: email,
        displayName: displayName,
        currency: currency,
      ));
    } on FirebaseAuthException catch (e) {
      throw _mapAuthError(e);
    }
  }

  Future<Map<String, dynamic>?> signInWithGoogle() async {
    try {
      await _googleSignIn.signOut();
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;
      if (user == null) return null;

      final doc =
          await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final appUser = AppUser.fromMap(doc.data()!, user.uid);
        return {'user': appUser, 'isNew': false};
      }

      return {
        'user': AppUser(
          uid: user.uid,
          email: user.email ?? '',
          displayName: user.displayName ?? '',
          photoUrl: user.photoURL,
        ),
        'isNew': true,
        'firebaseUser': user,
      };
    } catch (e) {
      return null;
    }
  }

  Future<AppUser> completeGoogleSetup({
    required AppUser appUser,
    required String password,
    required User firebaseUser,
    String currency = 'MYR',
  }) async {
    try {
      final emailCredential = EmailAuthProvider.credential(
        email: appUser.email,
        password: password,
      );
      await firebaseUser.linkWithCredential(emailCredential);
    } on FirebaseAuthException {
      // Already linked or error — continue
    }
    return await _createUser(appUser.copyWith(currency: currency));
  }

  Future<AppUser> _createUser(AppUser appUser) async {
    await _firestore.collection('users').doc(appUser.uid).set(appUser.toMap());
    await _seedDefaultCategories(appUser.uid);
    return appUser;
  }

  Future<AppUser?> getUser(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return AppUser.fromMap(doc.data()!, uid);
  }

  Future<void> updateUser(AppUser user) async {
    await _firestore.collection('users').doc(user.uid).update({
      'displayName': user.displayName,
      'photoUrl': user.photoUrl,
      'currency': user.currency,
    });
  }

  Future<void> updatePassword(String currentPassword, String newPassword) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) throw Exception('Not authenticated');

    try {
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw _mapAuthError(e);
    }
  }

  Future<void> _seedDefaultCategories(String userId) async {
    final existing = await _firestore
        .collection('categories')
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) return;

    final defaults = [
      {'name': 'Food & Drinks', 'icon': 'restaurant', 'color': '#FF5722', 'type': 'expense'},
      {'name': 'Transport', 'icon': 'directions_car', 'color': '#2196F3', 'type': 'expense'},
      {'name': 'Shopping', 'icon': 'shopping_cart', 'color': '#9C27B0', 'type': 'expense'},
      {'name': 'Bills & Utilities', 'icon': 'receipt', 'color': '#F44336', 'type': 'expense'},
      {'name': 'Entertainment', 'icon': 'movie', 'color': '#FF9800', 'type': 'expense'},
      {'name': 'Health', 'icon': 'local_hospital', 'color': '#4CAF50', 'type': 'expense'},
      {'name': 'Education', 'icon': 'school', 'color': '#795548', 'type': 'expense'},
      {'name': 'Other Expense', 'icon': 'more_horiz', 'color': '#607D8B', 'type': 'expense'},
      {'name': 'Salary', 'icon': 'work', 'color': '#4CAF50', 'type': 'income'},
      {'name': 'Freelance', 'icon': 'computer', 'color': '#2196F3', 'type': 'income'},
      {'name': 'Investment', 'icon': 'trending_up', 'color': '#FF9800', 'type': 'income'},
      {'name': 'Other Income', 'icon': 'more_horiz', 'color': '#607D8B', 'type': 'income'},
    ];

    final batch = _firestore.batch();
    for (final cat in defaults) {
      final docRef = _firestore.collection('categories').doc();
      batch.set(docRef, {
        ...cat,
        'isDefault': false,
        'userId': userId,
        'monthlyBudget': null,
      });
    }
    await batch.commit();
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  String _mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'email-already-in-use':
        return 'An account already exists with this email';
      case 'weak-password':
        return 'Password should be at least 6 characters';
      case 'invalid-email':
        return 'Invalid email address';
      case 'invalid-credential':
        return 'Incorrect password';
      default:
        return 'Authentication failed: ${e.message ?? e.code}';
    }
  }
}
