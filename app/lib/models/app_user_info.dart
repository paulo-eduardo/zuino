class AppUserInfo {
  static String? uid;
  static String? name;
  static String? email;

  static void updateFromFirebaseUser(user) {
    uid = user?.uid;
    name = user?.displayName ?? "Usuário";
    email = user?.email;
    
    // Log update for debugging
    print('AppUserInfo updated: uid=$uid, name=$name, email=$email');
  }
  
  // Get current user info as a map
  static Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
    };
  }
}
