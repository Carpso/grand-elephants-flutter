class CartItem {
  final String id;
  final String name;
  final double price;
  final int priceCents;
  final String image;
  final int quantity;

  const CartItem({
    required this.id,
    required this.name,
    required this.price,
    required this.priceCents,
    required this.image,
    this.quantity = 1,
  });

  double get total => price * quantity;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'price': price,
        'priceCents': priceCents,
        'image': image,
        'quantity': quantity,
      };

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
        id: '${json['id']}',
        name: json['name'] as String? ?? '',
        price: (json['price'] as num?)?.toDouble() ??
            ((json['priceCents'] as num?)?.toDouble() ?? 0) / 100,
        priceCents: (json['priceCents'] as num?)?.toInt() ??
            ((json['price'] as num?)?.toDouble() ?? 0).round() * 100,
        image: json['image'] as String? ?? '',
        quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      );

  CartItem copyWith({
    String? id,
    String? name,
    double? price,
    int? priceCents,
    String? image,
    int? quantity,
  }) =>
      CartItem(
        id: id ?? this.id,
        name: name ?? this.name,
        price: price ?? this.price,
        priceCents: priceCents ?? this.priceCents,
        image: image ?? this.image,
        quantity: quantity ?? this.quantity,
      );
}

class Order {
  final String id;
  final List<CartItem> items;
  final double subtotal;
  final double deliveryFee;
  final double total;
  final int totalCents;
  final String date;
  final String status;
  final String paymentMethod;
  final String paymentStatus;
  final String? transactionId;
  final String? referenceId;
  final String deliveryAddress;
  final String deliveryMethod;
  final String? customerPhone;
  final String? notes;
  final String? businessName;
  final String? riderName;
  final String? invoiceNo;
  final String? invoiceStatus;
  final String? deliveredAt;

  const Order({
    required this.id,
    required this.items,
    this.subtotal = 0,
    this.deliveryFee = 0,
    required this.total,
    this.totalCents = 0,
    required this.date,
    required this.status,
    this.paymentMethod = 'mobile_money',
    this.paymentStatus = 'pending',
    this.transactionId,
    this.referenceId,
    this.deliveryAddress = '',
    this.deliveryMethod = 'standard',
    this.customerPhone,
    this.notes,
    this.businessName,
    this.riderName,
    this.invoiceNo,
    this.invoiceStatus,
    this.deliveredAt,
  });

  static const List<String> validStatuses = [
    'Pending',
    'Confirmed',
    'Processing',
    'Shipped',
    'Out for Delivery',
    'Delivered',
    'Cancelled',
    'Refunded',
  ];

  bool get isCancellable => status == 'Pending' || status == 'Confirmed';
  bool get isDelivered => status == 'Delivered';
  bool get isCancelled => status == 'Cancelled';

  Order withStatus(String newStatus) => Order(
        id: id,
        items: items,
        subtotal: subtotal,
        deliveryFee: deliveryFee,
        total: total,
        totalCents: totalCents,
        date: date,
        status: newStatus,
        paymentMethod: paymentMethod,
        paymentStatus: paymentStatus,
        transactionId: transactionId,
        referenceId: referenceId,
        deliveryAddress: deliveryAddress,
        deliveryMethod: deliveryMethod,
        customerPhone: customerPhone,
        notes: notes,
        businessName: businessName,
        riderName: riderName,
        invoiceNo: invoiceNo,
        invoiceStatus: invoiceStatus,
        deliveredAt: deliveredAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'items': items.map((e) => e.toJson()).toList(),
        'subtotal': subtotal,
        'deliveryFee': deliveryFee,
        'total': total,
        'totalCents': totalCents,
        'date': date,
        'status': status,
        'paymentMethod': paymentMethod,
        'paymentStatus': paymentStatus,
        'transactionId': transactionId,
        'referenceId': referenceId,
        'deliveryAddress': deliveryAddress,
        'deliveryMethod': deliveryMethod,
        'customerPhone': customerPhone,
        'notes': notes,
        'businessName': businessName,
        'riderName': riderName,
        'invoiceNo': invoiceNo,
        'invoiceStatus': invoiceStatus,
        'deliveredAt': deliveredAt,
      };

  factory Order.fromJson(Map<String, dynamic> json) => Order(
        id: '${json['id']}',
        items: (json['items'] as List? ?? [])
            .map((e) => CartItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
        deliveryFee: (json['deliveryFee'] as num?)?.toDouble() ?? 0,
        total: (json['total'] as num?)?.toDouble() ??
            ((json['totalCents'] as num?)?.toDouble() ?? 0) / 100,
        totalCents: (json['totalCents'] as num?)?.toInt() ?? 0,
        date: json['date'] as String? ?? json['createdAt'] as String? ?? '',
        status: json['status'] as String? ?? 'Pending',
        paymentMethod: json['paymentMethod'] as String? ?? 'mobile_money',
        paymentStatus: json['paymentStatus'] as String? ?? 'pending',
        transactionId: json['transactionId'] as String?,
        referenceId: json['referenceId'] as String?,
        deliveryAddress: json['deliveryAddress'] as String? ?? '',
        deliveryMethod: json['deliveryMethod'] as String? ?? 'standard',
        customerPhone: json['customerPhone'] as String?,
        notes: json['notes'] as String?,
        businessName: json['businessName'] as String?,
        riderName: json['riderName'] as String?,
        invoiceNo: json['invoiceNo'] as String?,
        invoiceStatus: json['invoiceStatus'] as String?,
        deliveredAt: json['deliveredAt'] as String?,
      );
}
