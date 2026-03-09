// Autor: Allan Giovanni Matias Paes

import 'package:firebase_auth/firebase_auth.dart';

Future<Map<String, String>> login(String email, String senha) async {
  try {
    final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: senha,
    );

    final user = credential.user;

    if (user == null) {
      throw Exception("User not found");
    }

    final token = await user.getIdToken();

    return {"uid": user.uid, "token": token!};
  } on FirebaseAuthException catch (e) {
    throw Exception(e.message ?? "Login error");
  }
}
