import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_role_model.dart';
import 'role_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final RoleService _roleService = RoleService();

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserRoleModel?> getCurrentUserRole() => _roleService.getCurrentUserRole();

  Stream<UserRoleModel?> getCurrentUserRoleStream() => _roleService.getCurrentUserRoleStream();

  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } catch (e) {
      throw e;
    }
  }

  Future<User?> createUserWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Create user role (default to staff)
      if (result.user != null) {
        await _roleService.createUserRole(
          userId: result.user!.uid,
          role: UserRole.staff,
          email: email,
          displayName: result.user!.displayName,
        );
      }
      
      return result.user;
    } catch (e) {
      throw e;
    }
  }

  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        return null;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential result = await _auth.signInWithCredential(credential);
      
      // Create user role if new user (default to staff)
      if (result.user != null && result.additionalUserInfo?.isNewUser == true) {
        await _roleService.createUserRole(
          userId: result.user!.uid,
          role: UserRole.staff,
          email: result.user!.email ?? googleUser.email,
          displayName: result.user!.displayName ?? googleUser.displayName,
        );
      }
      
      return result.user;
    } catch (e) {
      throw e;
    }
  }

  Future<void> signOut() async {
    try {
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
    } catch (e) {
      throw e;
    }
  }
}