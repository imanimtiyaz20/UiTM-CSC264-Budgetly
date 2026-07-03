class AppUser {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final String currency;
  final DateTime createdAt;

  AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.currency = 'MYR',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'email': email,
        'displayName': displayName,
        'photoUrl': photoUrl,
        'currency': currency,
        'createdAt': createdAt,
      };

  factory AppUser.fromMap(Map<String, dynamic> map, String uid) => AppUser(
        uid: uid,
        email: map['email'] as String? ?? '',
        displayName: map['displayName'] as String? ?? '',
        photoUrl: map['photoUrl'] as String?,
        currency: map['currency'] as String? ?? 'MYR',
        createdAt: (map['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
      );

  AppUser copyWith({
    String? displayName,
    String? photoUrl,
    String? currency,
  }) =>
      AppUser(
        uid: uid,
        email: email,
        displayName: displayName ?? this.displayName,
        photoUrl: photoUrl ?? this.photoUrl,
        currency: currency ?? this.currency,
        createdAt: createdAt,
      );
}
