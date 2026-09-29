class AuthUser {
  const AuthUser({
    required this.uid,
    required this.email,
    this.isGoogleUser = false,
  });

  final String uid;
  final String email;
  final bool isGoogleUser;
}
