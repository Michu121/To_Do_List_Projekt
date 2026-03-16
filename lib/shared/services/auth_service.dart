import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AuthService {

  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> get authState => _auth.authStateChanges();

  /// EMAIL LOGIN

  Future<UserCredential> loginEmail(
      String email,
      String password
      ) async {

    return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password
    );
  }

  Future<UserCredential> registerEmail(
      String email,
      String password
      ) async {

    return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password
    );
  }

  /// GOOGLE

  Future<UserCredential?> signInGoogle() async {

    final googleUser = await GoogleSignIn().signIn();

    if (googleUser == null) return null;

    final googleAuth = await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken
    );

    return await _auth.signInWithCredential(credential);
  }

  /// APPLE

  Future<UserCredential> signInApple() async {

    final apple = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName
        ]
    );

    final oauth = OAuthProvider("apple.com").credential(
        idToken: apple.identityToken,
        accessToken: apple.authorizationCode
    );

    return await _auth.signInWithCredential(oauth);
  }

  Future<void> logout() async {

    await GoogleSignIn().signOut();
    await _auth.signOut();
  }
}