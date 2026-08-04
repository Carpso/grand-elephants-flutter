class CartItem {
  final String id;
  final String name;
  final double price;
  final String image;
  final int quantity;

  const CartItem({
    required this.id,
    required this.name,
    required this.price,
    required this.image,
    this.quantity = 1,
  });

  double get total => price * quantity;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'price': price,
        'image': image,
        'quantity': quantity,
      };

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
        id: json['id'] as String,
        name: json['name'] as String,
        price: (json['price'] as num).toDouble(),
        image: json['image'] as String,
        quantity: json['quantity'] as int? ?? 1,
      );

  CartItem copyWith({
    String? id,
    String? name,
    double? price,
    String? image,
    int? quantity,
  }) =>
      CartItem(
        id: id ?? this.id,
        name: name ?? this.name,
        price: price ?? this.price,
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

  const Order({
    required this.id,
    required this.items,
    this.subtotal = 0,
    this.deliveryFee = 0,
    required this.total,
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
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'items': items.map((e) => e.toJson()).toList(),
        'subtotal': subtotal,
        'deliveryFee': deliveryFee,
        'total': total,
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
      };

  factory Order.fromJson(Map<String, dynamic> json) => Order(
        id: json['id'] as String,
        items: (json['items'] as List)
            .map((e) => CartItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
        deliveryFee: (json['deliveryFee'] as num?)?.toDouble() ?? 0,
        total: (json['total'] as num).toDouble(),
        date: json['date'] as String,
        status: json['status'] as String,
        paymentMethod: json['paymentMethod'] as String? ?? 'mobile_money',
        paymentStatus: json['paymentStatus'] as String? ?? 'pending',
        transactionId: json['transactionId'] as String?,
        referenceId: json['referenceId'] as String?,
        deliveryAddress: json['deliveryAddress'] as String? ?? '',
        deliveryMethod: json['deliveryMethod'] as String? ?? 'standard',
        customerPhone: json['customerPhone'] as String?,
        notes: json['notes'] as String?,
      );
}
