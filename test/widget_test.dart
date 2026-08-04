import 'package:flutter_test/flutter_test.dart';
import 'package:sell_on_app/models/product.dart';
import 'package:sell_on_app/models/cart_item.dart';
import 'package:sell_on_app/models/user.dart';
import 'package:sell_on_app/providers/auth_provider.dart';
import 'package:sell_on_app/providers/config_provider.dart';

void main() {
  group('Product Model', () {
    test('Product.all returns 12 products', () {
      expect(Product.all.length, 12);
    });

    test('Product.all has unique IDs', () {
      final ids = Product.all.map((p) => p.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('Product.fromJson creates valid product', () {
      final json = {
        'id': '99',
        'name': 'Test Bag',
        'price': 1000.0,
        'image': 'assets/products/test.png',
        'description': 'A test bag',
        'category': 'Bags',
        'isGhost': false,
      };
      final product = Product.fromJson(json);
      expect(product.id, '99');
      expect(product.name, 'Test Bag');
      expect(product.price, 1000.0);
    });

    test('Product.toJson roundtrips', () {
      final original = Product.all.first;
      final json = original.toJson();
      final restored = Product.fromJson(json);
      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.price, original.price);
    });
  });

  group('CartItem Model', () {
    test('CartItem has correct total', () {
      const item = CartItem(id: '1', name: 'Bag', price: 500, image: 'img.png', quantity: 3);
      expect(item.total, 1500.0);
    });

    test('CartItem copyWith works', () {
      const item = CartItem(id: '1', name: 'Bag', price: 500, image: 'img.png');
      final updated = item.copyWith(quantity: 5);
      expect(updated.quantity, 5);
      expect(updated.name, 'Bag');
    });

    test('CartItem default quantity is 1', () {
      const item = CartItem(id: '1', name: 'Bag', price: 500, image: 'img.png');
      expect(item.quantity, 1);
    });

    test('CartItem toJson/fromJson roundtrip', () {
      const item = CartItem(id: '1', name: 'Bag', price: 500, image: 'img.png', quantity: 2);
      final json = item.toJson();
      final restored = CartItem.fromJson(json);
      expect(restored.id, item.id);
      expect(restored.quantity, 2);
    });
  });

  group('Order Model', () {
    test('Order holds items and total', () {
      const items = [
        CartItem(id: '1', name: 'Bag', price: 500, image: 'img.png', quantity: 2),
      ];
      const order = Order(id: 'ORD001', items: items, total: 1000, date: '2025-01-01', status: 'Pending');
      expect(order.items.length, 1);
      expect(order.total, 1000);
      expect(order.status, 'Pending');
    });

    test('Order toJson/fromJson roundtrip', () {
      const items = [
        CartItem(id: '1', name: 'Bag', price: 500, image: 'img.png', quantity: 2),
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

    test('User defaults', () {
      const user = User(uid: 'u1', name: 'John', email: 'j@test.com');
      expect(user.role, 'user');
      expect(user.riderStatus, 'none');
      expect(user.riderLocation, isNull);
    });
  });

  group('AuthProvider', () {
    test('validatePassword rejects short password', () {
      expect(AuthProvider.validatePassword('Ab1'), isNotNull);
    });

    test('validatePassword rejects no uppercase', () {
      expect(AuthProvider.validatePassword('abcdefg1'), isNotNull);
    });

    test('validatePassword rejects no number', () {
      expect(AuthProvider.validatePassword('Abcdefgh'), isNotNull);
    });

    test('validatePassword accepts valid password', () {
      expect(AuthProvider.validatePassword('Password1'), isNull);
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

    test('toggleTheme switches to dark', () {
      final config = ConfigProvider();
      expect(config.theme, 'light');
      config.toggleTheme();
      expect(config.theme, 'dark');
    });

    test('formatPrice returns USD format after toggle', () {
      final config = ConfigProvider();
      config.toggleCurrency();
      final result = config.formatPrice(100);
      expect(result, contains('\$'));
    });
  });
}
