enum MobileMoneyNetwork {
  mtn('MTN', 'MTN Mobile Money'),
  airtel('Airtel', 'Airtel Money'),
  zamtel('Zamtel', 'Zamtel Kwacha');

  final String displayName;
  final String fullName;

  const MobileMoneyNetwork(this.displayName, this.fullName);

  String get lipilaNetworkName {
    switch (this) {
      case MobileMoneyNetwork.mtn:
        return 'mtn';
      case MobileMoneyNetwork.airtel:
        return 'airtel';
      case MobileMoneyNetwork.zamtel:
        return 'zamtel';
    }
  }
}

class BusinessCollectionNumber {
  final String id;
  final String businessName;
  final String businessId;
  final MobileMoneyNetwork network;
  final String phoneNumber;
  final String tillNumber;
  final bool isActive;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String addedBy;

  const BusinessCollectionNumber({
    required this.id,
    required this.businessName,
    required this.businessId,
    required this.network,
    required this.phoneNumber,
    required this.tillNumber,
    this.isActive = true,
    this.isDefault = false,
    required this.createdAt,
    required this.updatedAt,
    required this.addedBy,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'businessName': businessName,
        'businessId': businessId,
        'network': network.name,
        'phoneNumber': phoneNumber,
        'tillNumber': tillNumber,
        'isActive': isActive,
        'isDefault': isDefault,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'addedBy': addedBy,
      };

  factory BusinessCollectionNumber.fromJson(Map<String, dynamic> json) =>
      BusinessCollectionNumber(
        id: json['id'] as String,
        businessName: json['businessName'] as String,
        businessId: json['businessId'] as String,
        network: MobileMoneyNetwork.values.firstWhere(
          (e) => e.name == json['network'],
          orElse: () => MobileMoneyNetwork.mtn,
        ),
        phoneNumber: json['phoneNumber'] as String,
        tillNumber: json['tillNumber'] as String? ?? '',
        isActive: json['isActive'] as bool? ?? true,
        isDefault: json['isDefault'] as bool? ?? false,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        addedBy: json['addedBy'] as String,
      );

  BusinessCollectionNumber copyWith({
    String? id,
    String? businessName,
    String? businessId,
    MobileMoneyNetwork? network,
    String? phoneNumber,
    String? tillNumber,
    bool? isActive,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? addedBy,
  }) =>
      BusinessCollectionNumber(
        id: id ?? this.id,
        businessName: businessName ?? this.businessName,
        businessId: businessId ?? this.businessId,
        network: network ?? this.network,
        phoneNumber: phoneNumber ?? this.phoneNumber,
        tillNumber: tillNumber ?? this.tillNumber,
        isActive: isActive ?? this.isActive,
        isDefault: isDefault ?? this.isDefault,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        addedBy: addedBy ?? this.addedBy,
      );
}