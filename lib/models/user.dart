class RiderLocation {
  final double lat;
  final double lng;
  final String address;

  const RiderLocation({
    required this.lat,
    required this.lng,
    required this.address,
  });

  Map<String, dynamic> toJson() => {
        'lat': lat,
        'lng': lng,
        'address': address,
      };

  factory RiderLocation.fromJson(Map<String, dynamic> json) => RiderLocation(
        lat: (json['lat'] as num).toDouble(),
        lng: (json['lng'] as num).toDouble(),
        address: json['address'] as String,
      );
}

class User {
  final String uid;
  final String name;
  final String email;
  final String role;
  final String riderStatus;
  final RiderLocation? riderLocation;
  final String? profilePhoto;
  final String? bikePhoto;

  const User({
    required this.uid,
    required this.name,
    required this.email,
    this.role = 'user',
    this.riderStatus = 'none',
    this.riderLocation,
    this.profilePhoto,
    this.bikePhoto,
  });

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'name': name,
        'email': email,
        'role': role,
        'riderStatus': riderStatus,
        'riderLocation': riderLocation?.toJson(),
        'profilePhoto': profilePhoto,
        'bikePhoto': bikePhoto,
      };

  factory User.fromJson(Map<String, dynamic> json) => User(
        uid: json['uid'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
        role: json['role'] as String? ?? 'user',
        riderStatus: json['riderStatus'] as String? ?? 'none',
        riderLocation: json['riderLocation'] != null
            ? RiderLocation.fromJson(
                json['riderLocation'] as Map<String, dynamic>)
            : null,
        profilePhoto: json['profilePhoto'] as String?,
        bikePhoto: json['bikePhoto'] as String?,
      );

  User copyWith({
    String? uid,
    String? name,
    String? email,
    String? role,
    String? riderStatus,
    RiderLocation? riderLocation,
    String? profilePhoto,
    String? bikePhoto,
  }) =>
      User(
        uid: uid ?? this.uid,
        name: name ?? this.name,
        email: email ?? this.email,
        role: role ?? this.role,
        riderStatus: riderStatus ?? this.riderStatus,
        riderLocation: riderLocation ?? this.riderLocation,
        profilePhoto: profilePhoto ?? this.profilePhoto,
        bikePhoto: bikePhoto ?? this.bikePhoto,
      );
}
