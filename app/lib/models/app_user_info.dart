class AppUserInfo {
  static String? uid;
  static String? name;
  static String? email;

  static void updateFromFirebaseUser(user) {
    uid = user?.uid;
    name = user?.displayName ?? "Usuário";
    email = user?.email;
  }
}
