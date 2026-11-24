import 'package:flutter_test/flutter_test.dart';
import 'package:fighub/product_model.dart';

void main() {
  group('Product image field compatibility', () {
    test('uses imagePaths when legacy imagePath is an empty string', () {
      final product = Product.fromMap('product-1', {
        'sellerId': 'seller-1',
        'name': 'Figure',
        'imagePath': '',
        'imagePaths': ['https://res.cloudinary.com/jcfyuify/image/upload/a.jpg'],
      });

      expect(product.imagePath,
          'https://res.cloudinary.com/jcfyuify/image/upload/a.jpg');
      expect(product.imagePaths, hasLength(1));
    });

    test('trims stored image URLs and ignores blank entries', () {
      final product = Product.fromMap('product-2', {
        'sellerId': 'seller-1',
        'name': 'Figure',
        'imagePath': '  ',
        'imagePaths': [
          '  https://res.cloudinary.com/jcfyuify/image/upload/a.jpg  ',
          '',
          '   ',
        ],
      });

      expect(product.imagePath,
          'https://res.cloudinary.com/jcfyuify/image/upload/a.jpg');
      expect(product.imagePaths, hasLength(1));
    });

    test('keeps legacy imagePath when imagePaths is absent', () {
      final product = Product.fromMap('product-3', {
        'sellerId': 'seller-1',
        'name': 'Legacy figure',
        'imagePath': 'https://res.cloudinary.com/jcfyuify/image/upload/old.jpg',
      });

      expect(product.imagePath,
          'https://res.cloudinary.com/jcfyuify/image/upload/old.jpg');
      expect(product.imagePaths, hasLength(1));
    });
  });
}
