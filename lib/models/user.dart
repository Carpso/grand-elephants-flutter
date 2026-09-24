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
        lat: _asDouble(json['lat']),
        lng: _asDouble(json['lng']),
        address: '${json['address'] ?? ''}',
      );
}

/// Never throws: accepts num, numeric strings and null.
double _asDouble(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse('${value ?? ''}') ?? 0;
}

class User {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String role;
  final String riderStatus;
  final RiderLocation? riderLocation;
  final String? profilePhoto;
  final String? bikePhoto;
  final String? businessId;
  final String? tpin;
  final bool notificationsEnabled;
  final String? createdAt;

  const User({
    required this.uid,
    required this.name,
    required this.email,
    this.phone = '',
    this.role = 'user',
    this.riderStatus = 'none',
    this.riderLocation,
    this.profilePhoto,
    this.bikePhoto,
    this.businessId,
    this.tpin,
    this.notificationsEnabled = true,
    this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'name': name,
        'email': email,
        'phone': phone,
        'role': role,
        'riderStatus': riderStatus,
        'riderLocation': riderLocation?.toJson(),
        'profilePhoto': profilePhoto,
        'bikePhoto': bikePhoto,
        'businessId': businessId,
        'tpin': tpin,
        'notificationsEnabled': notificationsEnabled,
        'createdAt': createdAt,
      };

  factory User.fromJson(Map<String, dynamic> json) => User(
        uid: '${json['uid'] ?? ''}',
        name: '${json['name'] ?? ''}',
        email: '${json['email'] ?? ''}',
        phone: '${json['phone'] ?? ''}',
        role: '${json['role'] ?? 'user'}',
        riderStatus: '${json['riderStatus'] ?? 'none'}',
        riderLocation: json['riderLocation'] is Map
            ? RiderLocation.fromJson(
                Map<String, dynamic>.from(json['riderLocation'] as Map))
            : null,
        profilePhoto: json['profilePhoto']?.toString(),
        bikePhoto: json['bikePhoto']?.toString(),
        businessId: json['businessId']?.toString(),
        tpin: json['tpin']?.toString(),
        notificationsEnabled: json['notificationsEnabled'] is bool
            ? json['notificationsEnabled'] as bool
            : true,
        createdAt: json['createdAt']?.toString(),
      );

  User copyWith({
    String? uid,
    String? name,
    String? email,
    String? phone,
    String? role,
    String? riderStatus,
    RiderLocation? riderLocation,
    String? profilePhoto,
    String? bikePhoto,
    String? businessId,
    String? tpin,
    bool? notificationsEnabled,
    String? createdAt,
  }) =>
      User(
        uid: uid ?? this.uid,
        name: name ?? this.name,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        role: role ?? this.role,
        riderStatus: riderStatus ?? this.riderStatus,
        riderLocation: riderLocation ?? this.riderLocation,
        profilePhoto: profilePhoto ?? this.profilePhoto,
        bikePhoto: bikePhoto ?? this.bikePhoto,
        businessId: businessId ?? this.businessId,
        tpin: tpin ?? this.tpin,
        notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
        createdAt: createdAt ?? this.createdAt,
      );
}
