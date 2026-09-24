import 'package:flutter_test/flutter_test.dart';
import 'package:grand_elephants/models/product.dart';
import 'package:grand_elephants/models/cart_item.dart';
import 'package:grand_elephants/models/user.dart';
import 'package:grand_elephants/providers/config_provider.dart';

Product testProduct() => const Product(
      id: '99',
      name: 'Test Bag',
      price: 1000,
      priceCents: 100000,
      image: 'assets/products/test.png',
      description: 'A test bag',
      category: 'Bags',
    );

void main() {
  group('Product Model', () {
    test('Product.fromJson parses API shape (price + priceCents)', () {
      final json = {
        'id': 99,
        'name': 'Test Bag',
        'price': 1000.0,
        'priceCents': 100000,
        'image': 'assets/products/test.png',
        'description': 'A test bag',
        'category': 'Bags',
        'isGhost': false,
        'stock': 5,
        'businessId': 1,
        'businessName': 'Grand Elephants Store',
      };
      final product = Product.fromJson(json);
      expect(product.id, '99');
      expect(product.name, 'Test Bag');
      expect(product.price, 1000.0);
      expect(product.priceCents, 100000);
      expect(product.stock, 5);
      expect(product.businessName, 'Grand Elephants Store');
    });

    test('Product.fromJson falls back to priceCents when price absent', () {
      final json = {
        'id': '7',
        'name': 'Handbag',
        'priceCents': 450000,
        'category': 'Bags',
      };
      final product = Product.fromJson(json);
      expect(product.price, 4500.0);
    });

    test('Product.toJson roundtrips', () {
      final original = testProduct();
      final json = original.toJson();
      final restored = Product.fromJson(json);
      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.price, original.price);
    });
  });

  group('CartItem Model', () {
    test('CartItem has correct total', () {
      const item = CartItem(id: '1', name: 'Bag', price: 500, priceCents: 50000, image: 'img.png', quantity: 3);
      expect(item.total, 1500.0);
    });

    test('CartItem copyWith works', () {
      const item = CartItem(id: '1', name: 'Bag', price: 500, priceCents: 50000, image: 'img.png');
      final updated = item.copyWith(quantity: 5);
      expect(updated.quantity, 5);
      expect(updated.name, 'Bag');
    });

    test('CartItem toJson/fromJson roundtrip', () {
      const item = CartItem(id: '1', name: 'Bag', price: 500, priceCents: 50000, image: 'img.png', quantity: 2);
      final json = item.toJson();
      final restored = CartItem.fromJson(json);
      expect(restored.id, item.id);
      expect(restored.quantity, 2);
    });
  });

  group('Order Model', () {
    test('Order.fromJson parses API shape', () {
      final json = {
        'id': 'ORD-123-456',
        'items': [
          {'id': 1, 'name': 'Bag', 'price': 4500.0, 'priceCents': 450000, 'image': 'x.png', 'quantity': 2},
        ],
        'subtotal': 9000.0,
        'deliveryFee': 75.0,
        'total': 10777.88,
        'totalCents': 1077788,
        'date': '2026-08-09 15:20:01',
        'status': 'Confirmed',
        'paymentMethod': 'mobile_money',
        'paymentStatus': 'successful',
        'businessName': 'Grand Elephants Store',
        'invoiceNo': 'SOA-2026-000001',
        'riderName': 'Fast Rider',
      };
      final order = Order.fromJson(json);
      expect(order.id, 'ORD-123-456');
      expect(order.status, 'Confirmed');
      expect(order.paymentStatus, 'successful');
      expect(order.items.length, 1);
      expect(order.items.first.priceCents, 450000);
      expect(order.businessName, 'Grand Elephants Store');
      expect(order.invoiceNo, 'SOA-2026-000001');
      expect(order.riderName, 'Fast Rider');
    });

    test('Order toJson/fromJson roundtrip', () {
      const items = [
        CartItem(id: '1', name: 'Bag', price: 500, priceCents: 50000, image: 'img.png', quantity: 2),
      ];
      const order = Order(id: 'ORD001', items: items, total: 1000, date: '2025-01-01', status: 'Delivered');
      final json = order.toJson();
      final restored = Order.fromJson(json);
      expect(restored.id, 'ORD001');
      expect(restored.status, 'Delivered');
      expect(restored.items.length, 1);
    });
  });

  group('User Model', () {
    test('User copyWith preserves fields', () {
      const user = User(uid: 'u1', name: 'John', email: 'j@test.com');
      final updated = user.copyWith(role: 'admin');
      expect(updated.role, 'admin');
      expect(updated.name, 'John');
      expect(updated.uid, 'u1');
    });

    test('User toJson/fromJson roundtrip', () {
      const user = User(uid: 'u1', name: 'John', email: 'j@test.com', role: 'rider', riderStatus: 'approved');
      final json = user.toJson();
      final restored = User.fromJson(json);
      expect(restored.uid, 'u1');
      expect(restored.role, 'rider');
      expect(restored.riderStatus, 'approved');
    });

    test('User.fromJson parses API shape', () {
      final json = {
        'uid': 7,
        'name': 'Godfrey',
        'email': 'g@test.com',
        'phone': '260976847775',
        'role': 'superadmin',
        'businessId': '1',
        'notificationsEnabled': true,
      };
      final user = User.fromJson(json);
      expect(user.uid, '7');
      expect(user.phone, '260976847775');
      expect(user.role, 'superadmin');
      expect(user.businessId, '1');
    });
  });

  group('ConfigProvider', () {
    test('formatPrice returns ZMW format', () {
      final config = ConfigProvider();
      expect(config.formatPrice(1500), 'K 1500.00');
    });

    test('toggleCurrency switches to USD', () {
      final config = ConfigProvider();
      expect(config.currency, 'ZMW');
      config.toggleCurrency();
      expect(config.currency, 'USD');
    });
  });
}
